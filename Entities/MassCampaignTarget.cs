using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LoyaltySystem.Domain.Entities;

/// <summary>
/// </summary>
[Table("MassCampaignTargets")]
public class MassCampaignTarget
{
    [Key]
    public long Id { get; set; }

    public int MassCampaignId { get; set; }

    public int VisitorId { get; set; }

    public int Status { get; set; }

    public DateTime? ProcessedAt { get; set; }

    [MaxLength(1000)]
    public string? ErrorMessage { get; set; }

    public int AttemptCount { get; set; }
}
