import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/data/models/task.dart';

class HomeWidgetModel extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  Stream<List<Task>> get tasks => FirebaseFirestore.instance
      .collection("tasks")
      .where('creator', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Task.fromDocument(doc)).toList());

  void onDateChanged(DateTime newDate) {
    _selectedDate = newDate;
    notifyListeners();
  }

  Future<void> deleteTask(String taskId) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
  }
}