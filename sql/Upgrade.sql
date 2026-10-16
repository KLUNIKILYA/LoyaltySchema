-- sqlcmd без "-f 65001" читает этот файл как Windows-1251, и русские строки ложатся
-- в базу кракозябрами ("Базовый" -> "Р‘Р°Р·РѕРІС‹Р№"). Проверка: буква Ж должна прочитаться
-- одним символом. Иначе — стоп, ничего не выполняем (NOEXEC действует до конца сессии).
IF UNICODE(N'Ж') <> 1046
BEGIN
    RAISERROR(N'STOP: file was read in the wrong encoding. Run: sqlcmd ... -f 65001 -i <file>', 16, 1);
    SET NOEXEC ON;
END
GO
IF OBJECT_ID(N'dbo.LoyaltyProfiles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.LoyaltyProfiles
    (
        VisitorId             INT NOT NULL PRIMARY KEY,
        TierLevel             INT NOT NULL DEFAULT 1,
        PhoneNumber           NVARCHAR(50) NULL,
        Email                 NVARCHAR(200) NULL,
        InstagramUsername     NVARCHAR(100) NULL,
        TelegramUsername      NVARCHAR(100) NULL,
        HasChildren           BIT NOT NULL DEFAULT 0,
        Neighborhood          NVARCHAR(200) NULL,
        Workplace             NVARCHAR(200) NULL,
        CustomerStatus        NVARCHAR(100) NULL,
        RegistrationDate      DATETIME NOT NULL
    );
END
GO

DECLARE @mertvye TABLE (stolb SYSNAME);
INSERT INTO @mertvye (stolb) VALUES
    (N'BonusBalance'), (N'IsSubscribedInsta'), (N'IsSubscribedTelegram'),
    (N'VisitType'), (N'VisitPurpose'), (N'Preferences'), (N'PreferredDays'),
    (N'PhoneNumber');

DECLARE @stolb SYSNAME, @sql NVARCHAR(500), @ogranichenie SYSNAME;
DECLARE mertvye_cur CURSOR LOCAL FAST_FORWARD FOR SELECT stolb FROM @mertvye;
OPEN mertvye_cur;
FETCH NEXT FROM mertvye_cur INTO @stolb;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF COL_LENGTH(N'dbo.LoyaltyProfiles', @stolb) IS NOT NULL
    BEGIN
        SELECT @ogranichenie = dc.name
        FROM sys.default_constraints dc
        JOIN sys.columns c ON c.object_id = dc.parent_object_id
                          AND c.column_id = dc.parent_column_id
        WHERE dc.parent_object_id = OBJECT_ID(N'dbo.LoyaltyProfiles')
          AND c.name = @stolb;

        IF @ogranichenie IS NOT NULL
        BEGIN
            SET @sql = N'ALTER TABLE dbo.LoyaltyProfiles DROP CONSTRAINT ' + QUOTENAME(@ogranichenie) + N';';
            EXEC sp_executesql @sql;
            SET @ogranichenie = NULL;
        END

        SET @sql = N'ALTER TABLE dbo.LoyaltyProfiles DROP COLUMN ' + QUOTENAME(@stolb) + N';';
        EXEC sp_executesql @sql;
    END

    FETCH NEXT FROM mertvye_cur INTO @stolb;
END

CLOSE mertvye_cur;
DEALLOCATE mertvye_cur;
GO

IF OBJECT_ID(N'dbo.ClientSegments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ClientSegments
    (
        Id                      INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Name                    NVARCHAR(200) NOT NULL,
        Description             NVARCHAR(MAX) NULL,
        FilterJson              NVARCHAR(MAX) NOT NULL DEFAULT '',
        ManualVisitorIdsJson    NVARCHAR(MAX) NULL,
        CreatedAt               DATETIME NOT NULL
    );
END
GO

IF COL_LENGTH(N'dbo.ClientSegments', N'ManualVisitorIdsJson') IS NULL
BEGIN
    ALTER TABLE dbo.ClientSegments
        ADD ManualVisitorIdsJson NVARCHAR(MAX) NULL;
END
GO

IF OBJECT_ID(N'dbo.MassCampaigns', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.MassCampaigns
    (
        Id                      INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Name                    NVARCHAR(200) NOT NULL,
        Description             NVARCHAR(MAX) NULL,
        SegmentId               INT NULL,
        AudienceFilterJson      NVARCHAR(MAX) NULL,
        AudienceVisitorIdsJson  NVARCHAR(MAX) NULL,
        ActionType              INT NOT NULL,
        Channel                 INT NOT NULL,
        Status                  INT NOT NULL,
        ActionParamsJson        NVARCHAR(MAX) NOT NULL,
        ScheduledAt             DATETIME NULL,
        CreatedAt               DATETIME NOT NULL,
        StartedAt               DATETIME NULL,
        CompletedAt             DATETIME NULL,
        TotalCount              INT NOT NULL DEFAULT 0,
        ProcessedCount          INT NOT NULL DEFAULT 0,
        SuccessCount            INT NOT NULL DEFAULT 0,
        FailedCount             INT NOT NULL DEFAULT 0,
        Budget                  DECIMAL(18,2) NOT NULL DEFAULT 0,
        BonusesIssued           DECIMAL(18,2) NOT NULL DEFAULT 0,
        LastError               NVARCHAR(2000) NULL
    );

    CREATE INDEX IX_MassCampaigns_Status      ON dbo.MassCampaigns(Status);
    CREATE INDEX IX_MassCampaigns_ScheduledAt ON dbo.MassCampaigns(ScheduledAt);
    CREATE INDEX IX_MassCampaigns_CreatedAt   ON dbo.MassCampaigns(CreatedAt DESC);
END
GO

IF OBJECT_ID(N'dbo.MassCampaignTargets', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.MassCampaignTargets
    (
        Id              BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        MassCampaignId  INT NOT NULL,
        VisitorId       INT NOT NULL,
        Status          INT NOT NULL DEFAULT 0,
        ProcessedAt     DATETIME NULL,
        ErrorMessage    NVARCHAR(1000) NULL
    );

    CREATE INDEX IX_MassCampaignTargets_Campaign_Status
        ON dbo.MassCampaignTargets(MassCampaignId, Status);

    CREATE INDEX IX_MassCampaignTargets_Visitor
        ON dbo.MassCampaignTargets(VisitorId);
END
GO

IF COL_LENGTH(N'dbo.MassCampaignTargets', N'AttemptCount') IS NULL
BEGIN
    ALTER TABLE dbo.MassCampaignTargets ADD AttemptCount INT NOT NULL DEFAULT 0;
END
GO

IF OBJECT_ID(N'dbo.BonusTransactions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.BonusTransactions
    (
        Id                BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        VisitorId         INT NOT NULL,
        Amount            DECIMAL(18,2) NOT NULL,
        Reason            INT NOT NULL,
        SourceCampaignId  INT NULL,
        Comment           NVARCHAR(500) NULL,
        CreatedAt         DATETIME NOT NULL,
        ExpiresAt         DATETIME NULL,
        IsActive          BIT NOT NULL DEFAULT 1
    );

    CREATE INDEX IX_BonusTransactions_Visitor_Active
        ON dbo.BonusTransactions(VisitorId, IsActive);

    CREATE INDEX IX_BonusTransactions_Campaign
        ON dbo.BonusTransactions(SourceCampaignId);

    CREATE INDEX IX_BonusTransactions_Expires
        ON dbo.BonusTransactions(ExpiresAt);
END
GO

IF OBJECT_ID(N'dbo.LoyaltyDiscountGrants', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.LoyaltyDiscountGrants
    (
        Id                BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        DiscountId        INT NOT NULL,
        VisitorId         INT NOT NULL,
        IssuedAt          DATETIME NOT NULL,
        ExpiresAt         DATETIME NULL,
        UsedAt            DATETIME NULL,
        UsedOrderId       INT NULL,
        IsActive          BIT NOT NULL DEFAULT 1,
        SourceCampaignId  INT NULL,
        SourceTriggerId   INT NULL,

        Comment           NVARCHAR(500) NULL
    );

    CREATE UNIQUE INDEX UX_LoyaltyDiscountGrants_Discount_Visitor
        ON dbo.LoyaltyDiscountGrants(DiscountId, VisitorId);

    CREATE INDEX IX_LoyaltyDiscountGrants_Visitor_Active
        ON dbo.LoyaltyDiscountGrants(VisitorId, IsActive)
        INCLUDE (DiscountId, ExpiresAt, UsedAt);

    CREATE INDEX IX_LoyaltyDiscountGrants_Campaign
        ON dbo.LoyaltyDiscountGrants(SourceCampaignId);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_LoyaltyDiscountGrants_Active_Used'
                 AND object_id = OBJECT_ID(N'dbo.LoyaltyDiscountGrants'))
BEGIN
    CREATE INDEX IX_LoyaltyDiscountGrants_Active_Used
        ON dbo.LoyaltyDiscountGrants(IsActive, UsedAt)
        INCLUDE (DiscountId, VisitorId);
END
GO

IF OBJECT_ID(N'dbo.CampaignDiscountGrants', N'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.CampaignDiscountGrants;
END
GO

IF EXISTS (SELECT 1 FROM sys.indexes
           WHERE name = 'IX_PaymentHistory_DiscountID'
             AND object_id = OBJECT_ID(N'dbo.PaymentHistory'))
BEGIN
    DROP INDEX IX_PaymentHistory_DiscountID ON dbo.PaymentHistory;
END
GO

IF OBJECT_ID(N'dbo.Triggers', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Triggers
    (
        Id                  INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Name                NVARCHAR(200) NOT NULL,
        Description         NVARCHAR(MAX) NULL,
        TriggerType         INT NOT NULL,
        IsEnabled           BIT NOT NULL DEFAULT 1,
        ParamsJson          NVARCHAR(MAX) NOT NULL,
        AudienceFilterJson  NVARCHAR(MAX) NULL,
        ActionParamsJson    NVARCHAR(MAX) NOT NULL,
        SendFromHour        INT NOT NULL DEFAULT 9,
        SendToHour          INT NOT NULL DEFAULT 21,
        CreatedAt           DATETIME NOT NULL,
        LastRunAt           DATETIME NULL,
        TotalFirings        INT NOT NULL DEFAULT 0
    );

    CREATE INDEX IX_Triggers_Enabled ON dbo.Triggers(IsEnabled);
END
GO

IF COL_LENGTH(N'dbo.Triggers', N'SendFromHour') IS NULL
BEGIN
    ALTER TABLE dbo.Triggers ADD SendFromHour INT NOT NULL DEFAULT 9;
END
GO
IF COL_LENGTH(N'dbo.Triggers', N'SendToHour') IS NULL
BEGIN
    ALTER TABLE dbo.Triggers ADD SendToHour INT NOT NULL DEFAULT 21;
END
GO

IF OBJECT_ID(N'dbo.TriggerFirings', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.TriggerFirings
    (
        Id              BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        TriggerId       INT NOT NULL,
        VisitorId       INT NOT NULL,
        OccurrenceKey   NVARCHAR(200) NOT NULL,
        FiredAt         DATETIME NOT NULL,
        Success         BIT NOT NULL,
        ErrorMessage    NVARCHAR(1000) NULL
    );

    CREATE UNIQUE INDEX UX_TriggerFirings_NoDups
        ON dbo.TriggerFirings(TriggerId, VisitorId, OccurrenceKey);

    CREATE INDEX IX_TriggerFirings_Trigger ON dbo.TriggerFirings(TriggerId);
    CREATE INDEX IX_TriggerFirings_Visitor ON dbo.TriggerFirings(VisitorId);
END
GO

IF EXISTS (SELECT 1 FROM sys.indexes
           WHERE name = 'IX_CashboxVisitor_ParentID'
             AND object_id = OBJECT_ID(N'dbo.CashboxVisitor')
             AND has_filter = 1)
BEGIN
    DROP INDEX IX_CashboxVisitor_ParentID ON dbo.CashboxVisitor;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_CashboxVisitor_ParentID'
                 AND object_id = OBJECT_ID(N'dbo.CashboxVisitor'))
BEGIN
    CREATE INDEX IX_CashboxVisitor_ParentID
        ON dbo.CashboxVisitor(ParentID)
        INCLUDE (BirthDate, Sex, Active);
END
GO

IF OBJECT_ID(N'dbo.ChildParents', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ChildParents
    (
        Id               BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,

        ChildVisitorId   INT NOT NULL,
        ParentVisitorId  INT NOT NULL,

        Role             NVARCHAR(50) NULL,
        CreatedAt        DATETIME NOT NULL DEFAULT GETDATE()
    );

    CREATE UNIQUE INDEX UX_ChildParents_Child_Parent
        ON dbo.ChildParents(ChildVisitorId, ParentVisitorId);

    CREATE INDEX IX_ChildParents_Parent ON dbo.ChildParents(ParentVisitorId);
END
GO

IF OBJECT_ID(N'dbo.KidExtraParents', N'U') IS NOT NULL
   AND COL_LENGTH(N'dbo.KidExtraParents', N'Role') IS NULL
BEGIN
    ALTER TABLE dbo.KidExtraParents ADD Role NVARCHAR(50) NULL;
END
GO

IF OBJECT_ID(N'dbo.KidExtras', N'U') IS NOT NULL
   AND COL_LENGTH(N'dbo.KidExtras', N'ChildVisitorId') IS NULL
BEGIN
    ALTER TABLE dbo.KidExtras ADD ChildVisitorId INT NULL;
END
GO

IF OBJECT_ID(N'dbo.CashboxVisitorKid', N'U') IS NOT NULL
BEGIN
    BEGIN TRANSACTION;

    DECLARE @novye TABLE (KidId INT, ChildVisitorId INT);

    MERGE dbo.CashboxVisitor AS target
    USING (
        SELECT k.ID              AS KidId,
               k.VisitorID       AS ParentId,
               LTRIM(RTRIM(ISNULL(p.Surname, N''))) AS Surname,
               LTRIM(RTRIM(ISNULL(k.KidName, N''))) AS Name,
               k.KidBirthDate,
               e.Sex
        FROM dbo.CashboxVisitorKid k
        LEFT JOIN dbo.KidExtras   e ON e.KidId = k.ID
        LEFT JOIN dbo.CashboxVisitor p ON p.IdVisitor = k.VisitorID
        WHERE e.ChildVisitorId IS NULL
    ) AS src
    ON 1 = 0
    WHEN NOT MATCHED THEN
        INSERT (Surname, Name, MiddleName, BirthDate, Sex, ParentID,
                Active, LastChange, SotrudnikStatus, TrainerStatus, ResidentStatus)
        VALUES (src.Surname, src.Name, N'', src.KidBirthDate, src.Sex, src.ParentId,
                1, GETDATE(), 0, 0, 0)
    OUTPUT src.KidId, inserted.IdVisitor INTO @novye(KidId, ChildVisitorId);

    INSERT INTO dbo.ChildParents (ChildVisitorId, ParentVisitorId, Role, CreatedAt)
    SELECT DISTINCT karta.ChildVisitorId, kp.VisitorId, kp.Role, kp.CreatedAt
    FROM dbo.KidExtraParents kp
    JOIN (
        SELECT e.KidId, e.ChildVisitorId FROM dbo.KidExtras e WHERE e.ChildVisitorId IS NOT NULL
        UNION ALL
        SELECT n.KidId, n.ChildVisitorId FROM @novye n
    ) AS karta ON karta.KidId = kp.KidId
    LEFT JOIN dbo.CashboxVisitor c ON c.IdVisitor = karta.ChildVisitorId
    WHERE kp.VisitorId <> ISNULL(c.ParentID, -1)
      AND NOT EXISTS (
          SELECT 1 FROM dbo.ChildParents x
          WHERE x.ChildVisitorId = karta.ChildVisitorId
            AND x.ParentVisitorId = kp.VisitorId);

    COMMIT TRANSACTION;

    DROP TABLE dbo.KidExtraParents;
    DROP TABLE dbo.KidExtras;
    DROP TABLE dbo.CashboxVisitorKid;
END
GO

IF COL_LENGTH(N'dbo.MassCampaigns', N'DiscountId') IS NULL
BEGIN
    ALTER TABLE dbo.MassCampaigns ADD DiscountId INT NULL;
END
GO

IF COL_LENGTH(N'dbo.Triggers', N'DiscountId') IS NULL
BEGIN
    ALTER TABLE dbo.Triggers ADD DiscountId INT NULL;
END
GO

IF OBJECT_ID(N'dbo.SpouseLinks', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SpouseLinks
    (
        Id           BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        VisitorAId   INT NOT NULL,
        VisitorBId   INT NOT NULL,
        CreatedAt    DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT CK_SpouseLinks_Order CHECK (VisitorAId < VisitorBId)
    );

    CREATE UNIQUE INDEX UX_SpouseLinks_Pair ON dbo.SpouseLinks(VisitorAId, VisitorBId);
    CREATE INDEX IX_SpouseLinks_A ON dbo.SpouseLinks(VisitorAId);
    CREATE INDEX IX_SpouseLinks_B ON dbo.SpouseLinks(VisitorBId);
END
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.TelegramLinks', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.TelegramLinks
    (
        Id                BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        VisitorId         INT NOT NULL,
        TelegramChatId    BIGINT NOT NULL,
        TelegramUsername  NVARCHAR(100) NULL,
        PhoneShared       NVARCHAR(30) NULL,
        LinkMethod        INT NOT NULL DEFAULT 0,
        IsActive          BIT NOT NULL DEFAULT 1,
        LinkedAt          DATETIME NOT NULL DEFAULT GETDATE()
    );

    CREATE UNIQUE INDEX UX_TelegramLinks_ChatId_Active
        ON dbo.TelegramLinks(TelegramChatId) WHERE IsActive = 1;
    CREATE UNIQUE INDEX UX_TelegramLinks_Visitor_Active
        ON dbo.TelegramLinks(VisitorId) WHERE IsActive = 1;
    CREATE INDEX IX_TelegramLinks_Visitor ON dbo.TelegramLinks(VisitorId);
END
GO

IF OBJECT_ID(N'dbo.TelegramLinkCodes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.TelegramLinkCodes
    (
        Id            BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Code          NVARCHAR(20) NOT NULL,
        VisitorId     INT NOT NULL,
        ExpiresAt     DATETIME NOT NULL,
        IsUsed        BIT NOT NULL DEFAULT 0,
        UsedByChatId  BIGINT NULL,
        CreatedAt     DATETIME NOT NULL DEFAULT GETDATE()
    );

    CREATE INDEX IX_TelegramLinkCodes_Code ON dbo.TelegramLinkCodes(Code);
    CREATE INDEX IX_TelegramLinkCodes_Visitor ON dbo.TelegramLinkCodes(VisitorId);
END
GO

IF OBJECT_ID(N'dbo.SupportTickets', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SupportTickets
    (
        Id          BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        VisitorId   INT NOT NULL,
        Text        NVARCHAR(4000) NOT NULL,
        CreatedAt   DATETIME NOT NULL DEFAULT GETDATE(),
        Status      INT NOT NULL DEFAULT 0,
        AnswerText  NVARCHAR(4000) NULL,
        AnsweredAt  DATETIME NULL
    );

    CREATE INDEX IX_SupportTickets_Visitor ON dbo.SupportTickets(VisitorId);
    CREATE INDEX IX_SupportTickets_Status ON dbo.SupportTickets(Status);
END
GO

IF COL_LENGTH('dbo.SupportTickets', 'AnsweredBy') IS NULL
    ALTER TABLE dbo.SupportTickets ADD AnsweredBy NVARCHAR(100) NULL;
GO

IF COL_LENGTH('dbo.SupportTickets', 'AnswerDelivered') IS NULL
    ALTER TABLE dbo.SupportTickets ADD AnswerDelivered BIT NOT NULL DEFAULT 0;
GO

IF OBJECT_ID(N'dbo.ReferralSettings', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ReferralSettings
    (
        Id                      INT NOT NULL PRIMARY KEY,
        Enabled                 BIT NOT NULL DEFAULT 0,
        RewardReferrer          BIT NOT NULL DEFAULT 1,
        ReferrerBonus           DECIMAL(18,2) NOT NULL DEFAULT 0,
        RewardReferred          BIT NOT NULL DEFAULT 0,
        ReferredBonus           DECIMAL(18,2) NOT NULL DEFAULT 0,
        QualifyEvent            INT NOT NULL DEFAULT 0,
        MaxRewardedPerReferrer  INT NULL,
        BonusExpiresInDays      INT NULL,
        InviteExpiresInDays     INT NULL DEFAULT 30,
        UpdatedAt               DATETIME NOT NULL DEFAULT GETDATE()
    );

    INSERT INTO dbo.ReferralSettings (Id, Enabled, RewardReferrer, ReferrerBonus, RewardReferred, ReferredBonus, QualifyEvent, UpdatedAt)
    VALUES (1, 0, 1, 0, 0, 0, 0, GETDATE());
END
GO

IF OBJECT_ID(N'dbo.ReferralCodes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ReferralCodes
    (
        VisitorId  INT NOT NULL PRIMARY KEY,
        Code       NVARCHAR(20) NOT NULL,
        CreatedAt  DATETIME NOT NULL DEFAULT GETDATE()
    );

    CREATE UNIQUE INDEX UX_ReferralCodes_Code ON dbo.ReferralCodes(Code);
END
GO

IF OBJECT_ID(N'dbo.Referrals', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Referrals
    (
        Id                    BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        ReferrerVisitorId     INT NOT NULL,
        ReferredChatId        BIGINT NULL,
        ReferredVisitorId     INT NULL,
        Status                INT NOT NULL DEFAULT 0,
        RejectReason          NVARCHAR(200) NULL,
        CreatedAt             DATETIME NOT NULL DEFAULT GETDATE(),
        BoundAt               DATETIME NULL,
        QualifiedAt           DATETIME NULL,
        RewardedAt            DATETIME NULL,
        ReferrerBonusAwarded  DECIMAL(18,2) NULL,
        ReferredBonusAwarded  DECIMAL(18,2) NULL
    );

    CREATE INDEX IX_Referrals_Referrer ON dbo.Referrals(ReferrerVisitorId);
    CREATE INDEX IX_Referrals_ReferredChat ON dbo.Referrals(ReferredChatId);
    CREATE INDEX IX_Referrals_ReferredVisitor ON dbo.Referrals(ReferredVisitorId);
    CREATE INDEX IX_Referrals_Status ON dbo.Referrals(Status);
END
GO

IF COL_LENGTH(N'dbo.Referrals', N'ReferredPhone') IS NULL
BEGIN
    ALTER TABLE dbo.Referrals ADD ReferredPhone NVARCHAR(30) NULL, ReferredName NVARCHAR(200) NULL;
END
GO

IF COL_LENGTH(N'dbo.ReferralSettings', N'ReferrerGrantDiscount') IS NULL
BEGIN
    ALTER TABLE dbo.ReferralSettings ADD
        ReferrerGrantDiscount    BIT NOT NULL DEFAULT 0,
        ReferrerDiscountTicketId INT NULL,
        ReferrerDiscountPercent  DECIMAL(5,2) NOT NULL DEFAULT 0,
        ReferrerDiscountValidDays INT NULL,
        ReferrerDiscountComment  NVARCHAR(500) NULL,
        ReferredGrantDiscount    BIT NOT NULL DEFAULT 0,
        ReferredDiscountTicketId INT NULL,
        ReferredDiscountPercent  DECIMAL(5,2) NOT NULL DEFAULT 0,
        ReferredDiscountValidDays INT NULL,
        ReferredDiscountComment  NVARCHAR(500) NULL;
END
GO

IF COL_LENGTH(N'dbo.ReferralSettings', N'ReferrerDiscountActionId') IS NULL
BEGIN
    ALTER TABLE dbo.ReferralSettings ADD
        ReferrerDiscountActionId INT NULL,
        ReferredDiscountActionId INT NULL;
END
GO

IF COL_LENGTH(N'dbo.ReferralSettings', N'InviteExpiresInDays') IS NULL
BEGIN
    ALTER TABLE dbo.ReferralSettings ADD InviteExpiresInDays INT NULL;
    EXEC(N'UPDATE dbo.ReferralSettings SET InviteExpiresInDays = 30 WHERE InviteExpiresInDays IS NULL;');
END
GO

IF COL_LENGTH(N'dbo.ReferralSettings', N'InviteText') IS NULL
    ALTER TABLE dbo.ReferralSettings ADD
        InviteText            NVARCHAR(1000) NULL,
        ShareText             NVARCHAR(1000) NULL,
        ReferrerRewardMessage NVARCHAR(1000) NULL,
        ReferredRewardMessage NVARCHAR(1000) NULL;
GO

IF COL_LENGTH(N'dbo.Referrals', N'ReferrerDiscountAwarded') IS NULL
BEGIN
    ALTER TABLE dbo.Referrals ADD
        ReferrerDiscountAwarded DECIMAL(5,2) NULL,
        ReferredDiscountAwarded DECIMAL(5,2) NULL;
END
GO

UPDATE dbo.Referrals
SET Status = 5
WHERE Status = 4
  AND (RejectReason LIKE N'Не привязал профиль за%' OR RejectReason LIKE N'Не купил за%');
GO

IF OBJECT_ID(N'dbo.Surveys', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Surveys
    (
        Id            INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Name          NVARCHAR(200) NOT NULL,
        QuestionsJson NVARCHAR(MAX) NOT NULL DEFAULT '[]',
        IsActive      BIT NOT NULL DEFAULT 1,
        CreatedAt     DATETIME NOT NULL DEFAULT GETDATE()
    );

    CREATE INDEX IX_Surveys_Active ON dbo.Surveys(IsActive);
END
GO

IF COL_LENGTH(N'dbo.Surveys', N'QuestionsJson') IS NULL
BEGIN
    ALTER TABLE dbo.Surveys ADD QuestionsJson NVARCHAR(MAX) NOT NULL DEFAULT '[]';
END
GO

IF COL_LENGTH(N'dbo.Surveys', N'QuestionText') IS NOT NULL
   AND COL_LENGTH(N'dbo.Surveys', N'OptionsJson') IS NOT NULL
BEGIN
    EXEC sp_executesql N'
        UPDATE dbo.Surveys
           SET QuestionsJson = N''[{"Text":'' + ''"'' + REPLACE(QuestionText, ''"'', ''\"'') + ''"'' +
                               N'',"Options":'' + OptionsJson + N''}]''
         WHERE ISNULL(QuestionsJson, N''[]'') IN (N''[]'', N'''')
           AND QuestionText IS NOT NULL AND LEN(QuestionText) > 0;';

    DECLARE @df NVARCHAR(200);
    SELECT @df = dc.name FROM sys.default_constraints dc
      JOIN sys.columns c ON c.default_object_id = dc.object_id
     WHERE dc.parent_object_id = OBJECT_ID(N'dbo.Surveys') AND c.name = 'OptionsJson';
    IF @df IS NOT NULL EXEC(N'ALTER TABLE dbo.Surveys DROP CONSTRAINT ' + @df);

    ALTER TABLE dbo.Surveys DROP COLUMN QuestionText;
    ALTER TABLE dbo.Surveys DROP COLUMN OptionsJson;
END
GO

IF OBJECT_ID(N'dbo.SurveyResponses', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SurveyResponses
    (
        Id            BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        SurveyId      INT NOT NULL,
        VisitorId     INT NOT NULL,
        QuestionIndex INT NOT NULL DEFAULT 0,
        OptionIndex   INT NOT NULL,
        OptionText    NVARCHAR(300) NOT NULL,
        QuestionText  NVARCHAR(300) NULL,
        ShapeStamp    NVARCHAR(16) NULL,
        AnsweredAt    DATETIME NOT NULL DEFAULT GETDATE()
    );

    CREATE UNIQUE INDEX UX_SurveyResponses_Survey_Visitor_Question
        ON dbo.SurveyResponses(SurveyId, VisitorId, QuestionIndex);

    CREATE INDEX IX_SurveyResponses_Survey ON dbo.SurveyResponses(SurveyId);
END
GO

IF COL_LENGTH(N'dbo.SurveyResponses', N'QuestionText') IS NULL
BEGIN
    ALTER TABLE dbo.SurveyResponses ADD QuestionText NVARCHAR(300) NULL;
END
GO

IF COL_LENGTH(N'dbo.SurveyResponses', N'ShapeStamp') IS NULL
BEGIN
    ALTER TABLE dbo.SurveyResponses ADD ShapeStamp NVARCHAR(16) NULL;
END
GO

IF COL_LENGTH(N'dbo.SurveyResponses', N'QuestionIndex') IS NULL
BEGIN
    ALTER TABLE dbo.SurveyResponses ADD QuestionIndex INT NOT NULL DEFAULT 0;
END
GO

IF COL_LENGTH(N'dbo.Surveys', N'IntroText') IS NULL
BEGIN
    ALTER TABLE dbo.Surveys ADD IntroText NVARCHAR(1000) NULL;
END
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_SurveyResponses_Survey_Visitor'
                                       AND object_id = OBJECT_ID(N'dbo.SurveyResponses'))
BEGIN
    DROP INDEX UX_SurveyResponses_Survey_Visitor ON dbo.SurveyResponses;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_SurveyResponses_Survey_Visitor_Question'
                                           AND object_id = OBJECT_ID(N'dbo.SurveyResponses'))
BEGIN
    CREATE UNIQUE INDEX UX_SurveyResponses_Survey_Visitor_Question
        ON dbo.SurveyResponses(SurveyId, VisitorId, QuestionIndex);
END
GO

IF OBJECT_ID(N'dbo.LoyaltySettings', N'U') IS NOT NULL
   AND COL_LENGTH(N'dbo.LoyaltySettings', N'SurveyCooldownDays') IS NULL
BEGIN
    ALTER TABLE dbo.LoyaltySettings ADD SurveyCooldownDays INT NOT NULL DEFAULT 30;
END
GO

IF COL_LENGTH('dbo.ClientSegments', 'ExcludedVisitorIdsJson') IS NULL
BEGIN
    ALTER TABLE dbo.ClientSegments ADD ExcludedVisitorIdsJson NVARCHAR(MAX) NULL;
END
GO

IF OBJECT_ID(N'dbo.AppUsers', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AppUsers
    (
        Id                  INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Login               NVARCHAR(100) NOT NULL,
        PasswordHash        NVARCHAR(400) NOT NULL,
        DisplayName         NVARCHAR(200) NOT NULL,
        Role                NVARCHAR(50)  NOT NULL,
        IsActive            BIT NOT NULL DEFAULT 1,
        MustChangePassword  BIT NOT NULL DEFAULT 0,
        CreatedAt           DATETIME NOT NULL DEFAULT GETDATE(),
        LastLoginAt         DATETIME NULL,
        PasswordChangedAt   DATETIME NULL
    );

    CREATE UNIQUE INDEX UX_AppUsers_Login ON dbo.AppUsers(Login);
END
GO

IF COL_LENGTH(N'dbo.AppUsers', N'PasswordChangedAt') IS NULL
BEGIN
    ALTER TABLE dbo.AppUsers ADD PasswordChangedAt DATETIME NULL;
END
GO

IF OBJECT_ID(N'dbo.UserActionLog', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserActionLog
    (
        Id         BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        UserId     INT NULL,
        UserLogin  NVARCHAR(100) NOT NULL,
        Action     NVARCHAR(100) NOT NULL,
        Target     NVARCHAR(200) NULL,
        Ip         NVARCHAR(45) NULL,
        CreatedAt  DATETIME NOT NULL DEFAULT GETDATE()
    );

    CREATE INDEX IX_UserActionLog_CreatedAt ON dbo.UserActionLog(CreatedAt DESC);
    CREATE INDEX IX_UserActionLog_Action ON dbo.UserActionLog(Action, CreatedAt DESC);
END
GO

IF OBJECT_ID(N'dbo.TelegramBindAttempts', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.TelegramBindAttempts
    (
        Id          BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        ChatId      BIGINT NOT NULL,
        AttemptedAt DATETIME NOT NULL DEFAULT GETDATE()
    );

    CREATE INDEX IX_TelegramBindAttempts_Time ON dbo.TelegramBindAttempts(AttemptedAt DESC, ChatId);
END
GO

IF COL_LENGTH(N'dbo.LoyaltyProfiles', N'TierChangedAt') IS NULL
BEGIN
    ALTER TABLE dbo.LoyaltyProfiles ADD TierChangedAt DATETIME NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LoyaltyProfiles_TierChangedAt')
BEGIN
    CREATE INDEX IX_LoyaltyProfiles_TierChangedAt
        ON dbo.LoyaltyProfiles(TierChangedAt) INCLUDE(TierLevel, VisitorId);
END
GO

IF OBJECT_ID(N'dbo.LoyaltySettings', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.LoyaltySettings
    (
        Id                  INT NOT NULL PRIMARY KEY DEFAULT 1,
        MaxPromoMessages    INT NOT NULL DEFAULT 1,
        PromoWindowDays     INT NOT NULL DEFAULT 7,
        QuietFromHour       INT NOT NULL DEFAULT 22,
        QuietToHour         INT NOT NULL DEFAULT 9,
        BonusLifetimeMonths INT NULL DEFAULT 12,
        AutoUpgradeTiers    BIT NOT NULL DEFAULT 0,
        UpdatedAt           DATETIME NOT NULL DEFAULT GETDATE(),
        SurveyCooldownDays  INT NOT NULL DEFAULT 30
    );

    INSERT INTO dbo.LoyaltySettings (Id) VALUES (1);
END
GO

IF OBJECT_ID(N'dbo.LoyaltyTiers', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.LoyaltyTiers
    (
        Id            INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Level         INT NOT NULL,
        Name          NVARCHAR(100) NOT NULL,
        LtvThreshold  DECIMAL(18,2) NOT NULL DEFAULT 0,
        RewardPercent DECIMAL(9,2) NOT NULL DEFAULT 0,
        UpdatedAt     DATETIME NOT NULL DEFAULT GETDATE()
    );

    CREATE UNIQUE INDEX UX_LoyaltyTiers_Level ON dbo.LoyaltyTiers(Level);

    INSERT INTO dbo.LoyaltyTiers (Level, Name, LtvThreshold, RewardPercent)
    VALUES (1, N'Базовый', 0,   0),
           (2, N'Серебро', 200, 3),
           (3, N'Золото',  600, 7);
END
GO

IF OBJECT_ID(N'dbo.ProfileDictionaries', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ProfileDictionaries
    (
        Id        INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Kind      INT NOT NULL,
        Value     NVARCHAR(200) NOT NULL,
        SortOrder INT NOT NULL DEFAULT 0,
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE()
    );

    CREATE UNIQUE INDEX UX_ProfileDictionaries_KindValue ON dbo.ProfileDictionaries(Kind, Value);
END
GO

IF OBJECT_ID(N'dbo.GymImports', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.GymImports
    (
        Id               INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        FileName         NVARCHAR(260) NOT NULL,
        UploadedAt       DATETIME NOT NULL DEFAULT GETDATE(),
        UploadedBy       NVARCHAR(100) NOT NULL,
        TotalRows        INT NOT NULL DEFAULT 0,
        SkippedRows      INT NOT NULL DEFAULT 0,
        CreatedCount     INT NOT NULL DEFAULT 0,
        UpdatedCount     INT NOT NULL DEFAULT 0,
        DeactivatedCount INT NOT NULL DEFAULT 0,
        LinkedCount      INT NOT NULL DEFAULT 0,
        CompletedAt      DATETIME NULL
    );
END
GO

IF OBJECT_ID(N'dbo.GymImports', N'U') IS NOT NULL
   AND COL_LENGTH(N'dbo.GymImports', N'CompletedAt') IS NULL
    ALTER TABLE dbo.GymImports ADD CompletedAt DATETIME NULL;
GO

IF OBJECT_ID(N'dbo.GymClients', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.GymClients
    (
        Id                INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        FullName          NVARCHAR(200) NOT NULL,
        Phone             NVARCHAR(9) NULL,
        PhoneRaw          NVARCHAR(50) NULL,
        BirthDate         DATETIME NULL,
        Source            INT NOT NULL DEFAULT 0,
        VisitorId         INT NULL,
        LinkMethod        INT NOT NULL DEFAULT 0,
        LinkedAt          DATETIME NULL,
        RejectedVisitorId INT NULL,
        IsActive          BIT NOT NULL DEFAULT 1,
        FirstImportId     INT NULL,
        LastImportId      INT NULL,
        CreatedAt         DATETIME NOT NULL DEFAULT GETDATE(),
        UpdatedAt         DATETIME NOT NULL DEFAULT GETDATE()
    );

    CREATE INDEX IX_GymClients_Phone ON dbo.GymClients(Phone);
    CREATE INDEX IX_GymClients_VisitorId ON dbo.GymClients(VisitorId);
END
GO

IF OBJECT_ID(N'dbo.GymSubscriptions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.GymSubscriptions
    (
        Id                 BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        GymClientId        INT NOT NULL,
        ImportId           INT NOT NULL,
        LastSubscription   NVARCHAR(200) NULL,
        PurchasedAt        DATETIME NULL,
        Status             NVARCHAR(50) NULL,
        ActiveSubscription NVARCHAR(200) NULL,
        ActiveUntil        DATETIME NULL,
        Freeze             NVARCHAR(200) NULL,
        LastPurchase       NVARCHAR(200) NULL,
        LastPurchaseAt     DATETIME NULL,
        LastPurchaseAmount DECIMAL(18,2) NULL
    );

    CREATE INDEX IX_GymSubscriptions_Client ON dbo.GymSubscriptions(GymClientId);
    CREATE INDEX IX_GymSubscriptions_Import ON dbo.GymSubscriptions(ImportId);
END
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.GymTelegramLinks', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.GymTelegramLinks
    (
        Id               BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        GymClientId      INT NOT NULL,
        TelegramChatId   BIGINT NOT NULL,
        TelegramUsername NVARCHAR(100) NULL,
        PhoneShared      NVARCHAR(30) NULL,
        LinkMethod       INT NOT NULL DEFAULT 0,
        IsActive         BIT NOT NULL DEFAULT 1,
        LinkedAt         DATETIME NOT NULL DEFAULT GETDATE()
    );

    CREATE UNIQUE INDEX UX_GymTelegramLinks_ChatId_Active
        ON dbo.GymTelegramLinks(TelegramChatId) WHERE IsActive = 1;
    CREATE UNIQUE INDEX UX_GymTelegramLinks_Client_Active
        ON dbo.GymTelegramLinks(GymClientId) WHERE IsActive = 1;
END
GO

IF OBJECT_ID(N'dbo.GymTelegramLinkCodes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.GymTelegramLinkCodes
    (
        Id           BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Code         NVARCHAR(20) NOT NULL,
        GymClientId  INT NOT NULL,
        ExpiresAt    DATETIME NOT NULL,
        IsUsed       BIT NOT NULL DEFAULT 0,
        UsedByChatId BIGINT NULL,
        CreatedAt    DATETIME NOT NULL DEFAULT GETDATE()
    );

    CREATE INDEX IX_GymTelegramLinkCodes_Code ON dbo.GymTelegramLinkCodes(Code);
END
GO

IF OBJECT_ID(N'dbo.TelegramStartTags', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.TelegramStartTags
    (
        Id        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        ChatId    BIGINT NOT NULL,
        Tag       NVARCHAR(30) NOT NULL,
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE()
    );

    CREATE UNIQUE INDEX UX_TelegramStartTags_ChatTag ON dbo.TelegramStartTags(ChatId, Tag);
END
GO

IF OBJECT_ID(N'dbo.GymSegments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.GymSegments
    (
        Id          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Name        NVARCHAR(200) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        FilterJson  NVARCHAR(MAX) NOT NULL,
        CreatedAt   DATETIME NOT NULL DEFAULT GETDATE()
    );
END
GO

IF OBJECT_ID(N'dbo.GymCampaigns', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.GymCampaigns
    (
        Id                 INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Name               NVARCHAR(200) NOT NULL,
        Description        NVARCHAR(MAX) NULL,
        SegmentId          INT NULL,
        AudienceFilterJson NVARCHAR(MAX) NOT NULL,
        MessageText        NVARCHAR(MAX) NOT NULL,
        Status             INT NOT NULL,
        ScheduledAt        DATETIME NULL,
        CreatedAt          DATETIME NOT NULL DEFAULT GETDATE(),
        StartedAt          DATETIME NULL,
        CompletedAt        DATETIME NULL,
        TotalCount         INT NOT NULL DEFAULT 0,
        ProcessedCount     INT NOT NULL DEFAULT 0,
        SuccessCount       INT NOT NULL DEFAULT 0,
        FailedCount        INT NOT NULL DEFAULT 0,
        LastError          NVARCHAR(2000) NULL
    );

    CREATE INDEX IX_GymCampaigns_Status ON dbo.GymCampaigns(Status);
END
GO

IF OBJECT_ID(N'dbo.GymCampaignTargets', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.GymCampaignTargets
    (
        Id            BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        GymCampaignId INT NOT NULL,
        GymClientId   INT NOT NULL,
        ChatId        BIGINT NULL,
        Status        INT NOT NULL DEFAULT 0,
        ProcessedAt   DATETIME NULL,
        ErrorMessage  NVARCHAR(1000) NULL,
        AttemptCount  INT NOT NULL DEFAULT 0
    );

    CREATE INDEX IX_GymCampaignTargets_Campaign_Status ON dbo.GymCampaignTargets(GymCampaignId, Status);
    CREATE INDEX IX_GymCampaignTargets_Chat ON dbo.GymCampaignTargets(ChatId, ProcessedAt) INCLUDE (Status);
END
GO

IF OBJECT_ID(N'dbo.GymTriggers', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.GymTriggers
    (
        Id           INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Name         NVARCHAR(200) NOT NULL,
        TriggerType  INT NOT NULL,
        DaysBefore   INT NOT NULL DEFAULT 0,
        MessageText  NVARCHAR(MAX) NOT NULL,
        IsEnabled    BIT NOT NULL DEFAULT 1,
        CreatedAt    DATETIME NOT NULL DEFAULT GETDATE(),
        LastRunAt    DATETIME NULL,
        TotalFirings INT NOT NULL DEFAULT 0
    );
END
GO

IF OBJECT_ID(N'dbo.GymTriggerFirings', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.GymTriggerFirings
    (
        Id            BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        GymTriggerId  INT NOT NULL,
        GymClientId   INT NOT NULL,
        ChatId        BIGINT NULL,
        OccurrenceKey NVARCHAR(100) NOT NULL,
        FiredAt       DATETIME NOT NULL,
        Success       BIT NOT NULL DEFAULT 0,
        ErrorMessage  NVARCHAR(1000) NULL
    );

    CREATE UNIQUE INDEX UX_GymTriggerFirings_Occurrence
        ON dbo.GymTriggerFirings(GymTriggerId, GymClientId, OccurrenceKey);
    CREATE INDEX IX_GymTriggerFirings_Chat ON dbo.GymTriggerFirings(ChatId, FiredAt) INCLUDE (Success);
END
GO

IF OBJECT_ID(N'dbo.LoyaltySettings', N'U') IS NOT NULL
   AND COL_LENGTH(N'dbo.LoyaltySettings', N'GymBirthDateSync') IS NULL
    ALTER TABLE dbo.LoyaltySettings ADD GymBirthDateSync BIT NOT NULL DEFAULT 0;
GO

IF OBJECT_ID(N'dbo.LoyaltySettings', N'U') IS NOT NULL
   AND COL_LENGTH(N'dbo.LoyaltySettings', N'BonusRate') IS NULL
    ALTER TABLE dbo.LoyaltySettings ADD
        BonusRate              DECIMAL(9,2) NOT NULL DEFAULT 1,
        MaxBonusPaymentPercent INT NOT NULL DEFAULT 100;
GO

IF OBJECT_ID(N'dbo.GymBirthDateWrites', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.GymBirthDateWrites
    (
        Id           BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        GymClientId  INT NOT NULL,
        VisitorId    INT NOT NULL,
        BirthDate    DATETIME NOT NULL,
        WrittenAt    DATETIME NOT NULL,
        RolledBackAt DATETIME NULL
    );

    CREATE INDEX IX_GymBirthDateWrites_Client ON dbo.GymBirthDateWrites(GymClientId);
    CREATE INDEX IX_GymBirthDateWrites_Visitor ON dbo.GymBirthDateWrites(VisitorId);
END
GO

IF OBJECT_ID(N'dbo.TelegramLinks', N'U') IS NOT NULL
   AND COL_LENGTH(N'dbo.TelegramLinks', N'GymClientId') IS NULL
    ALTER TABLE dbo.TelegramLinks ADD GymClientId INT NULL;
GO

-- Наши скидки в кассе адресные: автоприменение снимаем только с тех, что создала система лояльности
UPDATE d SET d.AutoOn = 0
FROM dbo.cs_Discount d
WHERE d.AutoOn = 1
  AND (d.ID IN (SELECT DiscountId FROM dbo.LoyaltyDiscountGrants)
       OR d.ID IN (SELECT DiscountId FROM dbo.MassCampaigns WHERE DiscountId IS NOT NULL)
       OR d.ID IN (SELECT DiscountId FROM dbo.Triggers WHERE DiscountId IS NOT NULL)
       OR d.ID IN (SELECT ReferrerDiscountActionId FROM dbo.ReferralSettings WHERE ReferrerDiscountActionId IS NOT NULL)
       OR d.ID IN (SELECT ReferredDiscountActionId FROM dbo.ReferralSettings WHERE ReferredDiscountActionId IS NOT NULL));
GO
