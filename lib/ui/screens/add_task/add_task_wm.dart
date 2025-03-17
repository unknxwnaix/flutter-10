import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_imagekit/flutter_imagekit.dart';
import 'package:frontend/utils/utils.dart';
import 'package:frontend/ui/widgets/custom_notification.dart';

class AddTaskWidgetModel extends ChangeNotifier {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  Color selectedColor = Colors.blue;
  File? file;
  bool isLoading = false;

  AddTaskWidgetModel({Map<String, dynamic>? task}) {
    if (task != null) {
      titleController.text = task['title'];
      descriptionController.text = task['description'];
      try {
        selectedDate = (task['date'] as Timestamp).toDate();
        selectedTime = TimeOfDay.fromDateTime(selectedDate);
      } catch (e) {
        print('Error converting date: $e');
      }
      selectedColor = hexToColor(task['color']);
    }
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

  Future<void> uploadTaskToDb(Map<String, dynamic>? task) async {
    try {
      String? imageURL;
      if (file != null) {
        imageURL = await uploadImage(file!);
        if (imageURL == null) throw Exception("Ошибка загрузки изображения");
      }

      // Объединяем дату и время
      final combinedDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      final taskData = {
        "title": titleController.text.trim(),
        "description": descriptionController.text.trim(),
        "date": combinedDateTime, // Используем объединенную дату и время
        "creator": FirebaseAuth.instance.currentUser!.uid,
        "postedAt": FieldValue.serverTimestamp(),
        "color": rgbToHex(selectedColor),
        "imageURL": imageURL ?? task?['imageURL'],
      };

      if (task != null) {
        // Обновляем существующую задачу
        await FirebaseFirestore.instance
            .collection("tasks")
            .doc(task['id'])
            .update(taskData);
      } else {
        // Создаем новую задачу
        final id = const Uuid().v4();
        await FirebaseFirestore.instance.collection("tasks").doc(id).set(taskData);
      }
    } catch (e) {
      print("Ошибка: $e");
      rethrow;
    }
  }

  void updateSelectedTime(TimeOfDay newTime) {
    selectedTime = newTime;
    notifyListeners();
  }

  void updateSelectedDate(DateTime newDate) {
    selectedDate = newDate;
    notifyListeners();
  }

  void updateSelectedColor(Color newColor) {
    selectedColor = newColor;
    notifyListeners();
  }

  void updateFile(File? newFile) {
    file = newFile;
    notifyListeners();
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
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
}