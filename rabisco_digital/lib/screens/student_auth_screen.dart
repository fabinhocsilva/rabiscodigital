import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'student_workspace_screen.dart';

class StudentAuthScreen extends StatefulWidget {
  const StudentAuthScreen({super.key});

  @override
  State<StudentAuthScreen> createState() => _StudentAuthScreenState();
}

class _StudentAuthScreenState extends State<StudentAuthScreen> {
  bool _quickJoin = false;
  bool _loading = false;
  String? _error;

  final _usernameCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Mirrors student.html?code=XXXX-YYYY deep links.
    final codeFromUrl = Uri.base.queryParameters['code'];
    if (codeFromUrl != null && codeFromUrl.isNotEmpty) {
      _codeCtrl.text = codeFromUrl;
      _quickJoin = true;
    }
  }

  Future<void> _loginWithAccount() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final app = context.read<AppState>();
    try {
      final res = await app.api.studentLogin(_usernameCtrl.text.trim(), _pwCtrl.text);
      if (res['ok'] != true) {
        setState(() => _error = res['error']?.toString() ?? 'Incorrect username or password.');
        return;
      }
      app.socket.connect();
      final code = res['classroomCode']?.toString();
      if (code == null || code.isEmpty) {
        setState(() => _error = 'Your account is not assigned to a classroom yet. Ask your teacher for an invite.');
        return;
      }
      final joinRes = await app.socket.studentJoinClassroom(code, res['token']);
      if (joinRes['ok'] != true) {
        setState(() => _error = joinRes['error']?.toString() ?? 'Could not join the classroom.');
        return;
      }
      app.setStudentSession(
        token: res['token'],
        name: res['name'] ?? _usernameCtrl.text,
        avatar: res['avatar'],
        classroomCode: code,
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => StudentWorkspaceScreen(studentId: joinRes['studentId'], classroomCode: code),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = 'Could not reach the server. Is it running?');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _quickJoinSubmit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final app = context.read<AppState>();
    try {
      app.socket.connect();
      final code = _codeCtrl.text.trim().toUpperCase();
      final res = await app.socket.quickJoin(code, _nameCtrl.text.trim(), null);
      if (res['ok'] != true) {
        setState(() => _error = res['error']?.toString() ?? 'Could not join.');
        return;
      }
      app.setStudentSession(
        token: 'guest', // guests aren't authenticated the same way; kept local-only
        name: _nameCtrl.text.trim(),
        classroomCode: code,
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => StudentWorkspaceScreen(studentId: res['studentId'], classroomCode: code),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = 'Could not reach the server. Is it running?');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('My account')),
                    ButtonSegment(value: true, label: Text('Join with a code')),
                  ],
                  selected: {_quickJoin},
                  onSelectionChanged: (s) => setState(() => _quickJoin = s.first),
                ),
                const SizedBox(height: 20),
                if (!_quickJoin) ...[
                  TextField(
                    controller: _usernameCtrl,
                    decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pwCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                  ),
                ] else ...[
                  TextField(
                    controller: _codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Classroom code (e.g. ABCD-1234)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Your name', border: OutlineInputBorder()),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : (_quickJoin ? _quickJoinSubmit : _loginWithAccount),
                    child: _loading
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_quickJoin ? 'Join classroom' : 'Sign in'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
