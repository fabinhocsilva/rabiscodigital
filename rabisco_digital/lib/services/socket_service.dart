import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/models.dart';

/// Thin wrapper around the same Socket.IO events server.js already defines.
/// Event names and payload shapes below must match server.js exactly —
/// nothing changed there, only which client sends/receives them.
class SocketService {
  IO.Socket? _socket;
  final String baseUrl;

  SocketService(this.baseUrl);

  final _rosterController = StreamController<ClassroomSummary>.broadcast();
  final _studentObjectsController = StreamController<Map<String, dynamic>>.broadcast();
  final _strokeLiveController = StreamController<Map<String, dynamic>>.broadcast();
  final _teacherCommandController = StreamController<Map<String, dynamic>>.broadcast();
  final _teacherStrokeLiveController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<ClassroomSummary> get onRosterUpdate => _rosterController.stream;
  Stream<Map<String, dynamic>> get onStudentObjects => _studentObjectsController.stream;
  Stream<Map<String, dynamic>> get onStrokeLive => _strokeLiveController.stream;
  Stream<Map<String, dynamic>> get onTeacherCommand => _teacherCommandController.stream;
  Stream<Map<String, dynamic>> get onTeacherStrokeLive => _teacherStrokeLiveController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect() {
    if (_socket != null) return;
    _socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    _socket!.onConnect((_) {});
    _socket!.on('roster:update', (data) {
      _rosterController.add(ClassroomSummary.fromJson(Map<String, dynamic>.from(data)));
    });
    _socket!.on('student:objects', (data) {
      _studentObjectsController.add(Map<String, dynamic>.from(data));
    });
    _socket!.on('stroke:live', (data) {
      _strokeLiveController.add(Map<String, dynamic>.from(data));
    });
    _socket!.on('teacher:command', (data) {
      _teacherCommandController.add(Map<String, dynamic>.from(data));
    });
    _socket!.on('teacher:stroke:live', (data) {
      _teacherStrokeLiveController.add(Map<String, dynamic>.from(data));
    });
    _socket!.connect();
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
  }

  Future<Map<String, dynamic>> _emitAck(String event, Map<String, dynamic> payload) {
    final completer = Completer<Map<String, dynamic>>();
    _socket!.emitWithAck(event, payload, ack: (data) {
      completer.complete(Map<String, dynamic>.from(data ?? {'ok': false, 'error': 'No response.'}));
    });
    return completer.future;
  }

  // ── Teacher ──
  Future<Map<String, dynamic>> createClassroom(String name, String token) =>
      _emitAck('classroom:create', {'name': name, 'token': token});

  Future<Map<String, dynamic>> teacherJoinClassroom(String code, String token) =>
      _emitAck('classroom:teacherJoin', {'code': code, 'token': token});

  Future<Map<String, dynamic>> regenerateCode(String oldCode, String token) =>
      _emitAck('classroom:regenerateCode', {'oldCode': oldCode, 'token': token});

  void teacherLock(String code, String studentId, bool locked) {
    _socket!.emit('teacher:lock', {'code': code, 'studentId': studentId, 'locked': locked});
  }

  void teacherAnnotate(String code, String studentId, List<Stroke> objects) {
    _socket!.emit('teacher:annotate', {
      'code': code,
      'studentId': studentId,
      'objects': objects.map((s) => s.toJson()).toList(),
    });
  }

  void teacherHint(String code, String studentId, String text) {
    _socket!.emit('teacher:hint', {'code': code, 'studentId': studentId, 'text': text});
  }

  void setStudentPermissions(String code, String studentId, Map<String, dynamic> permissions) {
    _socket!.emit('student:permissions', {'code': code, 'studentId': studentId, 'permissions': permissions});
  }

  void teacherStrokeLive(String code, String studentId, Stroke stroke) {
    _socket!.emit('teacher:stroke:live', {
      'code': code,
      'studentId': studentId,
      'pathId': stroke.id,
      'points': stroke.points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'color': stroke.colorValue,
      'width': stroke.strokeWidth,
      'owner': 'teacher',
    });
  }

  // ── Student ──
  Future<Map<String, dynamic>> studentJoinClassroom(String code, String token) =>
      _emitAck('classroom:join', {'code': code, 'token': token});

  Future<Map<String, dynamic>> quickJoin(String code, String name, String? sessionKey) =>
      _emitAck('whiteboard:quickjoin', {'code': code, 'name': name, 'sessionKey': sessionKey});

  void studentSync(List<Stroke> objects, double canvasWidth, double canvasHeight) {
    _socket!.emit('student:sync', {
      'objects': objects.map((s) => s.toJson()).toList(),
      'canvasWidth': canvasWidth,
      'canvasHeight': canvasHeight,
    });
  }

  void strokeLive(Stroke stroke) {
    _socket!.emit('stroke:live', {
      'pathId': stroke.id,
      'points': stroke.points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'color': stroke.colorValue,
      'width': stroke.strokeWidth,
    });
  }
}
