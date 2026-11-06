import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/daram_colors.dart';

/// The DARAM mark: a geometric "D" whose bowl opens around a small mint node,
/// suggesting a balance that keeps moving. It works on light and dark
/// backgrounds and stays legible at launcher-icon size.
class DaramMark extends StatelessWidget {
  const DaramMark({
    super.key,
    this.size = 40,
    this.withBackground = true,
    this.foreground,
    this.accentColor,
  });

  final double size;

  /// When true the mark sits on the brand gradient tile.
  final bool withBackground;

  /// Stroke colour when there is no background (defaults to the brand accent).
  final Color? foreground;

  /// Colour of the node dot.
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _DaramMarkPainter(
          withBackground: withBackground,
          foreground: foreground ?? context.daram.accent,
          accent: accentColor ?? context.daram.income,
        ),
      ),
    );
  }
}

class _DaramMarkPainter extends CustomPainter {
  const _DaramMarkPainter({
    required this.withBackground,
    required this.foreground,
    required this.accent,
  });

  final bool withBackground;
  final Color foreground;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final rect = Offset.zero & size;

    if (withBackground) {
      final background = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6D6AF6), Color(0xFF8B5CF6), Color(0xFF5B57E8)],
          stops: [0, 0.55, 1],
        ).createShader(rect);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(s * 0.29)),
        background,
      );
      // Soft top highlight for a subtle glass feel.
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(s * 0.29)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white.withValues(alpha: 0.16), Colors.transparent],
          ).createShader(rect),
      );
    }

    final stroke = Paint()
      ..color = withBackground ? Colors.white : foreground
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.072
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final left = s * 0.33;
    final top = s * 0.275;
    final bottom = s * 0.725;
    final mid = s * 0.5;

    // Stem.
    canvas.drawLine(Offset(left, top), Offset(left, bottom), stroke);

    // Bowl: two smooth cubics meeting at the node on the right shoulder.
    final bowl = Path()
      ..moveTo(left, top)
      ..cubicTo(s * 0.68, top, s * 0.80, s * 0.37, s * 0.80, mid);
    canvas.drawPath(bowl, stroke);

    final bowlBottom = Path()
      ..moveTo(s * 0.80, mid)
      ..cubicTo(s * 0.80, s * 0.63, s * 0.68, bottom, left, bottom);
    canvas.drawPath(bowlBottom, stroke);

    // Node dot, sitting on the bowl's shoulder.
    final node = Paint()..color = accent;
    canvas.drawCircle(Offset(s * 0.80, mid), s * 0.055, node);
    // Inner glint.
    canvas.drawCircle(
      Offset(s * 0.786, mid - s * 0.018),
      s * 0.017,
      Paint()..color = Colors.white.withValues(alpha: 0.65),
    );
  }

  @override
  bool shouldRepaint(covariant _DaramMarkPainter oldDelegate) =>
      oldDelegate.withBackground != withBackground ||
      oldDelegate.foreground != foreground ||
      oldDelegate.accent != accent;
}

/// Mark + wordmark + optional tagline.
class DaramLogo extends StatelessWidget {
  const DaramLogo({
    super.key,
    this.markSize = 44,
    this.showTagline = false,
    this.showEnglish = false,
    this.vertical = false,
  });

  final double markSize;
  final bool showTagline;
  final bool showEnglish;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final title = Column(
      crossAxisAlignment: vertical
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'دارام',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: colors.textPrimary,
              ),
            ),
            if (showEnglish) ...[
              const SizedBox(width: 8),
              Text(
                'DARAM',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 3,
                  color: colors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        if (showTagline)
          Text(
            'پولت رو بشناس، هوشمندانه زندگی کن.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.textMuted),
          ),
      ],
    );

    if (vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DaramMark(size: markSize),
          const SizedBox(height: 14),
          title,
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DaramMark(size: markSize),
        const SizedBox(width: 12),
        Flexible(child: title),
      ],
    );
  }
}

/// Decorative brand artwork used on the splash and onboarding screens.
class DaramAura extends StatelessWidget {
  const DaramAura({super.key, this.intensity = 1});

  final double intensity;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -120 * intensity,
            right: -80 * intensity,
            child: _Glow(
              size: 320 * intensity,
              color: colors.gradientStart.withValues(
                alpha: colors.isDark ? 0.35 : 0.22,
              ),
            ),
          ),
          Positioned(
            bottom: -140 * intensity,
            left: -100 * intensity,
            child: _Glow(
              size: 320 * intensity,
              color: colors.gradientEnd.withValues(
                alpha: colors.isDark ? 0.22 : 0.16,
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: 40,
            child: Transform.rotate(
              angle: math.pi / 7,
              child: Container(
                width: 90,
                height: 1,
                color: colors.accent.withValues(alpha: 0.15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}
