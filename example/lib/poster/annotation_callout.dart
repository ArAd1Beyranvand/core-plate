import 'package:flutter/material.dart';

import 'connector_motion.dart';
import 'poster_tokens.dart';

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
    this.compact = false,
  });

  final String index;
  final String label;
  final String title;
  final String body;
  final CalloutSide side;

  /// Shrinks the title/body text styles for cramped layouts (e.g. mobile
  /// landscape's stacked callout grid).
  final bool compact;

  AnnotationCallout withCompact(bool compact) => AnnotationCallout(
        index: index,
        label: label,
        title: title,
        body: body,
        side: side,
        compact: compact,
      );

  /// Persian/Arabic script range — text in these blocks is always shown
  /// right-aligned in RTL direction, regardless of which side of the
  /// poster the callout sits on.
  static final RegExp _rtlScript = RegExp(r'[؀-ۿݐ-ݿ]');

  static bool _isRtl(String text) => _rtlScript.hasMatch(text);

  Widget _line(String text, TextStyle style, TextAlign fallbackAlign) {
    if (_isRtl(text)) {
      return Text(
        text,
        style: style,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
      );
    }
    return Text(text, style: style, textAlign: fallbackAlign);
  }

  @override
  Widget build(BuildContext context) {
    final bool isLeft = side == CalloutSide.left;
    final CrossAxisAlignment cross =
        isLeft ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final TextAlign textAlign = isLeft ? TextAlign.right : TextAlign.left;
    final TextStyle titleStyle =
        compact ? PosterTokens.sectionTitleCompact : PosterTokens.sectionTitle;
    final TextStyle bodyStyle =
        compact ? PosterTokens.bodyCompact : PosterTokens.body;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: cross,
      children: [
        _line('$index — $label', PosterTokens.eyebrow, textAlign),
        SizedBox(height: compact ? 4 : 10),
        _line(title, titleStyle, textAlign),
        SizedBox(height: compact ? 4 : 12),
        _line(body, bodyStyle, textAlign),
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

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 40, maxWidth: length),
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
    this.connectorAnimation,
    this.connectorEntering = true,
  });

  final AnnotationCallout callout;
  final double connectorLength;
  final double connectorTop;
  final Animation<double>? connectorAnimation;
  final bool connectorEntering;

  /// When false the callout is shown on its own, with no connector line — used
  /// by the stacked layout where callouts no longer point at the device.
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    if (!showConnector) return callout;

    final Widget connector = Padding(
      padding: EdgeInsets.only(top: connectorTop),
      child: AnimatedConnectorLine(
        side: callout.side,
        length: connectorLength,
        animation: connectorAnimation,
        entering: connectorEntering,
      ),
    );

    final Widget flexibleConnector = Flexible(
      fit: FlexFit.loose,
      child: connector,
    );
    final Widget flexibleCallout = Flexible(
      fit: FlexFit.tight,
      child: callout,
    );

    final List<Widget> children = callout.side == CalloutSide.left
        ? [flexibleCallout, flexibleConnector]
        : [flexibleConnector, flexibleCallout];

    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
