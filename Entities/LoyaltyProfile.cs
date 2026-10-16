using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LoyaltySystem.Domain.Entities;

[Table("LoyaltyProfiles")]
public class LoyaltyProfile
{
    [Key]
    public int VisitorId { get; set; }

    public int TierLevel { get; set; }

    public string? Email { get; set; }

    public string? InstagramUsername { get; set; }

    public string? TelegramUsername { get; set; }

    public bool HasChildren { get; set; }

    public string? Neighborhood { get; set; }

    public string? Workplace { get; set; }

    public string? CustomerStatus { get; set; }

    public DateTime RegistrationDate { get; set; }

    public DateTime? TierChangedAt { get; set; }
}
