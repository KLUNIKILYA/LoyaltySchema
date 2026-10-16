using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LoyaltySystem.Domain.Entities;

/// <summary>
/// Баланс клиента - сумма активных непросроченных строк отсюда. 
/// </summary>
[Table("BonusTransactions")]
public class BonusTransaction
{
    [Key]
    public long Id { get; set; }

    public int VisitorId { get; set; }

    [Column(TypeName = "decimal(18,2)")]
    public decimal Amount { get; set; }

    public int Reason { get; set; }

    public int? SourceCampaignId { get; set; }

    [MaxLength(500)]
    public string? Comment { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? ExpiresAt { get; set; }

    public bool IsActive { get; set; } = true;
}
