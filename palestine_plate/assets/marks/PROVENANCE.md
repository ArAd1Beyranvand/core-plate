# palestine_watermark.png

The decal a Gaza `style2021` plate carries behind its digits: "فلسطين" over
"Palestine", 1200 x 400, transparent background.

**Pre-faded on purpose.** The ink is `#9E9E9E` at alpha 31 — about 12% — baked
into the asset. `PlateDecal` takes an `ImageProvider` and `PlateCanvas` paints
it with `Image(image: ..., fit: BoxFit.contain)`; there is no opacity parameter
anywhere on that path, so fading at render time is not available and the fade
has to live in the pixels. Retune the opacity by regenerating this file, not by
changing anything in `lib/`.

**Not a scan.** The lettering is set from
[Vazirmatn](https://github.com/rastikerdar/vazirmatn) (SIL Open Font License
1.1, notice in `../fonts/OFL-Vazirmatn.txt`) and rasterised with Pillow +
HarfBuzz. It is legible, correctly shaped Arabic — it is *not* a reproduction of
the face a Gaza plate is actually printed in, which no reference photograph in
this repo attests. Treat the letterforms, the two lines' relative size and the
12% figure as `// CALIBRATE`.

A raster rather than the `.svg` this package's layout would suggest: `PlateDecal`
cannot take an `SvgPlateAsset` today. Closing that gap is a `core_plate` change.
