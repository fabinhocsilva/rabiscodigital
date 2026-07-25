import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'teacher_dashboard_screen.dart';

class TeacherAuthScreen extends StatefulWidget {
  const TeacherAuthScreen({super.key});

  @override
  State<TeacherAuthScreen> createState() => _TeacherAuthScreenState();
}

class _TeacherAuthScreenState extends State<TeacherAuthScreen> {
  bool _registering = false;
  bool _loading = false;
  String? _error;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final app = context.read<AppState>();
    try {
      final res = _registering
          ? await app.api.teacherRegister(_nameCtrl.text.trim(), _emailCtrl.text.trim(), _pwCtrl.text)
          : await app.api.teacherLogin(_emailCtrl.text.trim(), _pwCtrl.text);
      if (res['ok'] == true) {
        app.setTeacherSession(token: res['token'], name: res['name'] ?? _nameCtrl.text);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const TeacherDashboardScreen()),
          );
        }
      } else {
        setState(() => _error = res['error']?.toString() ?? 'Something went wrong.');
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
      appBar: AppBar(title: Text(_registering ? 'Teacher — Sign up' : 'Teacher — Sign in')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_registering)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full name', border: OutlineInputBorder()),
                    ),
                  ),
                TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pwCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_registering ? 'Create account' : 'Sign in'),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _registering = !_registering),
                  child: Text(_registering ? 'Already have an account? Sign in' : "Don't have an account? Sign up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
