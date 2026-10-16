using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LoyaltySystem.Domain.Entities;

/// <summary>
/// Сотрудник, работающий в CRM
/// </summary>
[Table("AppUsers")]
public class AppUser
{
    [Key]
    public int Id { get; set; }

    /// <summary>Логин</summary>
    [MaxLength(100)]
    public string Login { get; set; } = string.Empty;

    [MaxLength(400)]
    public string PasswordHash { get; set; } = string.Empty;

    [MaxLength(200)]
    public string DisplayName { get; set; } = string.Empty;

    /// <summary>Reception / Manager / Administrator</summary>
    [MaxLength(50)]
    public string Role { get; set; } = string.Empty;

    public bool IsActive { get; set; } = true;

    public bool MustChangePassword { get; set; }

    public DateTime? PasswordChangedAt { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? LastLoginAt { get; set; }
}


[Table("UserActionLog")]
public class UserActionLog
{
    [Key]
    public long Id { get; set; }

    public int? UserId { get; set; }

    [MaxLength(100)]
    public string UserLogin { get; set; } = string.Empty;

    [MaxLength(100)]
    public string Action { get; set; } = string.Empty;

    [MaxLength(200)]
    public string? Target { get; set; }

    /// <summary>С какого адреса. Длина под IPv6</summary>
    [MaxLength(45)]
    public string? Ip { get; set; }

    public DateTime CreatedAt { get; set; }
}
