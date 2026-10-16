using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LoyaltySystem.Domain.Entities;

[Table("SpouseLinks")]
public class SpouseLink
{
    [Key]
    public long Id { get; set; }

    public int VisitorAId { get; set; }

    public int VisitorBId { get; set; }

    public DateTime CreatedAt { get; set; }
}
