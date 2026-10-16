using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LoyaltySystem.Domain.Entities;

public enum TelegramLinkMethod
{
    Unknown = 0,

    Phone = 1,

    ReceptionCode = 2
}

/// <summary>
/// Действующая привязка и есть участие в программе
/// </summary>
[Table("TelegramLinks")]
public class TelegramLink
{
    [Key]
    public long Id { get; set; }

    public int VisitorId { get; set; }

    public long TelegramChatId { get; set; }

    [MaxLength(100)]
    public string? TelegramUsername { get; set; }

    [MaxLength(30)]
    public string? PhoneShared { get; set; }

    public int LinkMethod { get; set; }

    public bool IsActive { get; set; } = true;

    public DateTime LinkedAt { get; set; }

    // Клиент тренажёрки, через которого подключён бот: при развязке бот возвращается ему
    public int? GymClientId { get; set; }
}
