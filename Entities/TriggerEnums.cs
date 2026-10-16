namespace LoyaltySystem.Domain.Entities;

public enum TriggerType
{
    Birthday = 1,

    RegistrationAnniversary = 2,

    InactivityCrossed = 10,

    Welcome = 20,

    VisitMilestone = 21,

    TierUpgrade = 22,

    SeasonTicketExpiring = 30,

    SeasonTicketExpired = 31,

    BonusesExpiring = 40,

    ChildBirthday = 50,

    ChildAgeChange = 51,

    ReferralQualified = 60,

    ReferralMilestone = 61
}
