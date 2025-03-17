import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/add_new_task.dart';
import 'package:frontend/utils.dart';
import 'package:frontend/widgets/date_selector.dart';
import 'widgets/custom_notification.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DateTime _selectedDate = DateTime.now();

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
    });
  }

  Future<void> _deleteTask(String taskId) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
    showCustomNotification(context, 'Task deleted successfully!', Colors.red);
  }

  void showCustomNotification(BuildContext context, String message, Color backgroundColor) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => CustomNotification(
        message: message,
        backgroundColor: backgroundColor,
      ),
    );

    // Вставляем уведомление в Overlay
    overlay.insert(overlayEntry);

    // Удаляем уведомление через 3 секунды
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddNewTask(),
                ),
              );
            },
            icon: const Icon(CupertinoIcons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          DateSelector(
            onDateSelected: _onDateChanged,
          ),
          // Задачи
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("tasks")
                  .where('creator',
                      isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No tasks for this date :('),
                  );
                }

                // Фильтруем задачи по выбранной дате
                final tasks = snapshot.data!.docs.where((doc) {
                  final taskDate = (doc['date'] as Timestamp).toDate();
                  return taskDate.year == _selectedDate.year &&
                         taskDate.month == _selectedDate.month &&
                         taskDate.day == _selectedDate.day;
                }).toList();

                if (tasks.isEmpty) {
                  return const Center(
                    child: Text('No tasks for this date :('),
                  );
                }

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    var task = tasks[index].data();
                    Color taskColor = hexToColor(task['color']);
                    DateTime dateTime = (task['date'] as Timestamp).toDate();
                    String formattedTime = DateFormat('hh:mm a').format(dateTime);

                    return Dismissible(
                      key: Key(tasks[index].id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      onDismissed: (direction) {
                        _deleteTask(tasks[index].id);
                      },
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddNewTask(
                                task: {
                                  ...task,
                                  'id': tasks[index].id,
                                },
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: taskColor,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task['title'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        task['description'],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.grey.shade300,
                                backgroundImage: task['imageURL'] != null
                                    ? NetworkImage(task['imageURL'])
                                    : null,
                                child: task['imageURL'] == null
                                    ? const Icon(Icons.person,
                                        color: Colors.grey, size: 30)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formattedTime,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}