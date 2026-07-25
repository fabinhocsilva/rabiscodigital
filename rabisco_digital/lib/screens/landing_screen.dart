import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'teacher_auth_screen.dart';
import 'student_auth_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  Future<void> _changeServerDialog(BuildContext context) async {
    final app = context.read<AppState>();
    final ctrl = TextEditingController(text: app.baseUrl);
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Server address'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'http://localhost:3001'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Connect')),
        ],
      ),
    );
    if (url != null && url.isNotEmpty && url != app.baseUrl) {
      app.changeServer(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rabisco Digital'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_ethernet),
            tooltip: 'Change server',
            onPressed: () => _changeServerDialog(context),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit_note, size: 72, color: Colors.deepPurple),
                const SizedBox(height: 12),
                Text(
                  'Rabisco Digital',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'A live classroom whiteboard',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.school),
                    label: const Text("I'm a teacher"),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TeacherAuthScreen()),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.person),
                    label: const Text("I'm a student"),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StudentAuthScreen()),
                    ),
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
