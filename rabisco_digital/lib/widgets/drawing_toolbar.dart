import 'package:flutter/material.dart';

class DrawingToolbar extends StatelessWidget {
  final Color color;
  final double strokeWidth;
  final bool isEraser;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onWidthChanged;
  final ValueChanged<bool> onEraserToggled;
  final VoidCallback onUndo;
  final VoidCallback onClear;

  static const colors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  const DrawingToolbar({
    super.key,
    required this.color,
    required this.strokeWidth,
    required this.isEraser,
    required this.onColorChanged,
    required this.onWidthChanged,
    required this.onEraserToggled,
    required this.onUndo,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final c in colors)
          GestureDetector(
            onTap: () {
              onEraserToggled(false);
              onColorChanged(c);
            },
            child: CircleAvatar(
              radius: 14,
              backgroundColor: c,
              child: (!isEraser && color.value == c.value)
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Icon(Icons.cleaning_services, size: 16),
          selected: isEraser,
          onSelected: onEraserToggled,
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: Slider(
            value: strokeWidth,
            min: 1,
            max: 20,
            onChanged: onWidthChanged,
          ),
        ),
        IconButton(icon: const Icon(Icons.undo), tooltip: 'Undo', onPressed: onUndo),
        IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Clear', onPressed: onClear),
      ],
    );
  }
}
