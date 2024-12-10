import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  final String token;

  const TaskDetailScreen({super.key, required this.taskId, required this.token});

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  Map<String, dynamic>? _task;
  List<dynamic> _comments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTaskDetails();
  }

  Future<void> _fetchTaskDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final taskUrl = Uri.parse('http://localhost:5000/tasks/${widget.taskId}');
    final commentsUrl = Uri.parse(
        'http://localhost:5000/tasks/${widget.taskId}/comments');

    try {
      final taskResponse = await http.get(taskUrl, headers: {
        'Content-Type': 'application/json',
        'Authorization': widget.token,
      });

      final commentsResponse = await http.get(commentsUrl, headers: {
        'Content-Type': 'application/json',
        'Authorization': widget.token,
      });

      if (taskResponse.statusCode == 200 &&
          commentsResponse.statusCode == 200) {
        setState(() {
          _task = jsonDecode(taskResponse.body);
          _comments = jsonDecode(commentsResponse.body);
        });
      } else {
        setState(() {
          _errorMessage = 'Ошибка при загрузке данных задачи.';
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

  void _addComment(String comment) async {
    final url = Uri.parse(
        'http://localhost:5000/tasks/${widget.taskId}/comments');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': widget.token,
        },
        body: jsonEncode({'comment': comment}),
      );

      if (response.statusCode == 201) {
        setState(() {
          _comments.add(comment);
        });
      } else {
        _showErrorMessage('Ошибка при добавлении комментария');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_task?['title'] ?? 'Задача'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Описание задачи
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _task?['description'] ?? 'Нет описания',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const Divider(thickness: 1),
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Комментарии:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Список комментариев
                    Expanded(
                      child: ListView.builder(
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_comments[index]),
                            leading: const Icon(Icons.comment),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCommentDialog();
        },
        tooltip: 'Добавить комментарий',
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  void _showAddCommentDialog() {
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Добавить комментарий'),
          content: TextField(
            controller: commentController,
            decoration:
                const InputDecoration(labelText: 'Введите комментарий'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                final comment = commentController.text;
                if (comment.isNotEmpty) {
                  _addComment(comment);
                  Navigator.pop(context);
                } else {
                  _showErrorMessage('Комментарий не может быть пустым');
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
