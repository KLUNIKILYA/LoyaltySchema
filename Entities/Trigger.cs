using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LoyaltySystem.Domain.Entities;

[Table("Triggers")]
public class Trigger
{
    [Key]
    public int Id { get; set; }

    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;

    public string? Description { get; set; }

    public int TriggerType { get; set; }

    public bool IsEnabled { get; set; } = true;

    public string ParamsJson { get; set; } = "{}";

    public string? AudienceFilterJson { get; set; }

    public string ActionParamsJson { get; set; } = "{}";

    public int? DiscountId { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? LastRunAt { get; set; }

    public int TotalFirings { get; set; }
}
