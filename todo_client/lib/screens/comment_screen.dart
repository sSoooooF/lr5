import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  TaskDetailScreen({required this.taskId});

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Map<String, dynamic> task;
  late List<String> comments;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    task = {};
    comments = [];
    _fetchTaskDetails();
  }

  _fetchTaskDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final response = await http.get(
      Uri.parse('http://localhost:5000/tasks/${widget.taskId}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        task = jsonDecode(response.body);
        comments = List<String>.from(task['comments'] ?? []);
      });
    }
  }

  _addComment() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final response = await http.post(
      Uri.parse('http://localhost:5000/tasks/${widget.taskId}/comments'),
      headers: {'Authorization': 'Bearer $token'},
      body: jsonEncode({'comment': _commentController.text}),
    );

    if (response.statusCode == 200) {
      setState(() {
        comments.add(_commentController.text);
        _commentController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(task['title'] ?? 'Детали задачи')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Описание: ${task['description'] ?? ''}'),
            const SizedBox(height: 16.0),
            const Text('Комментарии:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  return ListTile(title: Text(comments[index]));
                },
              ),
            ),
            TextField(
              controller: _commentController,
              decoration:
                  const InputDecoration(hintText: 'Сюда пиши комментарий'),
            ),
            ElevatedButton(
              onPressed: _addComment,
              child: const Text('Добавить комментарий'),
            ),
          ],
        ),
      ),
    );
  }
}
