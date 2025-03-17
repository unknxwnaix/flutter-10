import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:frontend/utils.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_imagekit/flutter_imagekit.dart';
import 'widgets/custom_notification.dart';

class AddNewTask extends StatefulWidget {
  final Map<String, dynamic>? task;

  const AddNewTask({super.key, this.task});

  @override
  State<AddNewTask> createState() => _AddNewTaskState();
}

class _AddNewTaskState extends State<AddNewTask> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  Color _selectedColor = Colors.blue;
  File? file;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      titleController.text = widget.task!['title'];
      descriptionController.text = widget.task!['description'];
      selectedDate = (widget.task!['date'] as Timestamp).toDate();
      _selectedColor = hexToColor(widget.task!['color']);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      final imageUrl = await ImageKit.io(
        imageFile,
        privateKey: "private_9tUZcrufkuy1WAabLfoCxXQGplw=",
        folder: "/dummy/folder/",
        onUploadProgress: (progressValue) {
          print("Прогресс загрузки: $progressValue%");
        },
      );

      print("Файл загружен: $imageUrl");
      return imageUrl;
    } catch (e) {
      print("Ошибка загрузки: $e");
      return null;
    }
  }

  Future<void> uploadTaskToDb() async {
    try {
      String? imageURL;
      if (file != null) {
        imageURL = await uploadImage(file!);
        if (imageURL == null) throw Exception("Ошибка загрузки изображения");
      }

      final taskData = {
        "title": titleController.text.trim(),
        "description": descriptionController.text.trim(),
        "date": selectedDate,
        "creator": FirebaseAuth.instance.currentUser!.uid,
        "postedAt": FieldValue.serverTimestamp(),
        "color": rgbToHex(_selectedColor),
        "imageURL": imageURL ?? widget.task?['imageURL'],
      };

      if (widget.task != null) {
        // Обновляем существующую задачу
        await FirebaseFirestore.instance
            .collection("tasks")
            .doc(widget.task!['id'])
            .update(taskData);
      } else {
        // Создаем новую задачу
        final id = const Uuid().v4();
        await FirebaseFirestore.instance.collection("tasks").doc(id).set(taskData);
      }

      // Возвращаемся на главную страницу
      Navigator.pop(context);
    } catch (e) {
      print("Ошибка: $e");
    }
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
        title: Text(widget.task != null ? 'Edit Task' : 'Add New Task'),
        actions: [
          GestureDetector(
            onTap: () async {
              final selDate = await showDatePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(
                  const Duration(days: 90),
                ),
              );
              if (selDate != null) {
                setState(() {
                  selectedDate = selDate;
                });
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                DateFormat('MM-d-y').format(selectedDate),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final image = await selectImage();
                      setState(() {
                        file = image;
                      });
                    },
                    child: DottedBorder(
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(10),
                      dashPattern: const [10, 4],
                      strokeCap: StrokeCap.round,
                      child: Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: file != null
                            ? Image.file(file!)
                            : widget.task?['imageURL'] != null
                                ? Image.network(widget.task!['imageURL'])
                                : const Center(
                                    child: Icon(
                                      Icons.camera_alt_outlined,
                                      size: 40,
                                    ),
                                  ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      hintText: 'Title',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      hintText: 'Description',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  ColorPicker(
                    pickersEnabled: const {
                      ColorPickerType.wheel: true,
                    },
                    color: _selectedColor,
                    onColorChanged: (Color color) {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    heading: const Text('Select color'),
                    subheading: const Text('Select a different shade'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        isLoading = true; // Начинаем загрузку
                      });
                      await uploadTaskToDb();
                      setState(() {
                        isLoading = false; // Завершаем загрузку
                      });
                      showCustomNotification(
                        context,
                        widget.task != null ? 'Task updated successfully!' : 'Task created successfully!',
                        Colors.green,
                      );
                    },
                    child: const Text(
                      'SUBMIT',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Затемнение и индикатор загрузки
          if (isLoading)
            ModalBarrier(
              color: Colors.black.withOpacity(0.5), // Затемнение экрана
              dismissible: false,
            ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white, // Цвет индикатора
              ),
            ),
        ],
      ),
    );
  }
}