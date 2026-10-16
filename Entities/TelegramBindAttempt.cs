using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LoyaltySystem.Domain.Entities;

[Table("TelegramBindAttempts")]
public class TelegramBindAttempt
{
    [Key]
    public long Id { get; set; }

    public long ChatId { get; set; }

    public DateTime AttemptedAt { get; set; }
}
