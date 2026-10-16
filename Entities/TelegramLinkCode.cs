using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LoyaltySystem.Domain.Entities;

[Table("TelegramLinkCodes")]
public class TelegramLinkCode
{
    [Key]
    public long Id { get; set; }

    [MaxLength(20)]
    public string Code { get; set; } = string.Empty;

    public int VisitorId { get; set; }

    public DateTime ExpiresAt { get; set; }

    public bool IsUsed { get; set; }

    public long? UsedByChatId { get; set; }

    public DateTime CreatedAt { get; set; }
}
