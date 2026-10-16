using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LoyaltySystem.Domain.Entities;

public enum SupportTicketStatus
{
    Open = 0,
    Answered = 1,
    Closed = 2
}

[Table("SupportTickets")]
public class SupportTicket
{
    [Key]
    public long Id { get; set; }

    public int VisitorId { get; set; }

    [MaxLength(4000)]
    public string Text { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }

    public int Status { get; set; }

    [MaxLength(4000)]
    public string? AnswerText { get; set; }

    public DateTime? AnsweredAt { get; set; }

    [MaxLength(100)]
    public string? AnsweredBy { get; set; }

    public bool AnswerDelivered { get; set; }
}
