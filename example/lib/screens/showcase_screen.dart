import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plate_number/plate_number.dart';
import 'package:plate_number/model/plate_spec.dart';

import '../device_preview/device_config.dart';
import '../device_preview/device_frame.dart';
import '../device_preview/device_transition.dart';
import '../poster/poster_tokens.dart';
import '../poster/annotation_callout.dart';
import '../poster/corner_brackets.dart';
import '../poster/grid_backdrop.dart';
import '../poster/poster_footer.dart';
import '../poster/poster_header.dart';
import '../showcase/device_cycle.dart';
import '../showcase/plate_typist.dart';
import '../showcase/virtual_keypad.dart';
import '../widgets/plate_display.dart';

/// The non-interactive "spec poster" showcase: a device cycling through form
/// factors at the centre, ringed by numbered annotation callouts.
class ShowcaseScreen extends StatelessWidget {
  const ShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PosterTokens.bg,
      body: Stack(
        children: const [
          Positioned.fill(child: GridBackdrop()),
          Positioned.fill(child: CornerBrackets()),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 56, vertical: 44),
              child: Column(
                children: [
                  PosterHeader(),
                  Expanded(child: _PosterBody()),
                  PosterFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Below this logical width the three-column poster collapses to a stack.
const double _wideBreakpoint = 1180;

// The four annotation callouts, shared between the wide and stacked layouts.
const AnnotationCallout _callout01 = AnnotationCallout(
  index: '01',
  label: 'VIEWPORT',
  title: 'One layout, three devices',
  body: 'Mobile, tablet and laptop states animate between each other.',
  side: CalloutSide.left,
);
const AnnotationCallout _callout02 = AnnotationCallout(
  index: '02',
  label: 'PACKAGE',
  title: 'plate_number',
  body: 'Open-source Flutter package for Iranian vehicle plates.',
  side: CalloutSide.right,
);
const AnnotationCallout _callout03 = AnnotationCallout(
  index: '03',
  label: 'MODES',
  title: 'Input & display',
  body: 'Capture plates field by field, or render them read-only.',
  side: CalloutSide.right,
);
const AnnotationCallout _callout04 = AnnotationCallout(
  index: '04',
  label: 'STYLING',
  title: 'Fully themeable',
  body: 'Spacing, colour and light or dark theme are all yours.',
  side: CalloutSide.left,
);

class _PosterBody extends StatelessWidget {
  const _PosterBody();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _wideBreakpoint) return const _WideBody();
        return const _StackedBody();
      },
    );
  }
}

/// Three columns: callouts flanking the device, connectors pointing inward.
class _WideBody extends StatelessWidget {
  const _WideBody();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        SizedBox(width: 360, child: _LeftCallouts()),
        Expanded(child: _DeviceStage()),
        SizedBox(width: 360, child: _RightCallouts()),
      ],
    );
  }
}

/// Narrow layout: the device on top, callouts as a connector-less 2x2 grid.
class _StackedBody extends StatelessWidget {
  const _StackedBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Expanded(child: _DeviceStage()),
        SizedBox(height: 24),
        Wrap(
          spacing: 48,
          runSpacing: 28,
          children: [
            SizedBox(
              width: 300,
              child: CalloutWithConnector(
                callout: _callout01,
                showConnector: false,
              ),
            ),
            SizedBox(
              width: 300,
              child: CalloutWithConnector(
                callout: _callout02,
                showConnector: false,
              ),
            ),
            SizedBox(
              width: 300,
              child: CalloutWithConnector(
                callout: _callout03,
                showConnector: false,
              ),
            ),
            SizedBox(
              width: 300,
              child: CalloutWithConnector(
                callout: _callout04,
                showConnector: false,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LeftCallouts extends StatelessWidget {
  const _LeftCallouts();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: const [
        // 01 sits high on the left.
        Padding(
          padding: EdgeInsets.only(top: 40),
          child: CalloutWithConnector(callout: _callout01),
        ),
        Spacer(),
        // 04 sits low on the left.
        Padding(
          padding: EdgeInsets.only(bottom: 48),
          child: CalloutWithConnector(callout: _callout04),
        ),
      ],
    );
  }
}

class _RightCallouts extends StatelessWidget {
  const _RightCallouts();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        // 02 sits around the vertical middle.
        SizedBox(height: 150),
        CalloutWithConnector(callout: _callout02),
        Spacer(),
        // 03 sits lower down on the right.
        Padding(
          padding: EdgeInsets.only(bottom: 96),
          child: CalloutWithConnector(callout: _callout03),
        ),
      ],
    );
  }
}

class _DeviceStage extends StatefulWidget {
  const _DeviceStage();

  @override
  State<_DeviceStage> createState() => _DeviceStageState();
}

class _DeviceStageState extends State<_DeviceStage> {
  final DeviceCycleController _controller = DeviceCycleController();
  final PlateTypist _typist = PlateTypist();

  /// Drives the frame's geometry morph; flips the instant a hop starts so the
  /// shell begins reshaping toward the incoming device.
  DeviceType _frameDevice = DeviceType.desktop;

  /// Drives the plate type shown and its backing bloc; lags [_frameDevice],
  /// only catching up during the blank hold once the outgoing plate has faded
  /// out (see [_onContentSwap]).
  DeviceType _contentDevice = DeviceType.desktop;

  /// Bloc for the content device, recreated on every content swap so each plate
  /// starts blank. [PlateDisplay] renders from it via its `bloc` param.
  late PlateCardBloc _bloc = PlateCardBloc(specFor(_contentDevice));

  /// Bumped on every device hop; captured by pending awaits so a stale run
  /// (a delayed typist start from a device we already left) bails out.
  int _generation = 0;

  /// The generation a typing run has already been kicked off for, so a repeated
  /// idle phase for the same device doesn't start a second run.
  int _startedGen = -1;

  /// Which plate slot currently holds focus (its index 2 is the letter slot),
  /// driving the tablet's letters pad. Null when focus is off the plate.
  PlateSlot? _activeSlot;

  /// Latest validation of the German plate's typed value, or null when nothing
  /// has been flagged yet (empty letter slot, or a non-German device is shown).
  /// Drives the tablet plate's active-field colour: red when invalid. Reset on
  /// every content swap, same as [_activeSlot].
  GermanPlateValidationResult? _germanValidation;

  /// Watches [_bloc]'s state so typed German values can be re-validated. Re-
  /// subscribed on every content swap because [_bloc] is recreated there.
  StreamSubscription<PlateCardState>? _blocSub;

  void _setActiveSlot(PlateSlot? slot) {
    if (_activeSlot?.index == slot?.index) return;
    setState(() => _activeSlot = slot);
  }

  /// Subscribes [_validateGermanPlate] to the current [_bloc], dropping any
  /// subscription to a previous (now-closed) bloc first.
  void _listenToBloc() {
    _blocSub?.cancel();
    _blocSub = _bloc.stream.listen(_validateGermanPlate);
  }

  /// Re-derives [_germanValidation] from a fresh plate state. Only meaningful
  /// while the German plate is on screen; a no-op for other devices.
  void _validateGermanPlate(PlateCardState state) {
    if (!mounted || _contentDevice != DeviceType.tablet) return;
    // deCar's slots: district = [0]+[1], identifier letter = [2], serial digits
    // = [3..6]. Treat unset slots as empty strings.
    final values = state.plateNumber.values;
    String at(int i) => (i < values.length ? values[i] : null) ?? '';
    final identifierLetters = at(2);
    // Don't flag anything red while the identifier letter is still blank — an
    // empty letter always fails the regex, which would be noise, not signal.
    if (identifierLetters.isEmpty) {
      if (_germanValidation != null) {
        setState(() => _germanValidation = null);
      }
      return;
    }
    final result = GermanPlateValidator.validate(
      district: at(0) + at(1),
      identifierLetters: identifierLetters,
      identifierDigits: at(3) + at(4) + at(5) + at(6),
    );
    setState(() => _germanValidation = result);
  }

  @override
  void initState() {
    super.initState();
    _listenToBloc();
    // The first device never fires a transition phase, so kick it off directly
    // once the tree is laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartTyping());
  }

  @override
  void dispose() {
    _typist.dispose();
    _blocSub?.cancel();
    _bloc.close();
    _controller.dispose();
    super.dispose();
  }

  void _onDeviceChanged(DeviceType device) {
    _generation++;
    _typist.cancel();
    // Only the frame starts reshaping now. The plate + its bloc stay on the
    // outgoing device until it has faded out; _onContentSwap does the hand-off.
    // DeviceCycle rebuilds its builder as part of the same advance, so the new
    // frame device is picked up without a setState here.
    _frameDevice = device;
  }

  /// Fired by [DeviceFrame] during the blank hold, after the frame has morphed
  /// and content opacity has hit zero — so the outgoing plate widget is already
  /// unmounted and its bloc can be closed and replaced without a visible flash.
  void _onContentSwap() {
    if (!mounted) return;
    _bloc.close();
    _contentDevice = _frameDevice;
    _bloc = PlateCardBloc(specFor(_contentDevice));
    _activeSlot = null;
    _germanValidation = null;
    _listenToBloc();
    setState(() {});
  }

  void _onPhase(DeviceTransitionPhase phase) {
    // At idle the content has fully faded back in, so it's safe to start typing.
    if (phase == DeviceTransitionPhase.idle) _maybeStartTyping();
  }

  void _maybeStartTyping() {
    if (!mounted || _startedGen == _generation) return;
    _startedGen = _generation;
    _runTyping(_generation);
  }

  Future<void> _runTyping(int gen) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted || gen != _generation) return;

    final device = _contentDevice;
    await _typist.run(
      bloc: _bloc,
      steps: switch (device) {
        DeviceType.mobile => bicycleScript,
        DeviceType.tablet => germanCarScript,
        DeviceType.desktop => carScript,
      },
      useLetterPicker: false,
      // The typist (out of scope here) still reports a bare index; resolve it to
      // the matching PlateSlot so _setActiveSlot sees the same type the canvas
      // callback now delivers.
      onSlotChanged: device == DeviceType.tablet
          ? (i) => _setActiveSlot(
                i == null ? null : specFor(_contentDevice).slotAt(i),
              )
          : null,
      context: context,
    );
    if (!mounted || gen != _generation) return;

    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || gen != _generation) return;
    _controller.advance();
  }

  @override
  Widget build(BuildContext context) {
    return DeviceCycle(
      controller: _controller,
      onDeviceChanged: _onDeviceChanged,
      builder: (context, device) {
        // Isolate the device + plate in its own layer. It is expensive to
        // raster (perspective transform, nested FittedBoxes, clips and live
        // TextFields), and on Linux an instant window maximise that forces a
        // full re-raster of it can miss the GL embedder's frame deadline and
        // crash the app with "Timed out waiting for OpenGL frame". A
        // RepaintBoundary lets the resize composite the cached layer instead
        // of re-rendering it from scratch.
        //
        // The AnimatedBuilder rebuilds only the device subtree on each typist
        // keystroke (to flash keys), never the whole stage.
        return RepaintBoundary(
          child: AnimatedBuilder(
            animation: _typist,
            builder: (context, _) => _buildDevice(device),
          ),
        );
      },
    );
  }

  Widget _buildDevice(DeviceType frameDevice) {
    // The shell morphs to [frameDevice], but the plate on the glass stays on
    // [_contentDevice] until the swap, so the outgoing plate keeps rendering
    // through its fade-out instead of being replaced the instant the hop fires.
    final contentDevice = _contentDevice;
    return DeviceFrame(
      device: frameDevice,
      onPhaseChanged: _onPhase,
      onContentSwap: _onContentSwap,
      deckPressedKey: _typist.activeKey,
      builder: (context, config) => PlateDisplay(
        spec: specFor(contentDevice),
        mode: PlateMode.input,
        // activeColor is the completed-field underline colour; swap it to red
        // for the tablet's German plate when the typed value is invalid (e.g. a
        // forbidden letter combination). Other devices keep the accent.
        activeColor: contentDevice == DeviceType.tablet &&
                _germanValidation?.isValid == false
            ? PosterTokens.invalid
            : PosterTokens.accent,
        bloc: _bloc,
        // The laptop deck already carries letter keys, so its letter comes in
        // through the library's on-screen-keypad mode instead of the modal
        // picker. Other devices keep their platform default.
        letterInputMode: contentDevice == DeviceType.desktop ||
                contentDevice == DeviceType.tablet
            ? LetterInputMode.hostKeypad
            : null,
        onActiveSlotChanged:
            contentDevice == DeviceType.tablet ? _setActiveSlot : null,
        keyboard: contentDevice == DeviceType.desktop
            ? null
            : contentDevice == DeviceType.tablet
                ? VirtualKeypad(
                    highlightedKey: _typist.activeKey,
                    compact: false,
                    // FIXME(K5): hard-coded letter-slot index 2.
                    showLetters: _activeSlot?.index == 2,
                    digitAlphabet: PlateAlphabet.latinDigits,
                    letterAlphabet: PlateAlphabet.latinUppercase,
                    // index: 2 works for both scripts today only by coincidence
                    // — PlateSpecs.irCar and PlateSpecs.deCar both happen to put
                    // their single letter slot at index 2. If a future PlateSpec
                    // places its letter slot elsewhere, this must read the active
                    // spec's slot list instead of the literal 2.
                    // FIXME(K5): hard-coded letter-slot index 2.
                    onKey: (letter) =>
                        _bloc.add(ValueIsChanged(index: 2, value: letter)),
                  )
                : VirtualKeypad(
                    highlightedKey: _typist.activeKey,
                    compact: contentDevice == DeviceType.mobile,
                  ),
      ),
    );
  }
}
