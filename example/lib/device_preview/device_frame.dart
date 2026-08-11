 import 'dart:math' as math;
 import 'package:flutter/material.dart';
 

 enum DevicePreset {
   smallPhone('Small Phone', 360, 640, 24, true),
   largePhone('Large Phone', 414, 896, 28, true),
   tablet('Tablet', 768, 1024, 20, false),
   desktop('Desktop', 1280, 800, 8, false),
   custom('Custom', 0, 0, 12, false);
 
   const DevicePreset(
     this.label,
     this.defaultWidth,
     this.defaultHeight,
     this.cornerRadius,
     this.hasNotch,
   );
 
   final String label;
   final double defaultWidth;
   final double defaultHeight;
   final double cornerRadius;
   final bool hasNotch;
 }
 
 class DeviceFrame extends StatefulWidget {
   const DeviceFrame({
     super.key,
     required this.child,
    required this.device,
    this.customWidth,
    this.customHeight,
    this.scale = 1.0,
  });

  final Widget child;
  final DevicePreset device;
  final double? customWidth;
  final double? customHeight;
   final double scale;
 
   @override
   State<DeviceFrame> createState() => _DeviceFrameState();
 }
 
 class _DeviceFrameState extends State<DeviceFrame>
     with SingleTickerProviderStateMixin {
   late AnimationController _controller;
 
   // Source values (the device we are transitioning *from*).
   late DevicePreset _fromDevice;
   late double _fromWidth;
   late double _fromHeight;
 
   // Target values (the device we are transitioning *to*).
   // These are always kept in sync with the widget fields.
   late DevicePreset _toDevice;
   late double _toWidth;
   late double _toHeight;
 
   @override
   void initState() {
     super.initState();
     _toDevice = widget.device;
     final targetSize = _effectiveSize(widget.device);
     _toWidth = targetSize.$1;
     _toHeight = targetSize.$2;
     _fromDevice = _toDevice;
     _fromWidth = _toWidth;
     _fromHeight = _toHeight;
 
     _controller = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 1500),
     );
     _controller.addListener(() => setState(() {}));
     _controller.addStatusListener(_onControllerStatus);
   }
 
   void _onControllerStatus(AnimationStatus status) {
     if (status == AnimationStatus.completed) {
       // The transition is finished — make the "from" equal the "to".
       _fromDevice = _toDevice;
       _fromWidth = _toWidth;
       _fromHeight = _toHeight;
       _controller.value = 0;
     }
   }
 
   @override
   void didUpdateWidget(DeviceFrame oldWidget) {
     super.didUpdateWidget(oldWidget);
     final (newW, newH) = _effectiveSize(widget.device);
 
     if (widget.device != oldWidget.device ||
         widget.customWidth != oldWidget.customWidth ||
         widget.customHeight != oldWidget.customHeight) {
       // Snapshot the *currently displayed* device as the "from".
       if (_controller.isAnimating || _controller.isCompleted) {
         _fromDevice = _toDevice;
         _fromWidth = _toWidth;
         _fromHeight = _toHeight;
       }
       _toDevice = widget.device;
       _toWidth = newW;
       _toHeight = newH;
       _controller.forward(from: 0);
     }
   }
 
   @override
   void dispose() {
     _controller.dispose();
     super.dispose();
   }
 
   // ---- helpers -----------------------------------------------------------
 
   (double, double) _effectiveSize(DevicePreset preset) {
     if (preset == DevicePreset.custom) {
       return (widget.customWidth ?? 360, widget.customHeight ?? 640);
     }
     return (preset.defaultWidth, preset.defaultHeight);
   }
 
   /// Compute the current frame dimensions by interpolating between
   /// [_fromWidth/_fromHeight] and [_toWidth/_toHeight].
   double _lerpFrameDimension(double fromVal, double toVal) {
     final t = _controller.value;
     if (t <= 0.25) return fromVal;
     if (t >= 0.75) return toVal;
     final p = Curves.easeInOut.transform((t - 0.25) / 0.5);
     return fromVal + (toVal - fromVal) * p;
   }
 
   /// The opacity of the inner screen content.
   ///
   /// 0.00 … 0.25 : 1 → 0   (fade-out)
   /// 0.25 … 0.75 : 0       (blank while resizing)
   /// 0.75 … 1.00 : 0 → 1   (fade-in)
   double get _contentOpacity {
     final t = _controller.value;
     if (t < 0.25) return 1.0 - (t / 0.25);
     if (t > 0.75) return (t - 0.75) / 0.25;
     return 0.0;
   }
 
   /// Which device preset the *frame* should visually represent.
   /// During resize we keep the *from* shape; after resize we show the *to*.
   DevicePreset get _framePreset {
     return _controller.value >= 0.75 ? _toDevice : _fromDevice;
   }
 
   /// Which device's content dimensions to use inside the frame.
   bool get _useNewContent => _controller.value > 0.75;
 
   // ---- build -------------------------------------------------------------
 
   @override
   Widget build(BuildContext context) {
     final scale = widget.scale;
 
     final frameW = _lerpFrameDimension(_fromWidth, _toWidth) * scale;
     final frameH = _lerpFrameDimension(_fromHeight, _toHeight) * scale;
 
     final contentW = _useNewContent ? _toWidth : _fromWidth;
     final contentH = _useNewContent ? _toHeight : _fromHeight;
     final contentDevice = _useNewContent ? _toDevice : _fromDevice;
 
     return Center(
       child: _DeviceFrameWidget(
         width: frameW,
         height: frameH,
         device: _framePreset,
         child: Opacity(
           opacity: _contentOpacity,
           child: Stack(
           children: [
             SizedBox(
               width: contentW,
               height: contentH,
               child: FittedBox(
                 fit: BoxFit.contain,
                 child: SizedBox(
                   width: contentW,
                   height: contentH,
                   child: MediaQuery(
                     data: MediaQuery.of(context).copyWith(
                       size: Size(contentW, contentH),
                     ),
                     child: widget.child,
                   ),
                 ),
               ),
             ),
             if (contentDevice != DevicePreset.desktop)
               Positioned(
                 top: 0,
                 left: 0,
                 right: 0,
                 child: _ScreenTopDecorations(device: contentDevice),
               ),
             ],
           ),
         ),
       ),
     );
   }
 }
 
 // =========================================================================
 // Device-frame shell
 // =========================================================================
 
 class _DeviceFrameWidget extends StatelessWidget {
   const _DeviceFrameWidget({
     required this.width,
     required this.height,
     required this.device,
     required this.child,
   });
 
   final double width;
   final double height;
   final DevicePreset device;
   final Widget child;
 
   static double _bezel(DevicePreset d) {
     switch (d) {
       case DevicePreset.smallPhone:
         return 7;
       case DevicePreset.largePhone:
         return 9;
       case DevicePreset.tablet:
         return 11;
       case DevicePreset.desktop:
         return 5;
       case DevicePreset.custom:
         return 8;
     }
   }
 
   static double _outerRadius(DevicePreset d) => d.cornerRadius + _bezel(d);
 
   @override
   Widget build(BuildContext context) {
     final bezel = _bezel(device);
     final outerR = _outerRadius(device);
     final hasDesktopStand = device == DevicePreset.desktop;
 
     // Desktop gets extra bottom padding for the stand.
     final bottomPad = hasDesktopStand ? bezel + 28 : bezel;
 
   return Container(
     width: width,
     height: height,
     decoration: BoxDecoration(
       color: const Color(0xFFC0C0C0),
       borderRadius: BorderRadius.circular(outerR),
         boxShadow: [
           BoxShadow(
             color: Colors.black.withValues(alpha: 0.25),
             blurRadius: 24,
             offset: const Offset(0, 10),
           ),
         ],
       ),
       child: Stack(
         clipBehavior: Clip.none,
         children: [
           // ---- screen area -----------------------------------------------
           Positioned(
             left: bezel,
             top: bezel,
             right: bezel,
             bottom: bottomPad,
             child: ClipPath(
               clipper: _ScreenClipper(
                 device: device,
                 width: width - bezel * 2,
                 height: height - bezel - bottomPad,
               ),
               child: child,
             ),
           ),
 
           // ---- top bezel shine ------------------------------------------
           Positioned(
             left: 0,
             top: 0,
             right: 0,
             child: IgnorePointer(
               child: Container(
                 height: bezel,
                 decoration: BoxDecoration(
                   borderRadius: BorderRadius.vertical(
                     top: Radius.circular(outerR),
                   ),
                 gradient: const LinearGradient(
                   begin: Alignment.topCenter,
                   end: Alignment.bottomCenter,
                   colors: [Color(0xFFD8D8D8), Color(0xFFB0B0B0)],
                 ),
                 ),
               ),
             ),
         ),
 
         // ---- desktop stand --------------------------------------------
           if (hasDesktopStand)
             Positioned(
               bottom: -18,
               left: 0,
               right: 0,
               child: IgnorePointer(
                 child: CustomPaint(
                   size: Size(width, 28),
                   painter: _StandPainter(
                     frameWidth: width,
                     bezel: bezel,
                     outerRadius: outerR,
                   ),
                 ),
               ),
             ),
         ],
       ),
     );
   }
 }
 
 // =========================================================================
 // Screen clipper — clips the screen rectangle with device-specific shape
 // =========================================================================
 
 class _ScreenClipper extends CustomClipper<Path> {
   const _ScreenClipper({
     required this.device,
     required this.width,
     required this.height,
   });
 
   final DevicePreset device;
   final double width;
   final double height;
 
   @override
   Path getClip(Size size) {
     final r = device.cornerRadius;
     final path = Path();
 
     if (device.hasNotch) {
       _addPhoneScreen(path, r);
     } else {
       // Simple rounded rectangle.
       path.addRRect(
         RRect.fromRectAndRadius(
           Rect.fromLTWH(0, 0, width, height),
           Radius.circular(r),
         ),
       );
     }
 
     return path;
   }
 
   void _addPhoneScreen(Path path, double r) {
     // A rounded rectangle with a Dynamic-Island-style pill at the top
     // centre.  We draw left-to-right along the top edge, dipping down
     // around the notch, then continue down the right / bottom / left.
 
     final notchW = math.min(width * 0.28, 120.0);
     final notchH = 10.0;
     final notchX = (width - notchW) / 2;
     final notchRX = 18.0;
 
     // Start: top-left corner
     path.moveTo(r, 0);
 
     // Top edge → notch-left
     path.lineTo(notchX - notchRX, 0);
 
     // Notch left curve (entering the dip)
     path.arcToPoint(
       Offset(notchX, notchH),
       radius: const Radius.circular(14),
       clockwise: false,
     );
 
     // Notch bottom edge
     path.lineTo(notchX + notchW, notchH);
 
     // Notch right curve (exiting the dip)
     path.arcToPoint(
       Offset(notchX + notchW + notchRX, 0),
       radius: const Radius.circular(14),
       clockwise: false,
     );
 
     // Top edge → top-right corner
     path.lineTo(width - r, 0);
     path.arcToPoint(
       Offset(width, r),
       radius: Radius.circular(r),
       clockwise: true,
     );
 
     // Right edge
     path.lineTo(width, height - r);
     path.arcToPoint(
       Offset(width - r, height),
       radius: Radius.circular(r),
       clockwise: true,
     );
 
     // Bottom edge
     path.lineTo(r, height);
     path.arcToPoint(
       Offset(0, height - r),
       radius: Radius.circular(r),
       clockwise: true,
     );
 
     // Left edge → close
     path.arcToPoint(
       Offset(r, 0),
       radius: Radius.circular(r),
       clockwise: true,
     );
     path.close();
   }
 
   @override
   bool shouldReclip(covariant _ScreenClipper oldClipper) {
     return device != oldClipper.device ||
         width != oldClipper.width ||
         height != oldClipper.height;
   }
}
 
 // =========================================================================
 // Screen-top decorations — camera dot & speaker grille that fade with content
 // =========================================================================
 
 class _ScreenTopDecorations extends StatelessWidget {
   const _ScreenTopDecorations({required this.device});
 
   final DevicePreset device;
 
   @override
   Widget build(BuildContext context) {
     final isTablet = device == DevicePreset.tablet;
     final hasSpeaker = device.hasNotch && device != DevicePreset.custom;
 
     return SizedBox(
       height: 18,
       child: Stack(
         children: [
           // Camera dot
           Center(
             child: Container(
               margin: const EdgeInsets.only(top: 4),
               width: isTablet ? 7 : 6,
               height: isTablet ? 7 : 6,
               decoration: BoxDecoration(
                 color: const Color(0xFF444444),
                 shape: BoxShape.circle,
                 border: Border.all(
                   color: const Color(0xFF222222),
                   width: 0.5,
                 ),
               ),
             ),
           ),
           // Speaker grille
           if (hasSpeaker)
             Center(
               child: Container(
                 margin: const EdgeInsets.only(top: 13),
                 width: 40,
                 height: 3,
                 decoration: BoxDecoration(
                   color: const Color(0xFF333333),
                   borderRadius: BorderRadius.circular(2),
                 ),
               ),
             ),
         ],
       ),
     );
   }
 }
 
 // =========================================================================
 // Desktop stand painter
 // =========================================================================
 
 class _StandPainter extends CustomPainter {
   const _StandPainter({
     required this.frameWidth,
     required this.bezel,
     required this.outerRadius,
   });
 
   final double frameWidth;
   final double bezel;
   final double outerRadius;
 
   @override
   void paint(Canvas canvas, Size size) {
   final paint = Paint()
     ..color = const Color(0xFFC0C0C0)
     ..style = PaintingStyle.fill;
 
     final standW = frameWidth * 0.22;
     final standLeft = (frameWidth - standW) / 2;
     final standTop = bezel * 0.5;
 
     // Neck
     final neckW = standW * 0.35;
     final neckLeft = (frameWidth - neckW) / 2;
     final neckPath = Path()
       ..moveTo(neckLeft, standTop)
       ..lineTo(neckLeft + neckW, standTop)
       ..lineTo(standLeft + standW, size.height)
       ..lineTo(standLeft, size.height)
       ..close();
     canvas.drawPath(neckPath, paint);
 
     // Base
     final baseW = standW * 1.5;
     final baseLeft = (frameWidth - baseW) / 2;
     final baseRRect = RRect.fromRectAndRadius(
       Rect.fromLTWH(baseLeft, size.height - 6, baseW, 6),
       const Radius.circular(3),
     );
     canvas.drawRRect(baseRRect, paint);
   }
 
   @override
   bool shouldRepaint(covariant _StandPainter oldDelegate) {
     return frameWidth != oldDelegate.frameWidth ||
         bezel != oldDelegate.bezel ||
         outerRadius != oldDelegate.outerRadius;
   }
 }
 
