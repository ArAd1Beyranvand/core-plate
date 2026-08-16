import 'package:flutter/material.dart';

import '../theme/poster_tokens.dart';

/// Which side of the device a callout sits on.
enum CalloutSide { left, right }

/// A numbered spec-poster annotation: eyebrow, title and body text.
///
/// Left-hand callouts are right-aligned and right-hand callouts are
/// left-aligned, so both point inward toward the device.
class AnnotationCallout extends StatelessWidget {
  const AnnotationCallout({
    super.key,
    required this.index,
    required this.label,
    required this.title,
    required this.body,
    required this.side,
  });

  final String index;
  final String label;
  final String title;
  final String body;
  final CalloutSide side;

  @override
  Widget build(BuildContext context) {
    final bool isLeft = side == CalloutSide.left;
    final CrossAxisAlignment cross =
        isLeft ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final TextAlign textAlign = isLeft ? TextAlign.right : TextAlign.left;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: cross,
      children: [
        Text('$index — $label', style: PosterTokens.eyebrow),
        const SizedBox(height: 10),
        Text(title, style: PosterTokens.sectionTitle, textAlign: textAlign),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(body, style: PosterTokens.body, textAlign: textAlign),
        ),
      ],
    );
  }
}

/// A hairline connector with a glowing dot at the device-facing end.
class ConnectorLine extends StatelessWidget {
  const ConnectorLine({
    super.key,
    required this.side,
    this.length = 150,
  });

  final CalloutSide side;
  final double length;

  @override
  Widget build(BuildContext context) {
    // For a left-hand callout the device is to the right, so the dot sits on
    // the right end (and vice versa).
    final bool dotOnRight = side == CalloutSide.left;

    final Widget dot = Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: PosterTokens.accent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: PosterTokens.accent.withValues(alpha: 0.45),
            blurRadius: 10,
          ),
        ],
      ),
    );

    final Widget line = Expanded(
      child: Container(height: 1, color: PosterTokens.accentDim),
    );

    return SizedBox(
      width: length,
      child: Row(
        children: dotOnRight ? [line, dot] : [dot, line],
      ),
    );
  }
}

/// Lays out an [AnnotationCallout] with its [ConnectorLine], ordered so the
/// connector always sits on the device-facing side of the text.
class CalloutWithConnector extends StatelessWidget {
  const CalloutWithConnector({
    super.key,
    required this.callout,
    this.connectorLength = 150,
    this.connectorTop = 34,
    this.showConnector = true,
  });

  final AnnotationCallout callout;
  final double connectorLength;
  final double connectorTop;

  /// When false the callout is shown on its own, with no connector line — used
  /// by the stacked layout where callouts no longer point at the device.
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    if (!showConnector) return callout;

    final Widget connector = Padding(
      padding: EdgeInsets.only(top: connectorTop),
      child: ConnectorLine(side: callout.side, length: connectorLength),
    );

    final List<Widget> children = callout.side == CalloutSide.left
        ? [callout, connector]
        : [connector, callout];

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
