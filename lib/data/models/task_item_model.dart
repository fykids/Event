class TaskItem {
  final String title;
  final bool done;
  final String assignedTo;

  TaskItem({
    required this.title,
    required this.done,
    required this.assignedTo,
  });

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem(
      title: map['title'] ?? '',
      done: map['done'] ?? false,
      assignedTo: map['assignedTo'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'done': done,
      'assignedTo': assignedTo,
    };
  }
}