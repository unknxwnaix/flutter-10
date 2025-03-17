import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String color;
  final String? imageURL;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.color,
    this.imageURL,
  });

  factory Task.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'],
      description: data['description'],
      date: (data['date'] as Timestamp).toDate(),
      color: data['color'],
      imageURL: data['imageURL'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': date,
      'color': color,
      'imageURL': imageURL,
    };
  }
}