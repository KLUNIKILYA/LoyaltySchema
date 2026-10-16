using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LoyaltySystem.Domain.Entities;

/// <summary>
/// Только связь «акция клиент». Сама скидка живёт в кассовой cs_Discount
/// </summary>
[Table("LoyaltyDiscountGrants")]
public class LoyaltyDiscountGrant
{
    [Key]
    public long Id { get; set; }

    public int DiscountId { get; set; }

    public int VisitorId { get; set; }

    public DateTime IssuedAt { get; set; }

    public DateTime? ExpiresAt { get; set; }

    public DateTime? UsedAt { get; set; }

    public int? UsedOrderId { get; set; }

    public bool IsActive { get; set; } = true;

    public int? SourceCampaignId { get; set; }

    public int? SourceTriggerId { get; set; }

    [MaxLength(500)]
    public string? Comment { get; set; }
}
