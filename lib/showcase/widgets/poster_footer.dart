import 'package:flutter/material.dart';

import '../theme/poster_tokens.dart';
import 'tech_chip.dart';

/// Poster footer: tech chips on the left, credentials on the right.
class PosterFooter extends StatelessWidget {
  const PosterFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            TechChip('FLUTTER'),
            TechChip('DART'),
            TechChip('OPEN SOURCE'),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pure Mathematics, Sharif University · entered 2019',
              style: PosterTokens.footerMeta,
              textAlign: TextAlign.right,
            ),
            RichText(
              textAlign: TextAlign.right,
              text: const TextSpan(
                style: PosterTokens.footerMeta,
                children: [
                  TextSpan(
                    text: '4 years',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: ' with Flutter · '),
                  TextSpan(
                    text: '1 year',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: ' on a team'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
