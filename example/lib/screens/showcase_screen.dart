import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plate_number/plate_number.dart';

import '../device_preview/device_config.dart';
import '../device_preview/device_frame.dart';
import '../device_preview/device_transition.dart';
import '../poster/poster_tokens.dart';
import '../poster/annotation_callout.dart';
import '../poster/callout_content.dart';
import '../poster/callout_motion.dart';
import '../poster/callout_rail.dart';
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
    final isMobile = _isAndroidMobile(context);

    return Scaffold(
      backgroundColor: PosterTokens.bg,
      body: Stack(
        children: [
          if (!isMobile) const Positioned.fill(child: GridBackdrop()),
          if (!isMobile) const Positioned.fill(child: CornerBrackets()),
          if (isMobile)
            const Center(child: _DeviceStage())
          else
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 56,
                  vertical: 44,
                ),
                child: Column(
                  children: const [
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

  static bool _isAndroidMobile(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;
    return isSmallScreen;
  }
}

/// Below this logical width the three-column poster collapses to a stack.
const double _wideBreakpoint = 1080;

/// The motif pairing for each hop, keyed by the device the hop lands on:
/// how the previous set left, and how this set arrives.
///
/// The cycle is desktop -> mobile -> tablet (see DeviceCycle.order), so:
/// the laptop's callouts sweep out sideways and the mobile's sweep in; the
/// mobile's fall through a trapdoor and the tablet's drop in from one above;
/// the tablet's siphon into their connector dots and the laptop's are emitted
/// back out of them.
const Map<DeviceType, ({CalloutMotif exit, CalloutMotif entry})> calloutMotifs =
    {
      DeviceType.desktop: (
        exit: CalloutMotif.siphon,
        entry: CalloutMotif.siphon,
      ),
      DeviceType.mobile: (exit: CalloutMotif.sweep, entry: CalloutMotif.sweep),
      DeviceType.tablet: (
        exit: CalloutMotif.trapdoor,
        entry: CalloutMotif.trapdoor,
      ),
    };

class _PosterBody extends StatefulWidget {
  const _PosterBody();

  @override
  State<_PosterBody> createState() => _PosterBodyState();
}

class _PosterBodyState extends State<_PosterBody> {
  /// The device the callout rails are showing. Tracks the FRAME device, so it
  /// flips at the start of a hop rather than at the content swap. Seeded to
  /// DeviceCycle.order's first entry.
  DeviceType _railDevice = DeviceType.desktop;

  void _onFrameDeviceChanged(DeviceType device) {
    if (!mounted || _railDevice == device) return;
    setState(() => _railDevice = device);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth >= _wideBreakpoint
        ? _WideBody(
            device: _railDevice,
            onFrameDeviceChanged: _onFrameDeviceChanged,
          )
        : _StackedBody(
            device: _railDevice,
            onFrameDeviceChanged: _onFrameDeviceChanged,
          ),
  );
}

/// Three columns: animated callout rails flanking the device, connectors
/// pointing inward.
class _WideBody extends StatelessWidget {
  const _WideBody({required this.device, required this.onFrameDeviceChanged});

  final DeviceType device;
  final ValueChanged<DeviceType> onFrameDeviceChanged;

  @override
  Widget build(BuildContext context) {
    final motifs = calloutMotifs[device]!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 360,
          child: CalloutRail(
            device: device,
            side: CalloutSide.left,
            exitMotif: motifs.exit,
            entryMotif: motifs.entry,
          ),
        ),
        Expanded(
          child: _DeviceStage(onFrameDeviceChanged: onFrameDeviceChanged),
        ),
        SizedBox(
          width: 360,
          child: CalloutRail(
            device: device,
            side: CalloutSide.right,
            exitMotif: motifs.exit,
            entryMotif: motifs.entry,
          ),
        ),
      ],
    );
  }
}

/// Narrow layout: the device on top, callouts as a connector-less 2x2 grid.
/// No animation on this layout — it just rebuilds from the current set.
class _StackedBody extends StatelessWidget {
  const _StackedBody({
    required this.device,
    required this.onFrameDeviceChanged,
  });

  final DeviceType device;
  final ValueChanged<DeviceType> onFrameDeviceChanged;

  @override
  Widget build(BuildContext context) {
    final set = calloutSets[device]!;
    return Column(
      children: [
        Expanded(
          child: _DeviceStage(onFrameDeviceChanged: onFrameDeviceChanged),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 48,
          runSpacing: 28,
          children: [
            for (final c in [...set.left, ...set.right])
              SizedBox(
                width: 300,
                child: CalloutWithConnector(callout: c, showConnector: false),
              ),
          ],
        ),
      ],
    );
  }
}

class _DeviceStage extends StatefulWidget {
  const _DeviceStage({this.onFrameDeviceChanged});

  /// Fired the instant a hop starts, with the incoming device — i.e. the same
  /// moment [_DeviceStageState._frameDevice] flips, before the plate content
  /// has caught up. The callout rails switch on this, so they leave while the
  /// device is still morphing.
  final ValueChanged<DeviceType>? onFrameDeviceChanged;

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

  /// Drives character entry from the tablet's [VirtualKeypad] into the
  /// attached [PlateCanvas], without either side knowing the active slot's
  /// index.
  final PlateInputController _plateInput = PlateInputController();

  /// A tapped laptop keycap, routed through the attached plate's active slot.
  /// PlateInputController.submit is a no-op when the character isn't in the
  /// slot's alphabet, so the deck's Persian letters land only on letter slots
  /// and its digits only on digit slots — no hard-coded character checks here,
  /// and it keeps working for any plate of any country.
  void _onDeckKey(String label) {
    if (_typist.isRunning) return; // never fight the auto-typist
    if (label == 'BACKSPACE') {
      _plateInput.backspace();
      return;
    }
    _plateInput.submit(label);
  }

  /// Bumped on every device hop; captured by pending awaits so a stale run
  /// (a delayed typist start from a device we already left) bails out.
  int _generation = 0;

  /// The generation a typing run has already been kicked off for, so a repeated
  /// idle phase for the same device doesn't start a second run.
  int _startedGen = -1;

  /// Which plate slot currently holds focus, driving the tablet's letters
  /// pad via its alphabet. Null when focus is off the plate.
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
    _plateInput.dispose();
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
    widget.onFrameDeviceChanged?.call(device);
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
      spec: specFor(device),
      controller: _plateInput,
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
    // The active slot's alphabet, not its position, decides whether the
    // tablet's letters pad shows: a digit-only alphabet keeps the digit grid,
    // anything else slides the letters layer in.
    final activeAlphabet = _activeSlot?.alphabet;
    final showLetters =
        activeAlphabet != null &&
        !activeAlphabet.characters.every((c) => c.isDigit());
    // Cap the frame: the laptop is 1280x830 body plus a ~430px projected deck,
    // so unconstrained it eats the whole middle column and dwarfs the poster.
    // DeviceFrame fits itself to its constraints, so this only scales it down.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 640),
        child: DeviceFrame(
          device: frameDevice,
          onPhaseChanged: _onPhase,
          onContentSwap: _onContentSwap,
          deckPressedKey: _typist.activeKey,
          onDeckKey: _onDeckKey,
          builder: (context, config) => PlateDisplay(
            spec: specFor(contentDevice),
            mode: PlateMode.input,
            // activeColor is the completed-field underline colour; swap it to red
            // for the tablet's German plate when the typed value is invalid (e.g. a
            // forbidden letter combination). Other devices keep the accent.
            activeColor:
                contentDevice == DeviceType.tablet &&
                    _germanValidation?.isValid == false
                ? PosterTokens.invalid
                : PosterTokens.accent,
            bloc: _bloc,
            // The laptop deck already carries letter keys, so its letter comes in
            // through the library's on-screen-keypad mode instead of the modal
            // picker. Other devices keep their platform default.
            letterInputMode:
                contentDevice == DeviceType.desktop ||
                    contentDevice == DeviceType.tablet
                ? LetterInputMode.hostKeypad
                : null,
            onActiveSlotChanged: contentDevice == DeviceType.tablet
                ? _setActiveSlot
                : null,
            controller:
                contentDevice == DeviceType.tablet ||
                    contentDevice == DeviceType.desktop
                ? _plateInput
                : null,
            showBackdrop: true,
            plateWidthFactor: switch (contentDevice) {
              DeviceType.desktop => 0.55,
              DeviceType.tablet => 0.62,
              DeviceType.mobile => 0.86,
            },
            keyboard: contentDevice == DeviceType.desktop
                ? null
                : contentDevice == DeviceType.tablet
                ? VirtualKeypad(
                    highlightedKey: _typist.activeKey,
                    compact: false,
                    showLetters: showLetters,
                    digitAlphabet: PlateAlphabet.latinDigits,
                    letterAlphabet: PlateAlphabet.latinUppercase,
                    activeAlphabet: activeAlphabet,
                    // GermanPlateValidator only exposes a whole-plate
                    // validate() (district + letters + digits in, one
                    // isValid/reason out) — no per-character ban set to
                    // derive individual barred keys from, so there is
                    // nothing to grey out yet. See the doc comment on
                    // _germanValidation.
                    unavailableKeys: const {},
                    onKey: (key) => key == kBackspaceKey
                        ? _plateInput.backspace()
                        : _plateInput.submit(key),
                  )
                : VirtualKeypad(
                    highlightedKey: _typist.activeKey,
                    compact: contentDevice == DeviceType.mobile,
                  ),
          ),
        ),
      ),
    );
  }
}
