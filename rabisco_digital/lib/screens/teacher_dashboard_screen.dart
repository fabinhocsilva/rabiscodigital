import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/models.dart';
import '../widgets/whiteboard_canvas.dart';
import '../widgets/drawing_toolbar.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  ClassroomSummary? _classroom;
  StreamSubscription? _rosterSub;
  StreamSubscription? _objectsSub;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _rosterSub = app.socket.onRosterUpdate.listen((summary) {
      setState(() => _classroom = summary);
    });
    _objectsSub = app.socket.onStudentObjects.listen((data) {
      // Live per-student object updates arrive here too; roster:update already
      // covers the common case, this keeps thumbnails current between those.
      if (_classroom == null) return;
      final studentId = data['studentId']?.toString();
      final idx = _classroom!.students.indexWhere((s) => s.id == studentId);
      if (idx == -1) return;
      setState(() {
        _classroom!.students[idx].objects = (data['objects'] as List? ?? [])
            .map((o) => Stroke.fromJson(Map<String, dynamic>.from(o)))
            .toList();
      });
    });
    _restoreOrPromptClassroom();
  }

  @override
  void dispose() {
    _rosterSub?.cancel();
    _objectsSub?.cancel();
    super.dispose();
  }

  Future<void> _restoreOrPromptClassroom() async {
    final app = context.read<AppState>();
    setState(() => _loading = true);
    try {
      final res = await app.api.myClassrooms(app.token!);
      final rooms = (res['classrooms'] as List?) ?? [];
      if (rooms.isNotEmpty) {
        final code = rooms.first['code'].toString();
        final joinRes = await app.socket.teacherJoinClassroom(code, app.token!);
        if (joinRes['ok'] == true) {
          setState(() => _classroom = ClassroomSummary.fromJson(joinRes));
        }
      } else {
        if (mounted) await _createClassroomDialog();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createClassroomDialog() async {
    final ctrl = TextEditingController(text: 'My Classroom');
    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Name your classroom'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Create')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final app = context.read<AppState>();
    final res = await app.socket.createClassroom(name, app.token!);
    if (res['ok'] == true) {
      setState(() => _classroom = ClassroomSummary.fromJson({'code': res['code'], 'name': res['name'], 'students': []}));
    }
  }

  Future<void> _regenerateCode() async {
    if (_classroom == null) return;
    final app = context.read<AppState>();
    final res = await app.socket.regenerateCode(_classroom!.code, app.token!);
    if (res['ok'] == true) {
      setState(() => _classroom = ClassroomSummary(code: res['code'], name: _classroom!.name, students: _classroom!.students));
    }
  }

  void _toggleLock(StudentRosterEntry s) {
    context.read<AppState>().socket.teacherLock(_classroom!.code, s.id, !s.locked);
  }

  Future<void> _sendHint(StudentRosterEntry s) async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Send a hint to ${s.name}'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: 'e.g. Check your sign on step 2')),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Send'))],
      ),
    );
    if (text == null || text.isEmpty) return;
    context.read<AppState>().socket.teacherHint(_classroom!.code, s.id, text);
  }

  void _openAnnotate(StudentRosterEntry s) {
    showDialog(
      context: context,
      builder: (_) => _AnnotateDialog(classroomCode: _classroom!.code, student: s),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_classroom == null ? 'Rabisco Digital' : _classroom!.name),
        actions: [
          if (_classroom != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Row(
                  children: [
                    SelectableText(_classroom!.code, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    IconButton(icon: const Icon(Icons.refresh), tooltip: 'New code', onPressed: _regenerateCode),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () {
              app.logout();
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _classroom == null
              ? Center(
                  child: FilledButton(onPressed: _createClassroomDialog, child: const Text('Create a classroom')),
                )
              : _classroom!.students.isEmpty
                  ? Center(
                      child: Text(
                        'Share code ${_classroom!.code} with your students\nto see them appear here live.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: _classroom!.students.length,
                      itemBuilder: (ctx, i) {
                        final s = _classroom!.students[i];
                        return _StudentCard(
                          student: s,
                          onLockToggle: () => _toggleLock(s),
                          onHint: () => _sendHint(s),
                          onAnnotate: () => _openAnnotate(s),
                        );
                      },
                    ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final StudentRosterEntry student;
  final VoidCallback onLockToggle;
  final VoidCallback onHint;
  final VoidCallback onAnnotate;

  const _StudentCard({
    required this.student,
    required this.onLockToggle,
    required this.onHint,
    required this.onAnnotate,
  });

  Color _statusColor() {
    switch (student.status) {
      case 'locked':
        return Colors.orange;
      case 'offline':
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Text(student.avatar, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Expanded(child: Text(student.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
                Icon(Icons.circle, size: 10, color: _statusColor()),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onAnnotate,
              child: FittedBox(
                fit: BoxFit.contain,
                child: IgnorePointer(
                  child: WhiteboardCanvas(
                    strokes: student.objects,
                    width: student.canvasWidth,
                    height: student.canvasHeight,
                    locked: true,
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(student.locked ? Icons.lock : Icons.lock_open, size: 20),
                tooltip: student.locked ? 'Unlock' : 'Lock',
                onPressed: onLockToggle,
              ),
              IconButton(icon: const Icon(Icons.lightbulb_outline, size: 20), tooltip: 'Send hint', onPressed: onHint),
              IconButton(icon: const Icon(Icons.edit, size: 20), tooltip: 'View & annotate', onPressed: onAnnotate),
            ],
          ),
        ],
      ),
    );
  }
}

/// "View & Annotate" — a live, larger view of one student's board where the
/// teacher can draw on top. Keeps merging in the student's own new strokes
/// (via student:objects) so nothing the student draws while this is open
/// gets clobbered, matching the original behavior.
class _AnnotateDialog extends StatefulWidget {
  final String classroomCode;
  final StudentRosterEntry student;

  const _AnnotateDialog({required this.classroomCode, required this.student});

  @override
  State<_AnnotateDialog> createState() => _AnnotateDialogState();
}

class _AnnotateDialogState extends State<_AnnotateDialog> {
  late List<Stroke> _liveStudentObjects;
  final List<Stroke> _teacherStrokes = [];
  Color _penColor = Colors.red;
  double _penWidth = 3.0;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _liveStudentObjects = List.of(widget.student.objects);
    _sub = context.read<AppState>().socket.onStudentObjects.listen((data) {
      if (data['studentId']?.toString() != widget.student.id) return;
      setState(() {
        _liveStudentObjects = (data['objects'] as List? ?? [])
            .map((o) => Stroke.fromJson(Map<String, dynamic>.from(o)))
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _sendMerged() {
    final merged = [..._liveStudentObjects, ..._teacherStrokes];
    context.read<AppState>().socket.teacherAnnotate(widget.classroomCode, widget.student.id, merged);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: Text('Annotating — ${widget.student.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            DrawingToolbar(
              color: _penColor,
              strokeWidth: _penWidth,
              isEraser: false,
              onColorChanged: (c) => setState(() => _penColor = c),
              onWidthChanged: (w) => setState(() => _penWidth = w),
              onEraserToggled: (_) {},
              onUndo: () {
                if (_teacherStrokes.isEmpty) return;
                setState(() => _teacherStrokes.removeLast());
                _sendMerged();
              },
              onClear: () {
                setState(() => _teacherStrokes.clear());
                _sendMerged();
              },
            ),
            const SizedBox(height: 8),
            WhiteboardCanvas(
              strokes: [..._liveStudentObjects, ..._teacherStrokes],
              penColor: _penColor,
              penWidth: _penWidth,
              width: widget.student.canvasWidth,
              height: widget.student.canvasHeight,
              onStrokeLive: (s) {
                context.read<AppState>().socket.teacherStrokeLive(widget.classroomCode, widget.student.id, s);
              },
              onStrokeComplete: (s) {
                setState(() => _teacherStrokes.add(s));
                _sendMerged();
              },
            ),
          ],
        ),
      ),
    );
  }
}
