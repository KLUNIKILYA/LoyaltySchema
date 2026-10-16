using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LoyaltySystem.Domain.Entities;

[Table("ChildParents")]
public class ChildParent
{
    [Key]
    public long Id { get; set; }

    public int ChildVisitorId { get; set; }

    /// <summary>Основного родителя сюда не дублируем — он в CashboxVisitor.ParentID</summary>
    public int ParentVisitorId { get; set; }

    [MaxLength(50)]
    public string? Role { get; set; }

    public DateTime CreatedAt { get; set; }
}
