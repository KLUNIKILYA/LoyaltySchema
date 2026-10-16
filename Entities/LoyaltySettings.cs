using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LoyaltySystem.Domain.Entities;

[Table("LoyaltySettings")]
public class LoyaltySettings
{
    [Key]
    public int Id { get; set; } = 1;

    public int MaxPromoMessages { get; set; } = 1;

    public int PromoWindowDays { get; set; } = 7;

    public int SurveyCooldownDays { get; set; } = 30;

    public int QuietFromHour { get; set; } = 22;

    public int QuietToHour { get; set; } = 9;

    public int? BonusLifetimeMonths { get; set; } = 12;

    // Читает касса: сколько рублей стоит один бонус при оплате
    [Column(TypeName = "decimal(9,2)")]
    public decimal BonusRate { get; set; } = 1;

    // Читает касса: какую долю чека можно оплатить бонусами
    public int MaxBonusPaymentPercent { get; set; } = 100;

    public bool AutoUpgradeTiers { get; set; }

    public bool GymBirthDateSync { get; set; }

    public DateTime UpdatedAt { get; set; }
}

[Table("LoyaltyTiers")]
public class LoyaltyTier
{
    [Key]
    public int Id { get; set; }

    public int Level { get; set; }

    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    public decimal LtvThreshold { get; set; }

    public decimal RewardPercent { get; set; }

    public DateTime UpdatedAt { get; set; }
}

public enum ProfileDictionaryKind
{
    Neighborhood = 0,
    Preference = 1,
    Workplace = 2
}

[Table("ProfileDictionaries")]
public class ProfileDictionaryItem
{
    [Key]
    public int Id { get; set; }

    public int Kind { get; set; }

    [MaxLength(200)]
    public string Value { get; set; } = string.Empty;

    public int SortOrder { get; set; }

    public DateTime CreatedAt { get; set; }
}
