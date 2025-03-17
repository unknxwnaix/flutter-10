import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'add_task_wm.dart';

class AddNewTask extends StatelessWidget {
  final Map<String, dynamic>? task;

  const AddNewTask({super.key, this.task});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddTaskWidgetModel(task: task),
      child: Scaffold(
        appBar: AppBar(
          title: Text(task != null ? 'Edit Task' : 'Add New Task'),
          actions: [
            Consumer<AddTaskWidgetModel>(
              builder: (context, wm, _) {
                return Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final selDate = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (selDate != null) {
                          wm.updateSelectedDate(selDate);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          DateFormat('MM-d-y').format(wm.selectedDate),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10), // Отступ между датой и временем
                    GestureDetector(
                      onTap: () async {
                        final selTime = await showTimePicker(
                          context: context,
                          initialTime: wm.selectedTime,
                        );
                        if (selTime != null) {
                          wm.updateSelectedTime(selTime);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          wm.selectedTime.format(context), // Форматируем время
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        body: Consumer<AddTaskWidgetModel>(
          builder: (context, wm, _) {
            return Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final image = await selectImage();
                            wm.updateFile(image);
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
                              child: wm.file != null
                                  ? Image.file(wm.file!)
                                  : task?['imageURL'] != null
                                      ? Image.network(task!['imageURL'])
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
                          controller: wm.titleController,
                          decoration: const InputDecoration(
                            hintText: 'Title',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: wm.descriptionController,
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
                          color: wm.selectedColor,
                          onColorChanged: (Color color) {
                            wm.updateSelectedColor(color);
                          },
                          heading: const Text('Select color'),
                          subheading: const Text('Select a different shade'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            wm.setLoading(true);
                            try {
                              await wm.uploadTaskToDb(task);
                              wm.showCustomNotification(
                                context,
                                task != null ? 'Task updated successfully!' : 'Task created successfully!',
                                Colors.green,
                              );
                              Navigator.pop(context);
                            } catch (e) {
                              wm.showCustomNotification(
                                context,
                                'Error: $e',
                                Colors.red,
                              );
                            } finally {
                              wm.setLoading(false);
                            }
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
                if (wm.isLoading)
                  ModalBarrier(
                    color: Colors.black.withOpacity(0.5),
                    dismissible: false,
                  ),
                if (wm.isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}