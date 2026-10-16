using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LoyaltySystem.Domain.Entities;

public enum ReferralStatus
{
    Pending = 0,
    Bound = 1,
    Qualified = 2,
    Rewarded = 3,
    Rejected = 4,
    Expired = 5
}

public enum ReferralQualifyEvent
{
    FirstPurchase = 0
}

[Table("ReferralSettings")]
public class ReferralSettings
{
    [Key]
    public int Id { get; set; } = 1;

    public bool Enabled { get; set; }

    public bool RewardReferrer { get; set; } = true;

    public decimal ReferrerBonus { get; set; }

    public bool RewardReferred { get; set; }

    public decimal ReferredBonus { get; set; }

    public bool ReferrerGrantDiscount { get; set; }

    public int? ReferrerDiscountTicketId { get; set; }

    public decimal ReferrerDiscountPercent { get; set; }

    public int? ReferrerDiscountValidDays { get; set; }

    [MaxLength(500)]
    public string? ReferrerDiscountComment { get; set; }

    public bool ReferredGrantDiscount { get; set; }

    public int? ReferredDiscountTicketId { get; set; }

    public decimal ReferredDiscountPercent { get; set; }

    public int? ReferredDiscountValidDays { get; set; }

    [MaxLength(500)]
    public string? ReferredDiscountComment { get; set; }

    public int? ReferrerDiscountActionId { get; set; }

    public int? ReferredDiscountActionId { get; set; }

    public int QualifyEvent { get; set; } = (int)ReferralQualifyEvent.FirstPurchase;

    public int? MaxRewardedPerReferrer { get; set; }

    public int? BonusExpiresInDays { get; set; }

    public int? InviteExpiresInDays { get; set; } = 30;

    [MaxLength(1000)]
    public string? InviteText { get; set; }

    [MaxLength(1000)]
    public string? ShareText { get; set; }

    [MaxLength(1000)]
    public string? ReferrerRewardMessage { get; set; }

    [MaxLength(1000)]
    public string? ReferredRewardMessage { get; set; }

    public DateTime UpdatedAt { get; set; }
}

[Table("ReferralCodes")]
public class ReferralCode
{
    [Key]
    public int VisitorId { get; set; }

    [MaxLength(20)]
    public string Code { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }
}

[Table("Referrals")]
public class Referral
{
    [Key]
    public long Id { get; set; }

    public int ReferrerVisitorId { get; set; }

    public long? ReferredChatId { get; set; }

    public int? ReferredVisitorId { get; set; }

    [MaxLength(30)]
    public string? ReferredPhone { get; set; }

    [MaxLength(200)]
    public string? ReferredName { get; set; }

    public int Status { get; set; }

    [MaxLength(200)]
    public string? RejectReason { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? BoundAt { get; set; }

    public DateTime? QualifiedAt { get; set; }

    public DateTime? RewardedAt { get; set; }

    public decimal? ReferrerBonusAwarded { get; set; }

    public decimal? ReferredBonusAwarded { get; set; }

    public decimal? ReferrerDiscountAwarded { get; set; }

    public decimal? ReferredDiscountAwarded { get; set; }
}
