using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LoyaltySystem.Domain.Entities;

[Table("Surveys")]
public class Survey
{
    [Key]
    public int Id { get; set; }

    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(1000)]
    public string? IntroText { get; set; }

    public string QuestionsJson { get; set; } = "[]";

    public bool IsActive { get; set; } = true;

    public DateTime CreatedAt { get; set; }
}

[Table("SurveyResponses")]
public class SurveyResponse
{
    [Key]
    public long Id { get; set; }

    public int SurveyId { get; set; }

    public int VisitorId { get; set; }

    public int QuestionIndex { get; set; }

    public const int DeclineQuestionIndex = -1;

    public int OptionIndex { get; set; }

    [MaxLength(300)]
    public string OptionText { get; set; } = string.Empty;

    [MaxLength(300)]
    public string? QuestionText { get; set; }

    [MaxLength(16)]
    public string? ShapeStamp { get; set; }

    public DateTime AnsweredAt { get; set; }
}
