using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LoyaltySystem.Domain.Entities;

[Table("TriggerFirings")]
public class TriggerFiring
{
    [Key]
    public long Id { get; set; }

    public int TriggerId { get; set; }

    public int VisitorId { get; set; }

    [MaxLength(200)]
    /// <summary>
    /// Дискретизатор события, вместе с триггером и клиентом даёт уникальность:
    /// "birthday:2026", "anniv:2026:3", "inact:30:2026-05-12", "welcome", "visit:50",
    /// "tier:3", "st_exp:{seasonOrderId}", "st_done:{seasonOrderId}",
    /// "bonus_exp:{bonusTransactionId}"
    /// </summary>
    public string OccurrenceKey { get; set; } = string.Empty;

    public DateTime FiredAt { get; set; }

    public bool Success { get; set; }

    [MaxLength(1000)]
    public string? ErrorMessage { get; set; }
}
