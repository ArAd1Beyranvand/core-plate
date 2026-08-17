import 'package:flutter/material.dart';

import 'poster_tokens.dart';

/// Poster masthead: name + role on the left, eyebrow tag on the right.
class PosterHeader extends StatelessWidget {
  const PosterHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(text: 'ARAD BIRANVAND', style: PosterTokens.headerName),
              TextSpan(
                text: ' / Flutter developer',
                style: PosterTokens.headerRole,
              ),
            ],
          ),
        ),
        const Text(
          'RESPONSIVE SYSTEM — 03 FORM FACTORS',
          style: PosterTokens.eyebrow,
        ),
      ],
    );
  }
}
