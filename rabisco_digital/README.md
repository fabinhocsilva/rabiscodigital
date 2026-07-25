# Rabisco Digital

A Flutter Web rewrite of the Slate client. The backend (`server.js`, Express + Socket.IO)
is unchanged — this only replaces `index.html` / `teacher.html` / `student.html` with a
Flutter app so you can edit the client in one language/toolchain instead of raw HTML/JS.

## Running it

1. Keep your existing Slate `server.js` running exactly as before:
   ```
   npm install
   npm start
   ```
   (defaults to `http://localhost:3001`)

2. In this folder:
   ```
   flutter pub get
   flutter run -d chrome
   ```
   On first launch it asks for the server address — enter `http://localhost:3001`
   (or wherever you deploy `server.js`, e.g. your Render URL).

3. To ship it as a static site next to (or instead of) the old HTML pages:
   ```
   flutter build web
   ```
   Copy the contents of `build/web/` into `server.js`'s `public/` folder (or host it
   separately) and it'll talk to the same server over Socket.IO/REST.

## What's implemented (matches the "genuinely connected" features)

- Teacher sign up / sign in, student sign in, and student **quick join via a code link**
  (`?code=XXXX-YYYY` in the URL still works, same as `student.html` did).
- **Classroom creation** issues a real join code from the server.
- **Live roster** — students appear in the teacher dashboard the moment they join, no refresh.
- **Live drawing sync** — student strokes stream to the teacher's thumbnail in real time.
- **Lock / Unlock** from a student's card actually blocks/unblocks their board.
- **Hints** appear as a banner on the student's board.
- **View & Annotate** — draw on a student's board from the teacher dashboard; it's merged
  so it won't erase anything the student draws while the dialog is open.
- Student account management and invitations are wired to the same REST endpoints
  server.js already exposes (`ApiService`), though the dashboard UI for those two is
  minimal for now — a natural next step.

## What's still local-only (unchanged from the original)

- Assignments and analytics — still not wired to the realtime layer (same as before).
- No database, no real auth hardening — same as documented in the original README.

## Project structure

```
lib/
  models/models.dart          — Stroke, StudentRosterEntry, ClassroomSummary, InvitationEntry
  services/api_service.dart   — REST calls (matches server.js's Express routes)
  services/socket_service.dart— Socket.IO events (matches server.js's io.on(...) handlers)
  state/app_state.dart        — session (token/role/name) shared across screens
  widgets/whiteboard_canvas.dart — the drawing surface (CustomPainter + gestures)
  widgets/drawing_toolbar.dart   — color/width/eraser/undo/clear controls
  screens/landing_screen.dart
  screens/teacher_auth_screen.dart
  screens/student_auth_screen.dart
  screens/teacher_dashboard_screen.dart
  screens/student_workspace_screen.dart
  main.dart
```

## A note on verification

This was written without a Flutter/Dart toolchain available in the environment that
generated it, so it hasn't been compiled or run — only checked for structural/syntax
consistency by hand. Run `flutter pub get` and `flutter analyze` first; if anything
doesn't compile, paste the error back and it's a quick fix.
