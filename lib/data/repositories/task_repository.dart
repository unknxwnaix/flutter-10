import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/data/models/task.dart';

class TaskRepository {
  final CollectionReference _taskCollection =
      FirebaseFirestore.instance.collection('tasks');

  Stream<List<Task>> getTasks(String userId) {
    return _taskCollection
        .where('creator', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Task.fromDocument(doc)).toList());
  }

  Future<void> addTask(Task task) {
    return _taskCollection.add(task.toMap());
  }

  Future<void> updateTask(Task task) {
    return _taskCollection.doc(task.id).update(task.toMap());
  }

  Future<void> deleteTask(String taskId) {
    return _taskCollection.doc(taskId).delete();
  }
}