-- sqlcmd без "-f 65001" читает этот файл как Windows-1251, и русские строки ложатся
-- в базу кракозябрами ("Базовый" -> "Р‘Р°Р·РѕРІС‹Р№"). Проверка: буква Ж должна прочитаться
-- одним символом. Иначе — стоп, ничего не выполняем (NOEXEC действует до конца сессии).
IF UNICODE(N'Ж') <> 1046
BEGIN
    RAISERROR(N'STOP: file was read in the wrong encoding. Run: sqlcmd ... -f 65001 -i <file>', 16, 1);
    SET NOEXEC ON;
END
GO
SET NOCOUNT ON;
GO

IF OBJECT_ID('tempdb..#opis') IS NOT NULL DROP TABLE #opis;
CREATE TABLE #opis (tabl SYSNAME NOT NULL, stolb SYSNAME NULL, opis NVARCHAR(1000) NOT NULL);

INSERT INTO #opis (tabl, stolb, opis) VALUES
(N'LoyaltyProfiles', NULL, N'Данные лояльности поверх клиента кассы. Может отсутствовать: клиента заводит касса'),
(N'LoyaltyProfiles', N'VisitorId', N'CashboxVisitor.IdVisitor, он же первичный ключ'),
(N'LoyaltyProfiles', N'TierLevel', N'LoyaltyTiers.Level. Ноль трактуется как уровень 1'),
(N'LoyaltyProfiles', N'Email', N'Заполняется в CRM, касса его не знает'),
(N'LoyaltyProfiles', N'TelegramUsername', N'Со слов клиента. Ник привязанного бота — в TelegramLinks'),
(N'LoyaltyProfiles', N'HasChildren', N'Справочная: отбор аудитории считает детей по CashboxVisitor.ParentID'),
(N'LoyaltyProfiles', N'Neighborhood', N'Значения из ProfileDictionaries, Kind = 0'),
(N'LoyaltyProfiles', N'CustomerStatus', N'Пометка оператора: VIP, проблемный'),
(N'LoyaltyProfiles', N'RegistrationDate', N'Вступление в программу. По ней срабатывает триггер годовщины'),
(N'LoyaltyProfiles', N'TierChangedAt', N'Когда попал на текущий уровень. Пусто — под триггер повышения не попадает'),

(N'LoyaltyTiers', NULL, N'Уровни лояльности, порог входа по LTV клиента'),
(N'LoyaltyTiers', N'Level', N'На него ссылается LoyaltyProfiles.TierLevel'),
(N'LoyaltyTiers', N'LtvThreshold', N'Сумма покупок за всё время, с которой клиент попадает на уровень'),
(N'LoyaltyTiers', N'RewardPercent', N'Процент кэшбэка на этом уровне. Начисляет касса'),

(N'LoyaltySettings', NULL, N'Общие настройки программы. Строка одна, Id = 1'),
(N'LoyaltySettings', N'MaxPromoMessages', N'Рекламных сообщений на клиента за окно PromoWindowDays'),
(N'LoyaltySettings', N'QuietFromHour', N'Тихие часы. Равные значения — не ограничивать, окно может идти через полночь'),
(N'LoyaltySettings', N'BonusLifetimeMonths', N'Пусто — бонусы не сгорают'),
(N'LoyaltySettings', N'BonusRate', N'Читает касса: сколько рублей списывается за один бонус при оплате'),
(N'LoyaltySettings', N'MaxBonusPaymentPercent', N'Читает касса: какую долю суммы чека, в процентах, можно оплатить бонусами'),
(N'LoyaltySettings', N'AutoUpgradeTiers', N'Только повышение, понижения нет'),
(N'LoyaltySettings', N'SurveyCooldownDays', N'Не чаще одного опроса в N дней. Ноль — без ограничения'),

(N'ProfileDictionaries', NULL, N'Справочники для выпадающих списков в профиле'),
(N'ProfileDictionaries', N'Kind', N'0 — район, 1 — предпочтение, 2 — место работы');

INSERT INTO #opis (tabl, stolb, opis) VALUES
(N'ChildParents', NULL, N'Дополнительные родители ребёнка. Сам ребёнок — обычный клиент CashboxVisitor, основной родитель в его ParentID, который знает ровно одного'),
(N'ChildParents', N'ChildVisitorId', N'CashboxVisitor.IdVisitor'),
(N'ChildParents', N'ParentVisitorId', N'CashboxVisitor.IdVisitor. Основного родителя сюда не дублируем'),
(N'ChildParents', N'Role', N'Мама, Папа, Бабушка, Опекун. Свободный текст'),

(N'SpouseLinks', NULL, N'Супруги, оба — CashboxVisitor.IdVisitor. На пару одна строка, направление неважно');

INSERT INTO #opis (tabl, stolb, opis) VALUES
(N'BonusTransactions', NULL, N'Движения бонусов. Баланс клиента — сумма активных непросроченных строк, отдельного поля с балансом нет'),
(N'BonusTransactions', N'VisitorId', N'CashboxVisitor.IdVisitor'),
(N'BonusTransactions', N'Amount', N'Положительная — начисление, отрицательная — списание'),
(N'BonusTransactions', N'Reason', N'0 — вручную, 1 — рассылка или триггер, 2 — покупка, 3 — возврат, 4 — сгорание, 5 — реферал'),
(N'BonusTransactions', N'SourceCampaignId', N'MassCampaigns.Id, если начислено рассылкой'),
(N'BonusTransactions', N'ExpiresAt', N'Пусто — бессрочно. Просроченные в баланс не входят'),
(N'BonusTransactions', N'IsActive', N'Снимается при откате или сгорании');

INSERT INTO #opis (tabl, stolb, opis) VALUES
(N'LoyaltyDiscountGrants', NULL, N'Кому доступна акция. Сама акция — в cs_Discount, здесь только получатели и отметка об использовании'),
(N'LoyaltyDiscountGrants', N'DiscountId', N'cs_Discount.ID — процент, срок и правила применения там'),
(N'LoyaltyDiscountGrants', N'VisitorId', N'CashboxVisitor.IdVisitor. Для детских акций — карточка самого ребёнка: услуги пробиваются на него'),
(N'LoyaltyDiscountGrants', N'ExpiresAt', N'Личный срок клиента. Действует до более раннего из него и cs_Discount.DateTo'),
(N'LoyaltyDiscountGrants', N'UsedAt', N'Заполняет касса при применении. После этого доступ гасится'),
(N'LoyaltyDiscountGrants', N'UsedOrderId', N'CashboxOrder.IdOrder, заполняет касса'),
(N'LoyaltyDiscountGrants', N'IsActive', N'Кассе следует отбирать только строки с IsActive = 1'),
(N'LoyaltyDiscountGrants', N'SourceCampaignId', N'MassCampaigns.Id'),
(N'LoyaltyDiscountGrants', N'SourceTriggerId', N'Triggers.Id');

INSERT INTO #opis (tabl, stolb, opis) VALUES
(N'MassCampaigns', NULL, N'Разовая рассылка. Обрабатывается фоновой службой пачками'),
(N'MassCampaigns', N'SegmentId', N'ClientSegments.Id'),
(N'MassCampaigns', N'AudienceFilterJson', N'Условия отбора, если сегмент не выбран'),
(N'MassCampaigns', N'AudienceVisitorIdsJson', N'Явный список клиентов'),
(N'MassCampaigns', N'ActionType', N'1 — бонус, 2 — сообщение, 4 — скидка, 8 — опрос. Складывается побитово'),
(N'MassCampaigns', N'Channel', N'0 — без отправки, 2 — Telegram. Значения 1 и 3 сняты, встречаются в старых строках'),
(N'MassCampaigns', N'Status', N'0 — черновик, 1 — запланирована, 2 — в очереди, 3 — идёт, 4 — завершена, 5 — упала, 6 — отменена'),
(N'MassCampaigns', N'ActionParamsJson', N'Текст сообщения, сумма бонуса, процент скидки, опрос'),
(N'MassCampaigns', N'ScheduledAt', N'Пусто — отправлять сразу'),
(N'MassCampaigns', N'ProcessedCount', N'Доставленные, пропущенные и неудачные вместе'),
(N'MassCampaigns', N'FailedCount', N'Пропущенные по антиспаму сюда не входят'),
(N'MassCampaigns', N'DiscountId', N'cs_Discount.ID под эту рассылку. Одна на всю рассылку'),

(N'MassCampaignTargets', NULL, N'Адресаты рассылки. Отметка пишется до отправки, поэтому повторный проход не шлёт заново'),
(N'MassCampaignTargets', N'MassCampaignId', N'MassCampaigns.Id'),
(N'MassCampaignTargets', N'VisitorId', N'CashboxVisitor.IdVisitor'),
(N'MassCampaignTargets', N'Status', N'0 — ждёт, 1 — обработан, 2 — не доставлено, 3 — пропущен'),
(N'MassCampaignTargets', N'ErrorMessage', N'Почему не доставлено или почему пропущен'),
(N'MassCampaignTargets', N'AttemptCount', N'После трёх попыток временный отказ считается окончательным'),

(N'ClientSegments', NULL, N'Сохранённый набор условий отбора. Вычисляется в момент использования'),
(N'ClientSegments', N'FilterJson', N'Возраст, пол, дети, визиты, LTV'),
(N'ClientSegments', N'ManualVisitorIdsJson', N'Добавленные руками поверх фильтра'),
(N'ClientSegments', N'ExcludedVisitorIdsJson', N'Исключённые руками');

INSERT INTO #opis (tabl, stolb, opis) VALUES
(N'Triggers', NULL, N'Правило «при событии сделать действие». Фоновая служба обходит их раз в 15 минут'),
(N'Triggers', N'TriggerType', N'1 — ДР клиента, 2 — годовщина регистрации, 10 — нет визитов N дней, 20 — приветствие, 21 — юбилейный визит, 22 — повышение уровня, 30 — абонемент истекает, 31 — абонемент истёк, 40 — бонусы сгорают, 50 — ДР ребёнка, 51 — ребёнку исполнилось N, 60 — засчитан реферал, 61 — привёл N друзей'),
(N'Triggers', N'ParamsJson', N'Параметры события: за сколько дней, какой возраст, какой номер визита'),
(N'Triggers', N'AudienceFilterJson', N'Дополнительное сужение теми же условиями, что у сегментов'),
(N'Triggers', N'ActionParamsJson', N'Текст сообщения, сумма бонуса, процент скидки, опрос'),
(N'Triggers', N'SendFromHour', N'Не используется: окно отправки задают тихие часы в LoyaltySettings. Столбец оставлен, потому что NOT NULL'),
(N'Triggers', N'SendToHour', N'Не используется, см. SendFromHour'),
(N'Triggers', N'LastRunAt', N'Не двигается, если проход прервался на середине пачки'),
(N'Triggers', N'DiscountId', N'cs_Discount.ID. Одна на триггер, а не на срабатывание'),

(N'TriggerFirings', NULL, N'Журнал срабатываний и защита от повтора: уникальность по триггеру, клиенту и событию'),
(N'TriggerFirings', N'TriggerId', N'Triggers.Id'),
(N'TriggerFirings', N'VisitorId', N'CashboxVisitor.IdVisitor. Для детских событий — родитель: ему уходит сообщение и бонус'),
(N'TriggerFirings', N'OccurrenceKey', N'Дискретизатор события, например child_bday:17235:2026');

INSERT INTO #opis (tabl, stolb, opis) VALUES
(N'Surveys', NULL, N'Опрос: вопросы с вариантами, бот задаёт их по одному'),
(N'Surveys', N'QuestionsJson', N'Вопросы и варианты ответов'),
(N'Surveys', N'IsActive', N'Выключенный не уходит ни рассылкой, ни триггером'),
(N'Surveys', N'IntroText', N'Если задано, бот сначала спрашивает согласие'),

(N'SurveyResponses', NULL, N'Ответы клиентов, по строке на каждый ответ'),
(N'SurveyResponses', N'SurveyId', N'Surveys.Id'),
(N'SurveyResponses', N'VisitorId', N'CashboxVisitor.IdVisitor'),
(N'SurveyResponses', N'QuestionIndex', N'Номер вопроса в QuestionsJson с нуля. Минус один — отказ проходить опрос'),
(N'SurveyResponses', N'OptionIndex', N'Номер выбранного варианта с нуля'),
(N'SurveyResponses', N'OptionText', N'На момент ответа: опрос могли изменить позже'),
(N'SurveyResponses', N'QuestionText', N'На момент ответа. Пусто у старых строк — тогда берётся по номеру'),
(N'SurveyResponses', N'ShapeStamp', N'Отпечаток версии опроса. В диаграмму попадают только ответы текущей версии. Пусто у старых строк');

INSERT INTO #opis (tabl, stolb, opis) VALUES
(N'ReferralSettings', NULL, N'Настройки «приведи друга». Строка одна, Id = 1'),
(N'ReferralSettings', N'QualifyEvent', N'0 — первая покупка'),
(N'ReferralSettings', N'MaxRewardedPerReferrer', N'Пусто — без предела. Ограничивает только награду пригласившего'),
(N'ReferralSettings', N'BonusExpiresInDays', N'Пусто — не сгорают'),
(N'ReferralSettings', N'InviteExpiresInDays', N'Пусто или ноль — бессрочно'),
(N'ReferralSettings', N'ReferrerDiscountTicketId', N'Tickets.IdTicket. Пусто — скидка на всё'),
(N'ReferralSettings', N'ReferrerDiscountActionId', N'cs_Discount.ID. Одна на всю программу'),
(N'ReferralSettings', N'ReferredDiscountTicketId', N'Tickets.IdTicket. Пусто — скидка на всё'),
(N'ReferralSettings', N'ReferredDiscountActionId', N'cs_Discount.ID. Одна на всю программу'),
(N'ReferralSettings', N'InviteText', N'Текст в боте для пригласившего. Пусто — стандартный; {Reward} — его награда, {FriendReward} — награда другу'),
(N'ReferralSettings', N'ShareText', N'Сообщение другу вместе со ссылкой. Пусто — стандартное'),
(N'ReferralSettings', N'ReferrerRewardMessage', N'Уведомление пригласившему о награде. Пусто — стандартное'),
(N'ReferralSettings', N'ReferredRewardMessage', N'Уведомление другу о награде. Пусто — стандартное'),

(N'ReferralCodes', NULL, N'Личный код приглашения. Один на клиента, не меняется'),
(N'ReferralCodes', N'VisitorId', N'CashboxVisitor.IdVisitor, он же первичный ключ'),
(N'ReferralCodes', N'Code', N'Попадает в ссылку-приглашение'),

(N'Referrals', NULL, N'Приглашение: кто кого позвал и до какой стадии дошло'),
(N'Referrals', N'ReferrerVisitorId', N'CashboxVisitor.IdVisitor'),
(N'Referrals', N'ReferredChatId', N'Известен раньше, чем приглашённый привяжет профиль'),
(N'Referrals', N'ReferredVisitorId', N'CashboxVisitor.IdVisitor. Пусто, пока не привязал профиль'),
(N'Referrals', N'Status', N'0 — перешёл по ссылке, 1 — привязал профиль, 2 — дошёл до покупки, но награда не полагалась, 3 — награды выданы, 4 — отказано по существу, 5 — истёк срок. Отказ блокирует повторное приглашение чата, истёкший срок — нет'),
(N'Referrals', N'CreatedAt', N'Переход по ссылке. От этой даты считается срок приглашения'),
(N'Referrals', N'QualifiedAt', N'От этой даты отсчитывается триггер «засчитан реферал»'),
(N'Referrals', N'ReferredPhone', N'Из телеграма, по нему ищется существующий клиент');

INSERT INTO #opis (tabl, stolb, opis) VALUES
(N'TelegramLinks', NULL, N'Привязка телеграма к клиенту. Действующая привязка и есть участие в программе, отдельного поля «участник» нет'),
(N'TelegramLinks', N'VisitorId', N'CashboxVisitor.IdVisitor'),
(N'TelegramLinks', N'TelegramChatId', N'Куда бот шлёт сообщения'),
(N'TelegramLinks', N'TelegramUsername', N'На момент привязки'),
(N'TelegramLinks', N'LinkMethod', N'0 — неизвестно, 1 — по телефону, 2 — по коду из CRM'),
(N'TelegramLinks', N'IsActive', N'Снимается автоматически, если клиент заблокировал бота'),

(N'TelegramLinkCodes', NULL, N'Одноразовый код привязки телеграма, выдаёт оператор в CRM'),
(N'TelegramLinkCodes', N'Code', N'Клиент вводит его боту'),
(N'TelegramLinkCodes', N'VisitorId', N'CashboxVisitor.IdVisitor'),
(N'TelegramLinkCodes', N'IsUsed', N'После использования значение кода можно выдать заново'),

(N'TelegramBindAttempts', NULL, N'Неудачные попытки привязки. Защита от перебора кодов'),

(N'SupportTickets', NULL, N'Обращения клиентов из бота и ответы на них'),
(N'SupportTickets', N'VisitorId', N'CashboxVisitor.IdVisitor'),
(N'SupportTickets', N'Status', N'0 — открыто, 1 — отвечено, 2 — закрыто'),
(N'SupportTickets', N'AnswerText', N'Уходит клиенту в бот'),
(N'SupportTickets', N'AnsweredBy', N'Логин сотрудника'),
(N'SupportTickets', N'AnswerDelivered', N'0 — ответ есть только в истории обращений в приложении: клиент отвязал или заблокировал бота');

INSERT INTO #opis (tabl, stolb, opis) VALUES
(N'AppUsers', NULL, N'Сотрудники, работающие в CRM. К клиентам и к кассе отношения не имеет'),
(N'AppUsers', N'PasswordHash', N'Формат pbkdf2$sha256$итерации$соль$хэш'),
(N'AppUsers', N'Role', N'Reception, Manager, Administrator. От неё зависят права'),
(N'AppUsers', N'IsActive', N'Уволенных гасим, а не удаляем: имя должно остаться в журнале действий'),
(N'AppUsers', N'MustChangePassword', N'Пока не сменит, дальше страницы смены не пускают. Проверяется на сервере'),
(N'AppUsers', N'PasswordChangedAt', N'Сессии, выданные раньше этой отметки, недействительны. Пусто у старых записей'),

(N'UserActionLog', NULL, N'Журнал действий сотрудников: кто что менял'),
(N'UserActionLog', N'UserId', N'AppUsers.Id. Пусто, если сотрудника удалили'),
(N'UserActionLog', N'UserLogin', N'Логин на момент действия — остаётся, даже если сотрудника удалили');

INSERT INTO #opis (tabl, stolb, opis) VALUES
(N'GymClients', NULL, N'Клиенты тренажёрки из выгрузки 1С. В кассу бассейна не попадают'),
(N'GymClients', N'Phone', N'Последние 9 цифр белорусского номера. Пусто, если номер не распознан'),
(N'GymClients', N'PhoneRaw', N'Номер как в выгрузке'),
(N'GymClients', N'Source', N'0 — выгрузка 1С, 1 — заведён вручную в CRM'),
(N'GymClients', N'VisitorId', N'CashboxVisitor.IdVisitor, если человек ходит и в бассейн'),
(N'GymClients', N'LinkMethod', N'0 — не связан, 1 — телефон+ФИО, 2 — телефон+ДР, 3 — ФИО+ДР, 4 — вручную, 5 — телефон+ФИО с опечаткой, 6 — телефон+фамилия и имя, отчество другое'),
(N'GymClients', N'RejectedVisitorId', N'Связь с этой карточкой сняли вручную — автосопоставление к ней не вернёт'),
(N'GymClients', N'IsActive', N'Был в последней выгрузке. Заведённые вручную не гаснут'),
(N'GymSubscriptions', NULL, N'Снимок последнего абонемента с каждой загрузки. Нигде не показывается'),
(N'GymImports', NULL, N'Журнал загрузок выгрузки 1С'),
(N'GymImports', N'CompletedAt', N'Пусто — загрузка прервалась на середине; повторная загрузка того же файла её доделает'),
(N'GymTelegramLinks', NULL, N'Бот у клиентов только тренажёрки. Связанные с бассейном привязываются через TelegramLinks'),
(N'GymTelegramLinks', N'GymClientId', N'GymClients.Id'),
(N'GymTelegramLinkCodes', NULL, N'Коды привязки, выданные администратором тренажёрки. Не пересекаются с TelegramLinkCodes'),
(N'TelegramStartTags', NULL, N'Откуда человек пришёл в бота: параметр /start, например gym — QR на кассе тренажёрки'),
(N'GymSegments', NULL, N'Сегменты клиентов тренажёрки'),
(N'GymSegments', N'FilterJson', N'Фильтр по клиентам тренажёрки (GymClientFilterRequest)'),
(N'GymCampaigns', NULL, N'Рассылки клиентам только тренажёрки. Связанным с бассейном пишет бассейн'),
(N'GymCampaigns', N'AudienceFilterJson', N'Фильтр аудитории на момент создания'),
(N'GymCampaigns', N'Status', N'1 — запланирована, 2 — в очереди, 3 — идёт, 4 — завершена, 6 — отменена'),
(N'GymCampaignTargets', NULL, N'Адресаты рассылок тренажёрки'),
(N'GymCampaignTargets', N'ChatId', N'Чат, куда ушло сообщение. По нему считается норма рассылок, общая с бассейном'),
(N'GymCampaignTargets', N'Status', N'0 — ждёт, 1 — доставлено, 2 — ошибка, 3 — пропущен'),
(N'GymTriggers', NULL, N'Триггеры тренажёрки. Сейчас один вид — день рождения, только для несвязанных с бассейном'),
(N'GymTriggers', N'DaysBefore', N'За сколько дней до дня рождения поздравлять, 0 — в сам день'),
(N'GymTriggerFirings', NULL, N'Отправленные поздравления тренажёрки; ключ birthday:год не даёт поздравить дважды'),
(N'GymTriggerFirings', N'ChatId', N'Чат получателя. Успешные считаются в общую с бассейном норму рассылок'),
(N'LoyaltySettings', N'GymBirthDateSync', N'Дописывать дату рождения из тренажёрки в пустое поле карточки кассы (ночью, порциями)'),
(N'GymBirthDateWrites', NULL, N'Журнал дописанных в кассу дат рождения из тренажёрки; по нему откат при развязке'),
(N'GymBirthDateWrites', N'RolledBackAt', N'Когда откатили при развязке. Если в кассе дату уже поменяли или стёрли, её не трогаем и отметку не ставим — повторно для этой карточки не пишем'),
(N'TelegramLinks', N'GymClientId', N'Клиент тренажёрки, через которого подключён бот. При развязке бот возвращается ему');

DECLARE @t SYSNAME, @c SYSNAME, @d NVARCHAR(1000), @minor INT, @obj INT;
DECLARE @postavleno INT = 0, @propuscheno INT = 0;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT tabl, stolb, opis FROM #opis;
OPEN cur;
FETCH NEXT FROM cur INTO @t, @c, @d;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @obj = OBJECT_ID(N'dbo.' + QUOTENAME(@t));

    IF @obj IS NOT NULL
       AND (@c IS NULL OR COL_LENGTH(N'dbo.' + QUOTENAME(@t), @c) IS NOT NULL)
    BEGIN
        SET @minor = CASE WHEN @c IS NULL THEN 0
                          ELSE (SELECT column_id FROM sys.columns
                                WHERE object_id = @obj AND name = @c) END;

        IF EXISTS (SELECT 1 FROM sys.extended_properties
                   WHERE major_id = @obj AND minor_id = @minor AND name = N'MS_Description')
        BEGIN
            IF @c IS NULL
                EXEC sp_updateextendedproperty N'MS_Description', @d, N'SCHEMA', N'dbo', N'TABLE', @t;
            ELSE
                EXEC sp_updateextendedproperty N'MS_Description', @d, N'SCHEMA', N'dbo', N'TABLE', @t, N'COLUMN', @c;
        END
        ELSE
        BEGIN
            IF @c IS NULL
                EXEC sp_addextendedproperty N'MS_Description', @d, N'SCHEMA', N'dbo', N'TABLE', @t;
            ELSE
                EXEC sp_addextendedproperty N'MS_Description', @d, N'SCHEMA', N'dbo', N'TABLE', @t, N'COLUMN', @c;
        END

        SET @postavleno = @postavleno + 1;
    END
    ELSE
    BEGIN
        SET @propuscheno = @propuscheno + 1;
    END

    FETCH NEXT FROM cur INTO @t, @c, @d;
END

CLOSE cur;
DEALLOCATE cur;
DROP TABLE #opis;

PRINT N'Описаний поставлено: ' + CAST(@postavleno AS NVARCHAR(10))
    + N', пропущено (нет таблицы или столбца): ' + CAST(@propuscheno AS NVARCHAR(10));
GO
