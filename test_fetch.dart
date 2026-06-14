import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final baseUrl = 'http://127.0.0.1:3000/api';
  
  final loginRes = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': 'tefy54.mejia@gmail.com', 'password': 'A12345678'}),
  );
  
  if (loginRes.statusCode == 200) {
    final token = jsonDecode(loginRes.body)['token'];
    print('Token: $token');
    
    final res = await http.get(
      Uri.parse('$baseUrl/redes/listar'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    print('Status /redes/listar: ${res.statusCode}');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = jsonDecode(res.body);
      if (decoded is List) {
        print('Success! Got list of ${decoded.length} items');
      } else {
        print('Error: Data is not a list. It is ${decoded.runtimeType}');
      }
    } else {
      print('Error Response: ${res.body}');
    }
  } else {
    print('Login Failed: ${loginRes.body}');
  }
}
