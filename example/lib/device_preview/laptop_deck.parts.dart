part of 'laptop_deck.dart';

/// The number pad to the right of the keyboard — decorative, like the rest of
/// the deck.
class _Numpad extends StatelessWidget {
  const _Numpad();

  static const _rows = <List<String>>[
    ['⌧', '÷', '×', '⌫'],
    ['7', '8', '9', '−'],
    ['4', '5', '6', '+'],
    ['1', '2', '3', '⏎'],
    ['0', '.', ''],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B0D10), Color(0xFF14171C)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0xB3000000), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          for (final row in _rows) ...[
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  for (var i = 0; i < row.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      // the zero key spans two columns, as on a real numpad
                      flex: row[i] == '0' ? 208 : 100,
                      child: _Key(label: row[i]),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
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
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
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

/// A static keycap — decorative, no press state.
class _Key extends StatelessWidget {
  const _Key({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFDFEFF), Color(0xFFEBEEF2), Color(0xFFCFD5DD)],
          stops: [0, .45, 1],
        ),
        border: const Border(
          top: BorderSide(color: Color(0xE6FFFFFF)),
        ),
        boxShadow: const [
          BoxShadow(color: Color(0xFF9AA1AA), offset: Offset(0, 5)),
          BoxShadow(color: Color(0xFF6C737B), offset: Offset(0, 7)),
          BoxShadow(color: Color(0x99000000), blurRadius: 16, offset: Offset(0, 13)),
        ],
      ),
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF171A1F), fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
