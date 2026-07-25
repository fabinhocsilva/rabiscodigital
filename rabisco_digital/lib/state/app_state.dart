import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

/// Holds the logged-in session (teacher or student) and the shared
/// service instances, so every screen talks to the same socket connection.
class AppState extends ChangeNotifier {
  String baseUrl;
  late ApiService api;
  late SocketService socket;

  AppState(this.baseUrl) {
    api = ApiService(baseUrl);
    socket = SocketService(baseUrl);
  }

  /// Point the app at a different server (e.g. from the "change server"
  /// option in the landing screen). Tears down the old socket first.
  void changeServer(String newBaseUrl) {
    socket.dispose();
    baseUrl = newBaseUrl;
    api = ApiService(baseUrl);
    socket = SocketService(baseUrl);
    token = null;
    role = null;
    name = null;
    avatar = null;
    classroomCode = null;
    notifyListeners();
  }

  String? token;
  String? role; // 'teacher' | 'student'
  String? name;
  String? avatar;
  String? classroomCode; // for students already tied to a classroom

  bool get isLoggedIn => token != null;

  void setTeacherSession({required String token, required String name}) {
    this.token = token;
    role = 'teacher';
    this.name = name;
    socket.connect();
    notifyListeners();
  }

  void setStudentSession({
    required String token,
    required String name,
    String? avatar,
    String? classroomCode,
  }) {
    this.token = token;
    role = 'student';
    this.name = name;
    this.avatar = avatar;
    this.classroomCode = classroomCode;
    socket.connect();
    notifyListeners();
  }

  void logout() {
    token = null;
    role = null;
    name = null;
    avatar = null;
    classroomCode = null;
    socket.dispose();
    notifyListeners();
  }
}
