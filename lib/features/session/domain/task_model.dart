/// A collaborative task presented to the team during the session.
/// Tasks are created by the admin and assigned per session.
class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.durationSec,
    required this.orderIndex,
    this.answerKey,
    this.hint,
  });

  final String id;
  final String title;
  final String description;

  /// Optional — shown only to the admin after the session for grading.
  /// Not pushed to participants to avoid anchoring their answers.
  final String? answerKey;

  /// Optional nudge shown in the task card if the team appears stuck.
  final String? hint;

  final int durationSec;

  /// Used to keep tasks in a consistent order in the admin list view.
  final int orderIndex;

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      durationSec: json['durationSec'] as int? ??
          600, // default to AppConstants.defaultTaskDurationSec
      orderIndex: json['orderIndex'] as int? ?? 0,
      answerKey: json['answerKey'] as String?,
      hint: json['hint'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'durationSec': durationSec,
        'orderIndex': orderIndex,
        'answerKey': answerKey,
        'hint': hint,
      };
}
