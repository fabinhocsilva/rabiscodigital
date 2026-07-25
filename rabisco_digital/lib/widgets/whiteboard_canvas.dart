import 'package:flutter/material.dart';
import '../models/models.dart';

/// The freehand drawing surface used by both the student workspace and the
/// teacher's "view & annotate" panel. Renders committed [strokes] plus any
/// [liveStrokes] currently being drawn by the other party (e.g. the teacher
/// sees the student's in-progress stroke before it's committed, and vice
/// versa), then reports locally-drawn strokes back through the callbacks.
class WhiteboardCanvas extends StatefulWidget {
  final List<Stroke> strokes;
  final List<Stroke> liveStrokes;
  final bool locked;
  final Color penColor;
  final double penWidth;
  final bool isEraser;
  final void Function(Stroke stroke)? onStrokeLive; // called on every point added
  final void Function(Stroke stroke)? onStrokeComplete; // called on pointer up
  final double width;
  final double height;

  const WhiteboardCanvas({
    super.key,
    required this.strokes,
    this.liveStrokes = const [],
    this.locked = false,
    this.penColor = Colors.black,
    this.penWidth = 3.0,
    this.isEraser = false,
    this.onStrokeLive,
    this.onStrokeComplete,
    this.width = 1100,
    this.height = 500,
  });

  @override
  State<WhiteboardCanvas> createState() => _WhiteboardCanvasState();
}

class _WhiteboardCanvasState extends State<WhiteboardCanvas> {
  Stroke? _current;
  int _strokeCounter = 0;

  String _newId() => 'stroke_${DateTime.now().millisecondsSinceEpoch}_${_strokeCounter++}';

  void _onPanStart(DragStartDetails details) {
    if (widget.locked) return;
    final box = context.findRenderObject() as RenderBox;
    final local = box.globalToLocal(details.globalPosition);
    setState(() {
      _current = Stroke(
        id: _newId(),
        points: [local],
        colorValue: (widget.isEraser ? Colors.white : widget.penColor).value,
        strokeWidth: widget.isEraser ? widget.penWidth * 4 : widget.penWidth,
        isEraser: widget.isEraser,
      );
    });
    if (_current != null) widget.onStrokeLive?.call(_current!);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.locked || _current == null) return;
    final box = context.findRenderObject() as RenderBox;
    final local = box.globalToLocal(details.globalPosition);
    setState(() {
      _current = _current!.copyWith(points: [..._current!.points, local]);
    });
    widget.onStrokeLive?.call(_current!);
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.locked || _current == null) return;
    final finished = _current!;
    setState(() => _current = null);
    widget.onStrokeComplete?.call(finished);
  }

  @override
  Widget build(BuildContext context) {
    final allStrokes = [
      ...widget.strokes,
      ...widget.liveStrokes,
      if (_current != null) _current!,
    ];
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.hardEdge,
        child: CustomPaint(
          painter: _WhiteboardPainter(allStrokes),
          size: Size(widget.width, widget.height),
        ),
      ),
    );
  }
}

class _WhiteboardPainter extends CustomPainter {
  final List<Stroke> strokes;
  _WhiteboardPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (stroke.points.length == 1) {
        canvas.drawCircle(stroke.points.first, stroke.strokeWidth / 2, paint..style = PaintingStyle.fill);
        continue;
      }
      final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (final p in stroke.points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WhiteboardPainter oldDelegate) => true;
}
