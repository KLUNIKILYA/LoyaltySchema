using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LoyaltySystem.Domain.Entities;

[Table("ClientSegments")]
public class ClientSegment
{
    [Key]
    public int Id { get; set; }

    public string Name { get; set; } = string.Empty;

    public string? Description { get; set; }

    public string FilterJson { get; set; } = string.Empty;

    public string? ManualVisitorIdsJson { get; set; }

    public string? ExcludedVisitorIdsJson { get; set; }

    public DateTime CreatedAt { get; set; }
}
