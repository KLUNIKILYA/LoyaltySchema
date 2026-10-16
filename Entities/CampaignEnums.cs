namespace LoyaltySystem.Domain.Entities;

[System.Flags]
public enum CampaignActionType
{
    None = 0,
    AwardBonus = 1,
    SendMessage = 2,
    GrantDiscount = 4,
    SendSurvey = 8
}

public enum CampaignChannel
{
    None = 0,

    Telegram = 2
}

public enum CampaignStatus
{
    Draft = 0,
    Scheduled = 1,
    Queued = 2,
    Running = 3,
    Completed = 4,
    Failed = 5,
    Cancelled = 6
}

public enum CampaignTargetStatus
{
    Pending = 0,
    Done = 1,
    Failed = 2,
    Skipped = 3
}

public enum BonusTransactionReason
{
    Manual = 0,
    Campaign = 1,
    Purchase = 2,
    Refund = 3,
    Expired = 4,
    Referral = 5
}
