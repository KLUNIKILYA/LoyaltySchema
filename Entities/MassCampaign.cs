using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LoyaltySystem.Domain.Entities;

[Table("MassCampaigns")]
public class MassCampaign
{
    [Key]
    public int Id { get; set; }

    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;

    public string? Description { get; set; }

    public int? SegmentId { get; set; }

    public string? AudienceFilterJson { get; set; }

    public string? AudienceVisitorIdsJson { get; set; }

    public int ActionType { get; set; }

    public int Channel { get; set; }

    public int Status { get; set; }

    public string ActionParamsJson { get; set; } = "{}";

    public int? DiscountId { get; set; }

    public DateTime? ScheduledAt { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? StartedAt { get; set; }

    public DateTime? CompletedAt { get; set; }

    public int TotalCount { get; set; }

    public int ProcessedCount { get; set; }

    public int SuccessCount { get; set; }

    public int FailedCount { get; set; }

    public decimal Budget { get; set; }

    public decimal BonusesIssued { get; set; }

    [MaxLength(2000)]
    public string? LastError { get; set; }
}
