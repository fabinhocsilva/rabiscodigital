import 'dart:ui';

/// A single freehand stroke on a whiteboard.
/// This is OUR wire format for board contents — the server (server.js)
/// never inspects it, it just relays whatever JSON we send, so the shape
/// only has to stay consistent between our own teacher/student clients.
class Stroke {
  final String id;
  final List<Offset> points;
  final int colorValue; // Color.value
  final double strokeWidth;
  final bool isEraser;
  final String owner; // 'student' or 'teacher' (for annotate strokes)

  Stroke({
    required this.id,
    required this.points,
    required this.colorValue,
    required this.strokeWidth,
    this.isEraser = false,
    this.owner = 'student',
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
        'color': colorValue,
        'width': strokeWidth,
        'eraser': isEraser,
        'owner': owner,
      };

  static Stroke fromJson(Map<String, dynamic> json) {
    final pts = (json['points'] as List? ?? [])
        .map((p) => Offset(
              (p['x'] as num).toDouble(),
              (p['y'] as num).toDouble(),
            ))
        .toList();
    return Stroke(
      id: json['id']?.toString() ?? '',
      points: pts,
      colorValue: (json['color'] as num?)?.toInt() ?? 0xFF000000,
      strokeWidth: (json['width'] as num?)?.toDouble() ?? 3.0,
      isEraser: json['eraser'] == true,
      owner: json['owner']?.toString() ?? 'student',
    );
  }

  Stroke copyWith({List<Offset>? points}) => Stroke(
        id: id,
        points: points ?? this.points,
        colorValue: colorValue,
        strokeWidth: strokeWidth,
        isEraser: isEraser,
        owner: owner,
      );
}

/// A student's live state as seen by the teacher's roster.
class StudentRosterEntry {
  final String id;
  String name;
  String avatar;
  List<Stroke> objects;
  bool locked;
  String status; // 'active' | 'locked' | 'offline'
  double canvasWidth;
  double canvasHeight;
  Map<String, dynamic> permissions;

  StudentRosterEntry({
    required this.id,
    required this.name,
    required this.avatar,
    required this.objects,
    required this.locked,
    required this.status,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.permissions,
  });

  static StudentRosterEntry fromJson(Map<String, dynamic> json) {
    return StudentRosterEntry(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Student',
      avatar: json['avatar']?.toString() ?? '🙂',
      objects: (json['objects'] as List? ?? [])
          .map((o) => Stroke.fromJson(Map<String, dynamic>.from(o)))
          .toList(),
      locked: json['locked'] == true,
      status: json['status']?.toString() ?? 'active',
      canvasWidth: (json['canvasWidth'] as num?)?.toDouble() ?? 1100,
      canvasHeight: (json['canvasHeight'] as num?)?.toDouble() ?? 500,
      permissions: Map<String, dynamic>.from(json['permissions'] ?? {
        'annotate': true,
        'lock': true,
        'editProfile': true,
      }),
    );
  }
}

/// A classroom as summarized by the server ('roster:update' payload).
class ClassroomSummary {
  final String code;
  final String name;
  final List<StudentRosterEntry> students;

  ClassroomSummary({required this.code, required this.name, required this.students});

  static ClassroomSummary fromJson(Map<String, dynamic> json) {
    return ClassroomSummary(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Classroom',
      students: (json['students'] as List? ?? [])
          .map((s) => StudentRosterEntry.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
    );
  }
}

class InvitationEntry {
  final String id;
  final String teacherName;
  final String classroomCode;
  final String classroomName;

  InvitationEntry({
    required this.id,
    required this.teacherName,
    required this.classroomCode,
    required this.classroomName,
  });

  static InvitationEntry fromJson(Map<String, dynamic> json) => InvitationEntry(
        id: json['id']?.toString() ?? '',
        teacherName: json['teacherName']?.toString() ?? '',
        classroomCode: json['classroomCode']?.toString() ?? '',
        classroomName: json['classroomName']?.toString() ?? '',
      );
}
