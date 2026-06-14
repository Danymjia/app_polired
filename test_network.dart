import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final loginRes = await http.post(
    Uri.parse('http://127.0.0.1:3000/api/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': 'tefy54.mejia@gmail.com', 'password': 'A12345678'}),
  );
  
  if (loginRes.statusCode == 200) {
    final token = jsonDecode(loginRes.body)['token'];
    print('Token obtained');
    
    final res = await http.get(
      Uri.parse('http://127.0.0.1:3000/api/redes/listar'),
      headers: {'Authorization': 'Bearer $token'},
    );
    print('Status: ${res.statusCode}');
    print('Body: ${res.body}');
  } else {
    print('Login failed: ${loginRes.statusCode} ${loginRes.body}');
  }
}
