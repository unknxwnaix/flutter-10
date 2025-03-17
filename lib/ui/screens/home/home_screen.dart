import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/utils/utils.dart';
import 'package:frontend/ui/widgets/date_selector.dart';
import 'package:provider/provider.dart';
import 'package:frontend/ui/widgets/custom_notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_wm.dart';
import 'package:frontend/data/models/task.dart';
import 'package:frontend/ui/screens/add_task/add_task_screen.dart';
import 'package:frontend/ui/screens/login/login_screen.dart'; // Import the login screen

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()), // Navigate to login screen
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeWidgetModel(),
      child: Consumer<HomeWidgetModel>(
        builder: (context, wm, _) {
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
                IconButton(
                  onPressed: () => _logout(context), // Call the logout function
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
            body: Column(
              children: [
                DateSelector(
                  onDateSelected: wm.onDateChanged,
                ),
                Expanded(
                  child: StreamBuilder<List<Task>>(
                    stream: wm.tasks,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('No tasks for this date :('),
                        );
                      }

                      final tasks = snapshot.data!.where((task) {
                        final taskDate = task.date;
                        return taskDate.year == wm.selectedDate.year &&
                               taskDate.month == wm.selectedDate.month &&
                               taskDate.day == wm.selectedDate.day;
                      }).toList();

                      if (tasks.isEmpty) {
                        return const Center(
                          child: Text('No tasks for this date :('),
                        );
                      }

                      return ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return Dismissible(
                            key: Key(task.id),
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
                              wm.deleteTask(task.id);
                              showCustomNotification(context, 'Task deleted successfully!', Colors.red);
                            },
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddNewTask(
                                      task: {
                                        ...task.toMap(),
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
                                          color: hexToColor(task.color),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              task.title,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              task.description,
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
                                      backgroundImage: task.imageURL != null
                                          ? NetworkImage(task.imageURL!)
                                          : null,
                                      child: task.imageURL == null
                                          ? const Icon(Icons.person,
                                              color: Colors.grey, size: 30)
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('hh:mm a').format(task.date),
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
        },
      ),
    );
  }
}