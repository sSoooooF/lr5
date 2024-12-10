import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:todo_client/screens/comment_screen.dart';

class HomeScreen extends StatefulWidget {
  final String token;

  const HomeScreen({Key? key, required this.token}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _tasks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = Uri.parse('http://localhost:5000/tasks');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': widget.token,
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _tasks = jsonDecode(response.body);
        });
      } else {
        setState(() {
          _errorMessage = 'Ошибка при загрузке задач: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Произошла ошибка: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addTask(String title, String description) async {
    final url = Uri.parse('http://localhost:5000/tasks');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': widget.token,
        },
        body: jsonEncode({
          'title': title,
          'description': description,
        }),
      );

      if (response.statusCode == 201) {
        setState(() {
          _tasks.add(jsonDecode(response.body));
        });
      } else {
        _showErrorMessage('Ошибка при добавлении задачи');
      }
    } catch (e) {
      _showErrorMessage('Произошла ошибка: $e');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _exportTasks() async {
    final url = Uri.parse(
        'http://localhost:5000/tasks/export?format=csv'); // URL для экспорта в CSV
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': widget.token,
        },
      );

      if (response.statusCode == 200) {
        // Получаем CSV как строку
        final csvData = response.body;

        // Получаем путь для сохранения файла
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/tasks.csv';

        // Сохраняем файл
        final file = File(filePath);
        await file.writeAsString(csvData);

        // Показываем диалог с предложением сохранить файл
        await _showSaveDialog(filePath);
      } else {
        _showErrorMessage('Ошибка при экспорте задач');
      }
    } catch (e) {
      _showErrorMessage('Произошла ошибка: $e');
    }
  }

  Future<void> _showSaveDialog(String filePath) async {
    final saveResult = await FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        fileName: 'tasks.csv',
        sourceFilePath: filePath,
      ),
    );

    if (saveResult != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Задачи экспортированы в CSV')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при сохранении файла')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Задачи'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTasks,
            tooltip: 'Обновить задачи',
          ),
          IconButton(
            icon: const Icon(Icons.download_for_offline),
            onPressed: _exportTasks,
            tooltip: 'Экспортировать задачи',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _tasks.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 10, thickness: 1),
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return TaskCard(
                      title: task['title'],
                      description: task['description'],
                      isDone: task['done'],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskDetailScreen(
                              token: widget.token,
                              taskId: task['id'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTaskDialog(context);
        },
        tooltip: 'Добавить задачу',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Добавить новую задачу'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Заголовок'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Описание'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                String title = titleController.text;
                String description = descriptionController.text;
                if (title.isNotEmpty) {
                  _addTask(title, description);
                  Navigator.pop(context);
                } else {
                  _showErrorMessage('Заголовок не может быть пустым');
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
  }
}

class TaskCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isDone;
  final VoidCallback onTap; 
  const TaskCard({
    Key? key,
    required this.title,
    required this.description,
    required this.isDone,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          isDone ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isDone ? Colors.green : Colors.grey,
          size: 28,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            decoration:
                isDone ? TextDecoration.lineThrough : TextDecoration.none,
          ),
        ),
        subtitle: Text(
          description.isNotEmpty ? description : 'Нет описания',
          style: const TextStyle(fontSize: 14),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap, // Обработчик клика по задаче
      ),
    );
  }
}
