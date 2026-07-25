import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'screens/landing_screen.dart';

void main() {
  runApp(const RabiscoDigitalApp());
}

class RabiscoDigitalApp extends StatelessWidget {
  const RabiscoDigitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rabisco Digital',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const _ServerSetup(),
    );
  }
}

/// Asks once for the Slate/Rabisco server URL (same server.js you already
/// run) and then builds the shared AppState + socket connection around it.
class _ServerSetup extends StatefulWidget {
  const _ServerSetup();

  @override
  State<_ServerSetup> createState() => _ServerSetupState();
}

class _ServerSetupState extends State<_ServerSetup> {
  final _urlCtrl = TextEditingController(text: 'http://localhost:3001');
  AppState? _appState;

  @override
  void initState() {
    super.initState();
    // When this app is served BY the same server.js it talks to (the
    // recommended single-deploy setup), the page's own origin IS the
    // server address — skip asking and just connect straight to it.
    final detected = _detectDeployedOrigin();
    if (detected != null) {
      _appState = AppState(detected);
    }
  }

  /// Returns the page's own origin only when this looks like a real
  /// deployment (not a local `flutter run -d chrome` dev server, which
  /// serves on localhost/127.0.0.1 at a throwaway port).
  String? _detectDeployedOrigin() {
    final uri = Uri.base;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    if (uri.host == 'localhost' || uri.host == '127.0.0.1' || uri.host.isEmpty) return null;
    final portPart = uri.hasPort && uri.port != 80 && uri.port != 443 ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$portPart';
  }

  @override
  Widget build(BuildContext context) {
    if (_appState != null) {
      return ChangeNotifierProvider.value(
        value: _appState!,
        child: const LandingScreen(),
      );
    }
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Rabisco Digital', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Server address (your Slate/Node server)', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 16),
                TextField(
                  controller: _urlCtrl,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'http://localhost:3001'),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => setState(() => _appState = AppState(_urlCtrl.text.trim())),
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
