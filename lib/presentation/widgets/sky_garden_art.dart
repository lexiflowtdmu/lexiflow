import 'package:flutter/material.dart';

// Keep this geometry in sync with
// web-dashboard/src/components/views/SkyGardenArt.tsx.
// All coordinates live in a 64x64 box.
class _Shape {
  final double cx, cy, rx, ry;
  final Color color;
  const _Shape(this.cx, this.cy, this.rx, this.ry, this.color);
}

class _CropDef {
  final List<_Shape> shapes;
  final Offset face;
  const _CropDef(this.shapes, this.face);
}

const Map<String, _CropDef> _crops = {
  'corn': _CropDef([
    _Shape(24, 30, 5, 14, Color(0xFF15803D)),
    _Shape(40, 30, 5, 14, Color(0xFF15803D)),
    _Shape(32, 24, 8, 16, Color(0xFFFACC15)),
  ], Offset(32, 25)),
  'tomato': _CropDef([_Shape(32, 26, 14, 13, Color(0xFFEF4444))], Offset(32, 27)),
  'flower': _CropDef([
    _Shape(32, 13, 7, 8, Color(0xFFF472B6)),
    _Shape(43, 21, 8, 7, Color(0xFFF472B6)),
    _Shape(39, 34, 7, 8, Color(0xFFF472B6)),
    _Shape(25, 34, 7, 8, Color(0xFFF472B6)),
    _Shape(21, 21, 8, 7, Color(0xFFF472B6)),
    _Shape(32, 24, 8, 8, Color(0xFFFDE047)),
  ], Offset(32, 24)),
  'apple': _CropDef([
    _Shape(32, 27, 14, 14, Color(0xFFDC2626)),
    _Shape(39, 11, 5, 3, Color(0xFF22C55E)),
  ], Offset(32, 28)),
  'herbs': _CropDef([
    _Shape(20, 28, 8, 11, Color(0xFF16A34A)),
    _Shape(44, 28, 8, 11, Color(0xFF16A34A)),
    _Shape(32, 22, 11, 15, Color(0xFF22C55E)),
  ], Offset(32, 24)),
  'blueberry': _CropDef([
    _Shape(21, 32, 9, 9, Color(0xFF6366F1)),
    _Shape(43, 32, 9, 9, Color(0xFF4F46E5)),
    _Shape(32, 21, 12, 12, Color(0xFF4338CA)),
  ], Offset(32, 22)),
};

/// 0 = sprout (under 34%), 1 = growing, 2 = ripe.
int growthLevel(int progress, int needed, {required bool ripe}) {
  if (ripe) return 2;
  return needed > 0 && progress / needed >= 0.34 ? 1 : 0;
}

class CropArt extends StatelessWidget {
  final String? crop;
  final int level;
  final double size;

  const CropArt({super.key, required this.crop, required this.level, required this.size});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _CropPainter(_crops[crop] ?? _crops['herbs']!, level),
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  final _CropDef def;
  final int level;

  const _CropPainter(this.def, this.level);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64);

    canvas.drawLine(
      const Offset(32, 64),
      Offset(32, level == 0 ? 44 : 28),
      Paint()
        ..color = const Color(0xFF15803D)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    final leafY = level == 0 ? 46.0 : 50.0;
    _leaf(canvas, 21, leafY, 25, const Color(0xFF22C55E));
    _leaf(canvas, 43, leafY, -25, const Color(0xFF16A34A));

    if (level == 0) return;

    final scale = level == 2 ? 1.0 : 0.6;
    canvas.save();
    canvas.translate(32, 26);
    canvas.scale(scale);
    canvas.translate(-32, -26);
    for (final s in def.shapes) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(s.cx, s.cy), width: s.rx * 2, height: s.ry * 2),
        Paint()..color = s.color,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(s.cx - s.rx * 0.35, s.cy - s.ry * 0.4),
          width: s.rx * 0.56,
          height: s.ry * 0.44,
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.4),
      );
    }

    const ink = Color(0xFF0C2D48);
    final f = def.face;
    canvas.drawCircle(f.translate(-4, -1), 1.6, Paint()..color = ink);
    canvas.drawCircle(f.translate(4, -1), 1.6, Paint()..color = ink);
    canvas.drawPath(
      Path()
        ..moveTo(f.dx - 3, f.dy + 3)
        ..quadraticBezierTo(f.dx, f.dy + 6, f.dx + 3, f.dy + 3),
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  void _leaf(Canvas canvas, double x, double y, double degrees, Color color) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(degrees * 3.14159265 / 180);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 22, height: 10),
      Paint()..color = color,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CropPainter old) => old.def != def || old.level != level;
}
