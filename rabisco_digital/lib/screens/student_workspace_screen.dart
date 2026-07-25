import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/models.dart';
import '../widgets/whiteboard_canvas.dart';
import '../widgets/drawing_toolbar.dart';

class StudentWorkspaceScreen extends StatefulWidget {
  final String studentId;
  final String classroomCode;

  const StudentWorkspaceScreen({super.key, required this.studentId, required this.classroomCode});

  @override
  State<StudentWorkspaceScreen> createState() => _StudentWorkspaceScreenState();
}

class _StudentWorkspaceScreenState extends State<StudentWorkspaceScreen> {
  final List<Stroke> _objects = [];
  final Map<String, Stroke> _teacherLiveStrokes = {}; // teacher's in-progress annotation
  bool _locked = false;
  String? _hint;
  Color _penColor = Colors.black;
  double _penWidth = 3.0;
  bool _isEraser = false;

  StreamSubscription? _cmdSub;
  StreamSubscription? _teacherLiveSub;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _cmdSub = app.socket.onTeacherCommand.listen(_onTeacherCommand);
    _teacherLiveSub = app.socket.onTeacherStrokeLive.listen((data) {
      final stroke = Stroke.fromJson(data);
      setState(() => _teacherLiveStrokes[stroke.id] = stroke);
    });
  }

  @override
  void dispose() {
    _cmdSub?.cancel();
    _teacherLiveSub?.cancel();
    super.dispose();
  }

  void _onTeacherCommand(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'lock':
        setState(() => _locked = data['locked'] == true);
        break;
      case 'objects':
        // Teacher's annotation was merged server-side and applied wholesale.
        setState(() {
          _objects
            ..clear()
            ..addAll((data['objects'] as List? ?? []).map((o) => Stroke.fromJson(Map<String, dynamic>.from(o))));
          _teacherLiveStrokes.clear();
        });
        break;
      case 'hint':
        setState(() => _hint = data['text']?.toString());
        break;
    }
  }

  void _sync() {
    context.read<AppState>().socket.studentSync(_objects, 1100, 500);
  }

  void _onStrokeLive(Stroke s) {
    context.read<AppState>().socket.strokeLive(s);
  }

  void _onStrokeComplete(Stroke s) {
    setState(() => _objects.add(s));
    _sync();
  }

  void _undo() {
    if (_objects.isEmpty) return;
    setState(() => _objects.removeLast());
    _sync();
  }

  void _clear() {
    setState(() => _objects.clear());
    _sync();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: Text('${app.name ?? 'Student'} — ${widget.classroomCode}'),
        actions: [
          if (_locked)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Chip(avatar: Icon(Icons.lock, size: 16), label: Text('Locked by teacher')),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_hint != null)
            Container(
              width: double.infinity,
              color: Colors.amber.shade100,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_hint!)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _hint = null)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: DrawingToolbar(
              color: _penColor,
              strokeWidth: _penWidth,
              isEraser: _isEraser,
              onColorChanged: (c) => setState(() => _penColor = c),
              onWidthChanged: (w) => setState(() => _penWidth = w),
              onEraserToggled: (v) => setState(() => _isEraser = v),
              onUndo: _undo,
              onClear: _clear,
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: WhiteboardCanvas(
                    strokes: _objects,
                    liveStrokes: _teacherLiveStrokes.values.toList(),
                    locked: _locked,
                    penColor: _penColor,
                    penWidth: _penWidth,
                    isEraser: _isEraser,
                    onStrokeLive: _onStrokeLive,
                    onStrokeComplete: _onStrokeComplete,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
