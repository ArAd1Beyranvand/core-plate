// STABLE — presentation subsystem. Do not refactor for consistency with other
// layers; change only for rendering bugs.

part of 'laptop_deck.dart';

/// Vertical gap left below every keyboard row.
const _rowGap = 10.0;

/// The inner height of the main keyboard well: every deck row plus the gap
/// that follows it. Used to shrink-to-fit the well when the deck is handed
/// less height than its natural total.
double get _deckWellHeight =>
    deckRows.fold<double>(0, (h, r) => h + r.height) +
    _rowGap * deckRows.length;

/// The Material icon a keycap renders in place of its glyph label, if any.
/// The label itself stays the reporting identity, so highlighting and the
/// [_report] contract are unaffected.
IconData? _iconFor(String label) => switch (label) {
      '⌫' => Icons.backspace_outlined,
      '⌧' => Icons.calculate_outlined,
      _ => null,
    };

/// A single keyboard row of keycaps, scaled by [scale] to fit the well.
class _DeckRowStrip extends StatelessWidget {
  const _DeckRowStrip({
    required this.row,
    required this.scale,
    this.onKey,
    this.pressedKey,
  });

  final DeckRow row;
  final double scale;
  final ValueChanged<String>? onKey;
  final String? pressedKey;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: row.height * scale,
      child: Row(
        children: [
          for (var i = 0; i < row.keys.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              flex: (row.keys[i].flex * 100).round(),
              child: _Key(
                label: row.keys[i].label,
                icon: _iconFor(row.keys[i].label),
                onKey: onKey,
                pressedLabel: pressedKey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The underside of the laptop, seen while the keyboard is folded shut:
/// exhaust vents, rear grilles, four feet and an etched line.
class _BackPanel extends StatelessWidget {
  const _BackPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B0D10), Color(0xFF181B21), Color(0xFF212530), Color(0xFF0A0C0F)],
          stops: [0, .38, .62, 1],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth, h = c.maxHeight;
          Widget vent(double left, double top, double width, double height) =>
              Positioned(
                left: left,
                top: top,
                width: width,
                height: height,
                child: CustomPaint(painter: const _VentPainter()),
              );
          Widget foot(double? left, double? right, double top) => Positioned(
                left: left,
                right: right,
                top: top,
                width: w * .032,
                height: h * .06,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF07080A),
                    borderRadius: BorderRadius.all(Radius.circular(99)),
                  ),
                ),
              );

          return Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.8),
                      radius: 0.9,
                      colors: [Color(0x12FFFFFF), Color(0x00FFFFFF)],
                    ),
                  ),
                ),
              ),
              vent(w * .27, h * .05, w * .46, h * .035),
              vent(w * .09, h * .13, w * .20, h * .05),
              vent(w * .71, h * .13, w * .20, h * .05),
              foot(w * .06, null, h * .08),
              foot(null, w * .06, h * .08),
              foot(w * .06, null, h * .86),
              foot(null, w * .06, h * .86),
              Positioned(
                left: 0,
                right: 0,
                bottom: h * .15,
                child: const Center(
                  child: Text(
                    'DESIGNED FOR PLATE OS',
                    style: TextStyle(
                      color: Color(0x29FFFFFF),
                      fontSize: 5,
                      letterSpacing: 1.6,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Thin milled slots — the fan exhaust.
class _VentPainter extends CustomPainter {
  const _VentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final slot = Paint()..color = const Color(0xB8000000);
    final gap = Paint()..color = const Color(0x0DFFFFFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(3)),
      gap,
    );
    for (var x = 0.0; x < size.width; x += 5) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 2, size.height), slot);
    }
  }

  @override
  bool shouldRepaint(covariant _VentPainter oldDelegate) => false;
}

/// Keys that don't report a character — modifiers, function row, arrows.
const _nonReportingKeys = <String>{
  'esc', '⇧', '⇪', '⇥', 'fn', '⌃', '⌥', '⌘', '⏻', '⌧',
  '◂', '▴', '▾', '▸',
  'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9', 'F10', 'F11', 'F12',
};

/// A tappable keycap: presses down and springs back, reporting its label.
class _Key extends StatefulWidget {
  const _Key({required this.label, this.icon, this.onKey, this.pressedLabel});
  final String label;

  /// Rendered instead of [label] when set; [label] is still the reporting
  /// identity, so [_report] and highlighting are unchanged.
  final IconData? icon;
  final ValueChanged<String>? onKey;
  final String? pressedLabel;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  void _report() {
    final label = widget.label;
    if (label.isEmpty || _nonReportingKeys.contains(label)) return;
    if (label == '⌫') {
      widget.onKey?.call('BACKSPACE');
    } else if (label == '⏎') {
      widget.onKey?.call('ENTER');
    } else {
      widget.onKey?.call(label);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pressed = _pressed ||
        (widget.pressedLabel != null && widget.pressedLabel == widget.label);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: _report,
      child: AnimatedScale(
        scale: pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: pressed ? Curves.easeOut : Curves.elasticOut,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF23262B), Color(0xFF141619), Color(0xFF050607)],
              stops: [0, .45, 1],
            ),
            border: const Border(
              top: BorderSide(color: Color(0x33FFFFFF)),
            ),
            boxShadow: pressed
                ? const [
                    BoxShadow(color: Color(0x99000000), blurRadius: 10, offset: Offset(0, 4)),
                  ]
                : const [
                    BoxShadow(color: Color(0xFF34373C), offset: Offset(0, 5)),
                    BoxShadow(color: Color(0xFF1A1C20), offset: Offset(0, 7)),
                    BoxShadow(color: Color(0x99000000), blurRadius: 16, offset: Offset(0, 13)),
                  ],
          ),
          child: FittedBox(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: widget.icon != null
                  ? Icon(widget.icon, size: 18, color: const Color(0xFFE8EBEF))
                  : Text(
                      widget.label,
                      style: const TextStyle(color: Color(0xFFE8EBEF), fontSize: 18, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
