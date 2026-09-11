import 'package:flutter_test/flutter_test.dart';
import 'package:germany_plate/germany_plate.dart';
import 'package:iran_plate/iran_plate.dart';
import 'package:palestine_plate/palestine_plate.dart';
import 'package:plate_gallery/src/sources/sources.dart';
import 'package:yemen_plate/yemen_plate.dart';

/// The coverage this phase is accountable for: every geometry the four
/// packages ship is reachable in the gallery.
///
/// Counted against each package's *own* catalogue surface — the `.all` lists,
/// the geometry maps, the bare consts — rather than against a number typed in
/// here, so a spec added to a package fails this test until an adapter picks it
/// up. That is the whole point of the adapters.
void main() {
  test('Iran: both specs', () {
    expect(const IranSource().specIds, <String>{IranPlates.car.id, IranPlates.bicycle.id});
  });

  test('Germany: the one spec, with its validator', () {
    const GermanySource source = GermanySource();
    expect(source.specIds, <String>{GermanPlates.car.id});
    expect(source.entries.single.validator, isA<GermanPlateValidator>());
  });

  test('Palestine: every spec in both .all lists', () {
    expect(PalestineSource().specIds, <String>{
      for (final spec in PSWestBankPlates.all) spec.id,
      for (final spec in PSGazaPlates.all) spec.id,
    });
  });

  test('Yemen: every geometry in all four maps', () {
    expect(YemenSource().specIds, <String>{
      for (final spec in YemenUnifiedPlates.carGeometries.values) spec.id,
      for (final spec in YemenUnifiedPlates.motoGeometries.values) spec.id,
      for (final spec in YemenNorthernPlates.carGeometries.values) spec.id,
      for (final spec in YemenNorthernPlates.motoGeometries.values) spec.id,
    });
  });

  test('every entry id is unique across the whole gallery', () {
    final List<String> ids = <String>[
      for (final GallerySource source in gallerySources)
        for (final GalleryEntry entry in source.entries) entry.id,
    ];
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('a sample value fits the slots of the spec it is drawn for', () {
    for (final GallerySource source in gallerySources) {
      for (final GalleryEntry entry in source.entries) {
        final List<String?>? values = entry.sampleValues;
        if (values == null) continue;
        expect(values, hasLength(entry.spec.slotCount), reason: entry.id);
      }
    }
  });

  test('sections are stable across reads — the pickers select by equality', () {
    for (final GallerySource source in gallerySources) {
      expect(source.sections, same(source.sections), reason: source.countryName);
    }
  });

  // The two P4/P5 behaviours the gallery exists to make visible, pinned here so
  // they are checked on every run rather than only when somebody looks.
  test('Yemen northern: field colour and panel word both follow the usage', () {
    final List<GalleryEntry> northern = YemenSource().entries
        .where((GalleryEntry e) => e.id.startsWith('ye.northern.car.'))
        .toList();
    // One geometry, one usage each, so the only thing that varies is the class.
    final Map<String, GalleryEntry> byUsage = <String, GalleryEntry>{
      for (final YemenUsage usage in YemenUsage.values)
        if (usage.onNorthern && usage != YemenUsage.military)
          usage.name: northern.firstWhere((GalleryEntry e) => e.id.startsWith('ye.northern.car.${usage.name}.')),
    };
    expect(byUsage, hasLength(greaterThanOrEqualTo(4)));
    expect(
      byUsage.values.map((GalleryEntry e) => e.theme!.plateBackground).toSet(),
      hasLength(byUsage.length),
      reason: 'on System B the field colour *is* the usage class',
    );
    expect(
      byUsage.values.map((GalleryEntry e) => e.country!.captionLines).toSet(),
      hasLength(byUsage.length),
      reason: 'the panel word changes with it',
    );
  });

  test('Palestine legacy: public transport inverts the plate', () {
    final List<GalleryEntry> legacy = PalestineSource().entries
        .where((GalleryEntry e) => e.id.startsWith('ps.wb.legacy.car.'))
        .toList();
    final GalleryEntry private = legacy.firstWhere((GalleryEntry e) => e.id.endsWith('.private'));
    final GalleryEntry bus = legacy.firstWhere((GalleryEntry e) => e.id.endsWith('.publicTransport'));
    expect(private.spec.id, bus.spec.id, reason: 'one geometry, two inks');
    expect(bus.theme!.plateBackground, private.theme!.ink);
    expect(bus.theme!.ink, private.theme!.plateBackground);
    // The ف / P block is printed in the plate's own ink, so it inverts too —
    // the panel is transparent on both and only the lettering carries colour.
    expect(bus.country!.panelTextColor, isNot(private.country!.panelTextColor));
  });
}
