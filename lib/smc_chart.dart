import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models.dart';

class SmcChart extends StatelessWidget {
  final List<Candle> candles;
  final Signal? signal;
  final String contract;

  const SmcChart({
    super.key,
    required this.candles,
    required this.signal,
    required this.contract,
  });

  @override
  Widget build(BuildContext context) {
    if (candles.length < 10) {
      return Center(
        child: Text(
          candles.isEmpty
              ? 'Belum ada data candle untuk $contract'
              : 'Menunggu data candle yang cukup...',
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          color: const Color(0xFF0D171C),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  contract,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                '15m • ${candles.length} candles',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: CustomPaint(
            painter: _SmcChartPainter(
              candles: candles,
              signal: signal,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        _legend(),
      ],
    );
  }

  Widget _legend() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      color: const Color(0xFF0D171C),
      child: Wrap(
        spacing: 12,
        runSpacing: 5,
        children: const [
          _LegendItem(
            color: Colors.greenAccent,
            text: 'BUY',
          ),
          _LegendItem(
            color: Colors.redAccent,
            text: 'SELL',
          ),
          _LegendItem(
            color: Colors.orangeAccent,
            text: 'SWEEP',
          ),
          _LegendItem(
            color: Colors.cyanAccent,
            text: 'BOS',
          ),
          _LegendItem(
            color: Colors.purpleAccent,
            text: 'FVG',
          ),
          _LegendItem(
            color: Colors.yellowAccent,
            text: 'OB',
          ),
          _LegendItem(
            color: Colors.blueAccent,
            text: 'EMA200',
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}

class _SmcChartPainter extends CustomPainter {
  final List<Candle> candles;
  final Signal? signal;

  _SmcChartPainter({
    required this.candles,
    required this.signal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    const left = 52.0;
    const right = 12.0;
    const top = 18.0;
    const bottom = 34.0;

    final chartWidth =
        math.max(1.0, size.width - left - right);

    final chartHeight =
        math.max(1.0, size.height - top - bottom);

    // Gunakan candle terbaru agar chart tidak terlalu padat.
    final visibleCount =
        math.min(80, candles.length);

    final data = candles
        .sublist(candles.length - visibleCount)
        .toList();

    final prices = <double>[];

    for (final c in data) {
      prices.add(c.high);
      prices.add(c.low);
    }

    if (signal != null) {
      prices.add(signal!.entry);
      prices.add(signal!.stop);
      prices.add(signal!.tp);
    }

    final maxPrice =
        prices.reduce(math.max);

    final minPrice =
        prices.reduce(math.min);

    final padding =
        math.max((maxPrice - minPrice) * 0.08, 0.000001);

    final high = maxPrice + padding;
    final low = minPrice - padding;

    double xFor(int index) {
      if (data.length <= 1) {
        return left + chartWidth / 2;
      }

      return left +
          (index / (data.length - 1)) *
              chartWidth;
    }

    double yFor(double price) {
      final range = high - low;

      if (range <= 0) {
        return top + chartHeight / 2;
      }

      return top +
          ((high - price) / range) *
              chartHeight;
    }

    // ----------------------------------------------------------
    // BACKGROUND
    // ----------------------------------------------------------

    final backgroundPaint = Paint()
      ..color = const Color(0xFF081014);

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        size.width,
        size.height,
      ),
      backgroundPaint,
    );

    // ----------------------------------------------------------
    // GRID
    // ----------------------------------------------------------

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;

    for (int i = 0; i <= 5; i++) {
      final y =
          top + chartHeight * i / 5;

      canvas.drawLine(
        Offset(left, y),
        Offset(
          size.width - right,
          y,
        ),
        gridPaint,
      );
    }

    for (int i = 0; i <= 6; i++) {
      final x =
          left + chartWidth * i / 6;

      canvas.drawLine(
        Offset(x, top),
        Offset(
          x,
          size.height - bottom,
        ),
        gridPaint,
      );
    }

    // ----------------------------------------------------------
    // PRICE LABELS
    // ----------------------------------------------------------

    final textStyle = const TextStyle(
      color: Colors.white54,
      fontSize: 9,
    );

    for (int i = 0; i <= 5; i++) {
      final price =
          high - (high - low) * i / 5;

      final tp = TextPainter(
        text: TextSpan(
          text: _formatPrice(price),
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        Offset(
          3,
          top + chartHeight * i / 5 - 6,
        ),
      );
    }

    // ----------------------------------------------------------
    // FVG
    // ----------------------------------------------------------

    _drawFvg(
      canvas,
      data,
      xFor,
      yFor,
      visibleCount,
    );

    // ----------------------------------------------------------
    // ORDER BLOCK PROXY
    // ----------------------------------------------------------

    _drawOrderBlocks(
      canvas,
      data,
      xFor,
      yFor,
    );

    // ----------------------------------------------------------
    // CANDLESTICKS
    // ----------------------------------------------------------

    final candleWidth =
        math.max(
          2.0,
          math.min(
            10.0,
            chartWidth /
                data.length *
                0.65,
          ),
        );

    for (int i = 0; i < data.length; i++) {
      final c = data[i];

      final x = xFor(i);

      final isBull =
          c.close >= c.open;

      final color = isBull
          ? Colors.greenAccent
          : Colors.redAccent;

      final wickPaint = Paint()
        ..color = color
        ..strokeWidth = 1;

      canvas.drawLine(
        Offset(x, yFor(c.high)),
        Offset(x, yFor(c.low)),
        wickPaint,
      );

      final bodyTop =
          yFor(math.max(c.open, c.close));

      final bodyBottom =
          yFor(math.min(c.open, c.close));

      final bodyHeight =
          math.max(1.5, bodyBottom - bodyTop);

      final bodyPaint = Paint()
        ..color = color;

      canvas.drawRect(
        Rect.fromLTWH(
          x - candleWidth / 2,
          bodyTop,
          candleWidth,
          bodyHeight,
        ),
        bodyPaint,
      );
    }

    // ----------------------------------------------------------
    // EMA 200
    // ----------------------------------------------------------

    final ema = _calculateEma(
      candles,
      200,
    );

    final emaStart =
        math.max(
          0,
          ema.length - data.length,
        );

    final emaVisible =
        ema.sublist(emaStart);

    if (emaVisible.length > 1) {
      final emaPaint = Paint()
        ..color = Colors.blueAccent
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final path = Path();

      for (int i = 0;
          i < emaVisible.length;
          i++) {
        final x = xFor(
          i +
              data.length -
                  emaVisible.length,
        );

        final y = yFor(
          emaVisible[i],
        );

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(
        path,
        emaPaint,
      );
    }

    // ----------------------------------------------------------
    // SMC EVENTS
    // ----------------------------------------------------------

    _drawSmcEvents(
      canvas,
      data,
      xFor,
      yFor,
    );

    // ----------------------------------------------------------
    // SIGNAL ENTRY / SL / TP
    // ----------------------------------------------------------

    if (signal != null) {
      _drawSignalLevels(
        canvas,
        size,
        yFor,
        signal!,
      );
    }

    // ----------------------------------------------------------
    // CURRENT PRICE
    // ----------------------------------------------------------

    final last =
        data.last.close;

    final currentY =
        yFor(last);

    final currentPaint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(left, currentY),
      Offset(
        size.width - right,
        currentY,
      ),
      currentPaint,
    );

    final currentText =
        TextPainter(
      text: TextSpan(
        text: _formatPrice(last),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    currentText.paint(
      canvas,
      Offset(
        size.width - right - currentText.width,
        currentY - 14,
      ),
    );
  }

  // ============================================================
  // FVG
  // ============================================================

  void _drawFvg(
    Canvas canvas,
    List<Candle> data,
    double Function(int) xFor,
    double Function(double) yFor,
    int visibleCount,
  ) {
    if (data.length < 3) {
      return;
    }

    for (int i = 2; i < data.length; i++) {
      final a = data[i - 2];
      final c = data[i];

      // Bullish FVG:
      // high candle A < low candle C
      if (a.high < c.low) {
        final topPrice = c.low;
        final bottomPrice = a.high;

        final rect = Rect.fromLTRB(
          xFor(i - 2),
          yFor(topPrice),
          xFor(i),
          yFor(bottomPrice),
        );

        final paint = Paint()
          ..color =
              Colors.purpleAccent.withValues(alpha: 0.15)
          ..style = PaintingStyle.fill;

        canvas.drawRect(rect, paint);

        final border = Paint()
          ..color =
              Colors.purpleAccent.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

        canvas.drawRect(rect, border);
      }

      // Bearish FVG:
      // low candle A > high candle C
      if (a.low > c.high) {
        final topPrice = a.low;
        final bottomPrice = c.high;

        final rect = Rect.fromLTRB(
          xFor(i - 2),
          yFor(topPrice),
          xFor(i),
          yFor(bottomPrice),
        );

        final paint = Paint()
          ..color =
              Colors.deepPurpleAccent.withValues(alpha: 0.15)
          ..style = PaintingStyle.fill;

        canvas.drawRect(rect, paint);

        final border = Paint()
          ..color =
              Colors.deepPurpleAccent.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

        canvas.drawRect(rect, border);
      }
    }
  }

  // ============================================================
  // ORDER BLOCK PROXY
  // ============================================================

  void _drawOrderBlocks(
    Canvas canvas,
    List<Candle> data,
    double Function(int) xFor,
    double Function(double) yFor,
  ) {
    if (data.length < 8) {
      return;
    }

    for (int i = 3; i < data.length; i++) {
      final previous = data[i - 1];
      final current = data[i];

      final previousRange =
          previous.high - previous.low;

      final currentRange =
          current.high - current.low;

      if (previousRange <= 0 ||
          currentRange <= 0) {
        continue;
      }

      final bullishImpulse =
          current.close > previous.high &&
          current.close > current.open &&
          currentRange >
              previousRange * 1.25;

      final bearishImpulse =
          current.close < previous.low &&
          current.close < current.open &&
          currentRange >
              previousRange * 1.25;

      if (bullishImpulse &&
          previous.close < previous.open) {
        _drawZone(
          canvas,
          xFor(i - 1),
          xFor(data.length - 1),
          yFor(previous.high),
          yFor(previous.low),
          Colors.yellowAccent,
        );
      }

      if (bearishImpulse &&
          previous.close > previous.open) {
        _drawZone(
          canvas,
          xFor(i - 1),
          xFor(data.length - 1),
          yFor(previous.high),
          yFor(previous.low),
          Colors.orangeAccent,
        );
      }
    }
  }

  void _drawZone(
    Canvas canvas,
    double x1,
    double x2,
    double y1,
    double y2,
    Color color,
  ) {
    final top =
        math.min(y1, y2);

    final bottom =
        math.max(y1, y2);

    final rect = Rect.fromLTRB(
      x1,
      top,
      x2,
      bottom,
    );

    final fill = Paint()
      ..color = color.withValues(alpha: 0.08);

    canvas.drawRect(
      rect,
      fill,
    );

    final border = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRect(
      rect,
      border,
    );
  }

  // ============================================================
  // BOS / LIQUIDITY SWEEP
  // ============================================================

  void _drawSmcEvents(
    Canvas canvas,
    List<Candle> data,
    double Function(int) xFor,
    double Function(double) yFor,
  ) {
    if (data.length < 8) {
      return;
    }

    for (int i = 5; i < data.length; i++) {
      final current = data[i];

      double previousHigh = data[i - 5].high;
      double previousLow = data[i - 5].low;

      for (int j = i - 5; j < i; j++) {
        previousHigh =
            math.max(previousHigh, data[j].high);

        previousLow =
            math.min(previousLow, data[j].low);
      }

      final bullishBos =
          current.close > previousHigh;

      final bearishBos =
          current.close < previousLow;

      final bullishSweep =
          current.low < previousLow &&
          current.close > previousLow;

      final bearishSweep =
          current.high > previousHigh &&
          current.close < previousHigh;

      if (bullishBos) {
        _label(
          canvas,
          'BOS ↑',
          xFor(i),
          yFor(current.high) - 18,
          Colors.cyanAccent,
        );
      }

      if (bearishBos) {
        _label(
          canvas,
          'BOS ↓',
          xFor(i),
          yFor(current.low) + 8,
          Colors.cyanAccent,
        );
      }

      if (bullishSweep) {
        _label(
          canvas,
          'SWEEP',
          xFor(i),
          yFor(current.low) + 8,
          Colors.orangeAccent,
        );
      }

      if (bearishSweep) {
        _label(
          canvas,
          'SWEEP',
          xFor(i),
          yFor(current.high) - 18,
          Colors.orangeAccent,
        );
      }
    }
  }

  // ============================================================
  // SIGNAL LEVELS
  // ============================================================

  void _drawSignalLevels(
    Canvas canvas,
    Size size,
    double Function(double) yFor,
    Signal signal,
  ) {
    final isBuy =
        signal.side.toUpperCase() == 'BUY';

    final entryColor =
        isBuy ? Colors.greenAccent : Colors.redAccent;

    _level(
      canvas,
      size,
      yFor(signal.entry),
      entryColor,
      '${signal.side} ENTRY ${_formatPrice(signal.entry)}',
    );

    _level(
      canvas,
      size,
      yFor(signal.stop),
      Colors.redAccent,
      'SL ${_formatPrice(signal.stop)}',
    );

    _level(
      canvas,
      size,
      yFor(signal.tp),
      Colors.greenAccent,
      'TP ${_formatPrice(signal.tp)}',
    );
  }

  void _level(
    Canvas canvas,
    Size size,
    double y,
    Color color,
    String text,
  ) {
    if (y < 12 || y > size.height - 25) {
      return;
    }

    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 1.2;

    canvas.drawLine(
      const Offset(48, 0),
      Offset(
        size.width - 8,
        y,
      ),
      paint,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(
        54,
        y - 13,
      ),
    );
  }

  // ============================================================
  // TEXT LABEL
  // ============================================================

  void _label(
    Canvas canvas,
    String text,
    double x,
    double y,
    Color color,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final drawX =
        math.max(48.0, x - tp.width / 2);

    final drawY =
        math.max(4.0, y);

    tp.paint(
      canvas,
      Offset(drawX, drawY),
    );
  }

  // ============================================================
  // EMA
  // ============================================================

  List<double> _calculateEma(
    List<Candle> source,
    int period,
  ) {
    if (source.isEmpty) {
      return [];
    }

    final result = <double>[];

    final alpha =
        2.0 / (period + 1);

    double previous =
        source.first.close;

    result.add(previous);

    for (int i = 1;
        i < source.length;
        i++) {
      previous =
          (source[i].close - previous) *
                  alpha +
              previous;

      result.add(previous);
    }

    return result;
  }

  String _formatPrice(double value) {
    if (value >= 1000) {
      return value.toStringAsFixed(2);
    }

    if (value >= 1) {
      return value.toStringAsFixed(4);
    }

    return value.toStringAsFixed(6);
  }

  @override
  bool shouldRepaint(
    covariant _SmcChartPainter oldDelegate,
  ) {
    return oldDelegate.candles != candles ||
        oldDelegate.signal != signal;
  }
}
