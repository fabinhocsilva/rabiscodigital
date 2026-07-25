import 'dart:convert';
import 'package:http/http.dart' as http;

/// Talks to the same Node/Express REST endpoints server.js already exposes.
/// Only the client (this Flutter app) changed — the backend is untouched.
class ApiService {
  final String baseUrl; // e.g. http://localhost:3001

  ApiService(this.baseUrl);

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> _headers([String? token]) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body, {String? token}) async {
    final res = await http.post(_u(path), headers: _headers(token), body: jsonEncode(body));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _get(String path, {String? token}) async {
    final res = await http.get(_u(path), headers: _headers(token));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _patch(String path, Map<String, dynamic> body, {String? token}) async {
    final res = await http.patch(_u(path), headers: _headers(token), body: jsonEncode(body));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _delete(String path, {String? token}) async {
    final res = await http.delete(_u(path), headers: _headers(token));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Auth ──
  Future<Map<String, dynamic>> teacherRegister(String name, String email, String password) =>
      _post('/api/teacher/register', {'name': name, 'email': email, 'password': password});

  Future<Map<String, dynamic>> teacherLogin(String email, String password) =>
      _post('/api/teacher/login', {'email': email, 'password': password});

  Future<Map<String, dynamic>> studentLogin(String username, String password) =>
      _post('/api/student/login', {'username': username, 'password': password});

  Future<Map<String, dynamic>> authMe(String token) => _post('/api/auth/me', {'token': token});

  // ── Teacher: student account management ──
  Future<Map<String, dynamic>> listStudents(String token) => _get('/api/students', token: token);

  Future<Map<String, dynamic>> createStudent(
    String token, {
    required String name,
    required String username,
    required String password,
    String avatar = '🙂',
    String? classroomCode,
  }) =>
      _post('/api/students', {
        'name': name,
        'username': username,
        'password': password,
        'avatar': avatar,
        'classroomCode': classroomCode,
      }, token: token);

  Future<Map<String, dynamic>> updateStudent(
    String token,
    String username, {
    String? password,
    String? classroomCode,
    String? avatar,
  }) =>
      _patch('/api/students/$username', {
        if (password != null) 'password': password,
        if (classroomCode != null) 'classroomCode': classroomCode,
        if (avatar != null) 'avatar': avatar,
      }, token: token);

  Future<Map<String, dynamic>> deleteStudent(String token, String username) =>
      _delete('/api/students/$username', token: token);

  // ── Invitations ──
  Future<Map<String, dynamic>> sendInvitation(String token, String studentUsername, String classroomCode) =>
      _post('/api/invitations', {'studentUsername': studentUsername, 'classroomCode': classroomCode}, token: token);

  Future<Map<String, dynamic>> sentInvitations(String token) => _get('/api/invitations/sent', token: token);

  Future<Map<String, dynamic>> myInvitations(String token) => _get('/api/invitations/mine', token: token);

  Future<Map<String, dynamic>> respondInvitation(String token, String id, String status) =>
      _patch('/api/invitations/$id', {'status': status}, token: token);

  Future<Map<String, dynamic>> cancelInvitation(String token, String id) =>
      _delete('/api/invitations/$id', token: token);

  // ── Classrooms / public whiteboard lookup ──
  Future<Map<String, dynamic>> myClassrooms(String token) => _get('/api/classrooms', token: token);

  Future<Map<String, dynamic>> whiteboardInfo(String code) => _get('/api/whiteboard/$code');
}
