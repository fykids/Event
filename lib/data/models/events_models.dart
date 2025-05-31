import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tubes/data/models/task_item_model.dart';

class EventModel {
  final String id;
  final String name;
  final String description;
  final String location;
  final DateTime date;
  final String category;
  final String code;
  final String ownerId;
  final List<String> docLinks;
  final List<String> members;
  final Map<String, bool> rsvp;
  final List<TaskItem> tasks;

  EventModel({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.date,
    required this.category,
    required this.code,
    required this.ownerId,
    required this.docLinks,
    required this.members,
    required this.rsvp,
    required this.tasks,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return EventModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      category: data['category'] ?? '',
      code: data['code'] ?? '',
      ownerId: data['ownerId'] ?? '',
      docLinks: List<String>.from(data['docLinks'] ?? []),
      members: List<String>.from(data['members'] ?? []),
      rsvp: Map<String, bool>.from(data['rsvp'] ?? {}),
      tasks:
          (data['tasks'] as List<dynamic>?)
              ?.map((task) => TaskItem.fromMap(task))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'location': location,
      'date': Timestamp.fromDate(date),
      'category': category,
      'code': code,
      'ownerId': ownerId,
      'docLinks': docLinks,
      'members': members,
      'rsvp': rsvp,
      'tasks': tasks.map((t) => t.toMap()).toList(),
    };
  }
}
