import 'package:flutter/material.dart';

import '../poster/poster_scale.dart';
import '../poster/poster_textures.dart';
import '../poster/poster_tokens.dart';

/// A throwaway gallery rendering every colour swatch, every text specimen
/// (at tier wide) and each texture over the stage black, so the poster
/// foundation (colours, type, textures) can be eyeballed in isolation. Run
/// with:
///
///   flutter run -t lib/dev/token_gallery.dart
void main() => runApp(const TokenGallery());

class TokenGallery extends StatelessWidget {
  const TokenGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: PosterColors.pageBlack,
        appBar: AppBar(title: const Text('Poster tokens')),
        body: PosterMetricsScope(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section('Colours', _colourSwatches()),
                const SizedBox(height: 32),
                _section('Type (wide tier)', [_TypeSpecimens()]),
                const SizedBox(height: 32),
                _section('Textures over stage black', [_TextureTiles()]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  List<Widget> _colourSwatches() {
    final swatches = <String, Color>{
      'pageBlack': PosterColors.pageBlack,
      'stageBlack': PosterColors.stageBlack,
      'groundRadialCore': PosterColors.groundRadialCore,
      'groundRadialMid': PosterColors.groundRadialMid,
      'roadStripe': PosterColors.roadStripe,
      'inkDisplay1': PosterColors.inkDisplay1,
      'inkDisplay2': PosterColors.inkDisplay2,
      'inkDisplay3': PosterColors.inkDisplay3,
      'inkDisplay4': PosterColors.inkDisplay4,
      'inkDisplayCut': PosterColors.inkDisplayCut,
      'inkByline': PosterColors.inkByline,
      'inkMutedItalic': PosterColors.inkMutedItalic,
      'inkLink': PosterColors.inkLink,
      'inkMetaStrong': PosterColors.inkMetaStrong,
      'inkMetaWeak': PosterColors.inkMetaWeak,
      'inkStamp': PosterColors.inkStamp,
      'accent': PosterColors.accent,
      'accentRail': PosterColors.accentRail,
      'pipIdle': PosterColors.pipIdle,
      'flareRed': PosterColors.flareRed,
      'flareInk': PosterColors.flareInk,
      'cardBlueIr': PosterColors.cardBlueIr,
      'cardBlueDe': PosterColors.cardBlueDe,
      'euStar': PosterColors.euStar,
      'flagBrightGreen': PosterColors.flagBrightGreen,
      'flagBrightWhite': PosterColors.flagBrightWhite,
      'flagBrightRed': PosterColors.flagBrightRed,
      'flagMutedGreen': PosterColors.flagMutedGreen,
      'flagMutedWhite': PosterColors.flagMutedWhite,
      'flagMutedRed': PosterColors.flagMutedRed,
      'chipFace': PosterColors.chipFace,
      'chipInk': PosterColors.chipInk,
      'metaStrip': PosterColors.metaStrip,
      'PosterTokens.accent': PosterTokens.accent,
      'PosterTokens.hairline': PosterTokens.hairline,
      'PosterTokens.bg': PosterTokens.bg,
      'PosterTokens.invalid': PosterTokens.invalid,
    };

    final gradients = <String, LinearGradient>{
      'cardSteel': PosterGradients.cardSteel,
      'cardDark': PosterGradients.cardDark,
      'cardChipDark': PosterGradients.cardChipDark,
      'linkButton': PosterGradients.linkButton,
    };

    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: swatches.entries
            .map((e) => _swatch(e.key, color: e.value))
            .toList(),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: gradients.entries
            .map((e) => _swatch(e.key, gradient: e.value))
            .toList(),
      ),
    ];
  }

  Widget _swatch(String label, {Color? color, Gradient? gradient}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 96,
          height: 64,
          decoration: BoxDecoration(
            color: color,
            gradient: gradient,
            border: Border.all(color: Colors.white24),
          ),
        ),
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ),
      ],
    );
  }
}

class _TypeSpecimens extends StatelessWidget {
  const _TypeSpecimens();

  @override
  Widget build(BuildContext context) {
    // Force tier "wide" for the specimen regardless of the actual window
    // size, per the task's "every text specimen at tier wide" requirement.
    const f = 1.0;
    final specimens = <String, TextStyle>{
      'wordmark': PosterType.wordmark(f).copyWith(fontSize: 40),
      'bylineName': PosterType.bylineName(f),
      'bylineRole': PosterType.bylineRole(f),
      'cardEyebrowHero': PosterType.cardEyebrowHero(f),
      'cardEyebrowSteel': PosterType.cardEyebrowSteel(f),
      'cardEyebrowDark': PosterType.cardEyebrowDark(f),
      'cardTitleEnHero': PosterType.cardTitleEnHero(f, 42),
      'cardTitleEnSmall': PosterType.cardTitleEnSmall(f, 34),
      'cardTitleFa': PosterType.cardTitleFa(f, 34),
      'cardBodyEn': PosterType.cardBodyEn(f, 18),
      'cardBodyFa': PosterType.cardBodyFa(f, 19),
      'indexChip': PosterType.indexChip(f, 44),
      'linkLabel': PosterType.linkLabel(f),
      'metaStrong': PosterType.metaStrong(f),
      'metaWeak': PosterType.metaWeak(f),
      'stamp': PosterType.stamp(f),
      'redTag': PosterType.redTag(f),
    };

    return Container(
      color: PosterColors.stageBlack,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: specimens.entries
            .map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  '${e.key}: The quick road / پلاک',
                  style: e.value.copyWith(
                    color: e.value.color ?? PosterColors.inkDisplay1,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TextureTiles extends StatelessWidget {
  const _TextureTiles();

  @override
  Widget build(BuildContext context) {
    final metrics = PosterMetrics.of(context);
    final tiles = <String, DecorationImage>{
      'bg_grain_a @256': textureDecoration(
        texture: PosterTexture.grainA,
        metrics: metrics,
        tileDesignPx: 256,
        opacity: 0.15,
        blendMode: BlendMode.srcOver,
      ),
      'bg_grain_b @320': textureDecoration(
        texture: PosterTexture.grainB,
        metrics: metrics,
        tileDesignPx: 320,
        opacity: 0.44,
        blendMode: BlendMode.srcOver,
      ),
      'tex_screen @180': textureDecoration(
        texture: PosterTexture.screenGrain,
        metrics: metrics,
        tileDesignPx: 180,
        opacity: 0.45,
        blendMode: BlendMode.screen,
      ),
      'tex_overlay @220': textureDecoration(
        texture: PosterTexture.overlayGrain,
        metrics: metrics,
        tileDesignPx: 220,
        opacity: 0.19,
        blendMode: BlendMode.overlay,
      ),
    };

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: tiles.entries
          .map(
            (e) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 220,
                  height: 140,
                  decoration: BoxDecoration(
                    color: PosterColors.stageBlack,
                    image: e.value,
                    border: Border.all(color: Colors.white24),
                  ),
                ),
                Text(
                  e.key,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}
