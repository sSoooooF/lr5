import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final String baseUrl;

  AuthService({required this.baseUrl});

  Future<String?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['token'];
    } else {
      return null;
    }
  }
}
