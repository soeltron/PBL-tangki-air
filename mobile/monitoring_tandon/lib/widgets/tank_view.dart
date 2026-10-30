import 'dart:math';
import 'package:flutter/material.dart';

class TankView extends StatefulWidget {
  final double waterLevel; // 0.0 to 100.0
  final double capacityLiters;
  final bool isPumpOn;

  const TankView({
    super.key,
    required this.waterLevel,
    required this.capacityLiters,
    required this.isPumpOn,
  });

  @override
  State<TankView> createState() => _TankViewState();
}

class _TankViewState extends State<TankView>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentVolume = (widget.waterLevel / 100.0) * widget.capacityLiters;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer Glass Tank Vessel with Ocean Blue Theme
            Container(
              width: 190,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.5),
                  width: 2.5,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFE0F2FE).withValues(alpha: 0.85),
                    const Color(0xFFF1F5F9).withValues(alpha: 0.95),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _WaterTankPainter(
                        waterLevel: widget.waterLevel,
                        waveValue: _waveController.value,
                        isPumpOn: widget.isPumpOn,
                      ),
                      child: Container(),
                    );
                  },
                ),
              ),
            ),

            // Left Side Capacity Scale Lines
            Positioned(
              left: 14,
              top: 22,
              bottom: 22,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _scaleText('100%'),
                  _scaleText('75%'),
                  _scaleText('50%'),
                  _scaleText('25%'),
                  _scaleText('0%'),
                ],
              ),
            ),

            // Center Floating Level Card
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${widget.waterLevel.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Color(0xFF0284C7),
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${currentVolume.toStringAsFixed(0)} / ${widget.capacityLiters.toStringAsFixed(0)} L',
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isPumpOn) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF0284C7),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Mengisi Tandon...',
                          style: TextStyle(
                            color: Color(0xFF0284C7),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _scaleText(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _WaterTankPainter extends CustomPainter {
  final double waterLevel;
  final double waveValue;
  final bool isPumpOn;

  _WaterTankPainter({
    required this.waterLevel,
    required this.waveValue,
    required this.isPumpOn,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double height = size.height;
    final double width = size.width;

    final double fillPercentage = (waterLevel.clamp(0.0, 100.0)) / 100.0;
    final double waterHeight = height * fillPercentage;
    final double baseLevel = height - waterHeight;

    // Ocean Blue Water Gradient
    final waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF38BDF8).withValues(alpha: 0.9),
          const Color(0xFF0284C7).withValues(alpha: 0.95),
          const Color(0xFF0369A1),
        ],
      ).createShader(Rect.fromLTWH(0, baseLevel, width, waterHeight));

    // Secondary Wave
    final backWavePaint = Paint()
      ..color = const Color(0xFF7DD3FC).withValues(alpha: 0.5);

    final Path backPath = Path();
    backPath.moveTo(0, height);
    for (double x = 0; x <= width; x += 1) {
      final double y = baseLevel +
          sin((x / width * 2 * pi) + (waveValue * 2 * pi) + pi) * 6;
      backPath.lineTo(x, y);
    }
    backPath.lineTo(width, height);
    backPath.close();
    canvas.drawPath(backPath, backWavePaint);

    final Path frontPath = Path();
    frontPath.moveTo(0, height);
    for (double x = 0; x <= width; x += 1) {
      final double y = baseLevel +
          sin((x / width * 2 * pi) - (waveValue * 2 * pi)) * 7;
      frontPath.lineTo(x, y);
    }
    frontPath.lineTo(width, height);
    frontPath.close();
    canvas.drawPath(frontPath, waterPaint);

    final surfacePaint = Paint()
      ..color = const Color(0xFFE0F2FE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(frontPath, surfacePaint);

    if (isPumpOn && fillPercentage < 0.98) {
      final dropPaint = Paint()..color = const Color(0xFF0284C7);
      for (int i = 0; i < 5; i++) {
        final double dropX = (width / 2) + (i * 12 - 24);
        final double dropY = ((waveValue * 3 + i * 0.2) % 1.0) * baseLevel;
        if (dropY < baseLevel) {
          canvas.drawCircle(Offset(dropX, dropY), 3.5, dropPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WaterTankPainter oldDelegate) {
    return oldDelegate.waterLevel != waterLevel ||
        oldDelegate.waveValue != waveValue ||
        oldDelegate.isPumpOn != isPumpOn;
  }
}
