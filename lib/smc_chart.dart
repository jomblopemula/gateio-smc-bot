import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models.dart';

class SmcChart extends StatefulWidget {
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
  State<SmcChart> createState() => _SmcChartState();
}

class _SmcChartState extends State<SmcChart> {
  final TransformationController _controller =
      TransformationController();

  String _timeframe = '15m';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _controller.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.candles.length < 10) {
      return Center(
        child: Text(
          widget.candles.isEmpty
              ? 'Belum ada data candle untuk ${widget.contract}'
              : 'Menunggu data candle yang cukup...',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      );
    }

    final signal = widget.signal;
    final side = signal?.side.toUpperCase() ?? 'NO SIGNAL';

    final isBuy = side == 'BUY';
    final isSell = side == 'SELL';

    final statusColor = isBuy
        ? Colors.greenAccent
        : isSell
            ? Colors.redAccent
            : Colors.white70;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF071014),
        borderRadius: BorderRadius.all(
          Radius.circular(12),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(
          Radius.circular(12),
        ),
        child: Column(
          children: [
            _buildHeader(
              signal,
              side,
              statusColor,
            ),
            _buildTimeframeBar(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final chartWidth =
                      math.max(
                    920.0,
                    constraints.maxWidth - 8.0,
                  );

                  final chartHeight =
                      math.max(
                    260.0,
                    constraints.maxHeight,
                  );

                  return Stack(
                    children: [
                      InteractiveViewer(
                        transformationController:
                            _controller,
                        constrained: false,
                        panEnabled: true,
                        scaleEnabled: true,
                        minScale: 1.0,
                        maxScale: 4.0,
                        boundaryMargin:
                            const EdgeInsets.all(180),
                        child: SizedBox(
                          width: chartWidth,
                          height: chartHeight,
                          child: CustomPaint(
                            painter: _SmcChartPainter(
                              candles: widget.candles,
                              signal: signal,
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        top: 10,
                        right: 10,
                        child: Material(
                          color:
                              const Color(0xCC10181D),
                          borderRadius:
                              BorderRadius.circular(8),
                          child: IconButton(
                            tooltip: 'Reset zoom',
                            onPressed: _resetZoom,
                            icon: const Icon(
                              Icons.fit_screen,
                              size: 18,
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: _buildStatusBadge(
                          side,
                          statusColor,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    Signal? signal,
    String side,
    Color statusColor,
  ) {
    final last = widget.candles.last.close;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        12,
        9,
        12,
        9,
      ),
      color: const Color(0xFF0D171C),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contract,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'LIVE • ${_formatPrice(last)} • $_timeframe',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(7),
              border: Border.all(
                color: statusColor.withValues(
                  alpha: 0.45,
                ),
              ),
            ),
            child: Text(
              side,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          if (signal != null) ...[
            const SizedBox(width: 8),
            Text(
              '${signal.score}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
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

  Widget _buildTimeframeBar() {
    const values = [
      '1m',
      '5m',
      '15m',
      '30m',
      '1h',
      '4h',
      '1D',
    ];

    return Container(
      height: 40,
      color: const Color(0xFF0A1318),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 5),
        itemBuilder: (_, index) {
          final value = values[index];
          final selected =
              value == _timeframe;

          return ChoiceChip(
            label: Text(value),
            selected: selected,
            visualDensity:
                VisualDensity.compact,
            labelStyle: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : Colors.white60,
            ),
            onSelected: (_) {
              setState(() {
                _timeframe = value;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(
    String side,
    Color color,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE610181D),
        borderRadius:
            BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(
            alpha: 0.45,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 6,
        ),
        child: Text(
          side == 'NO SIGNAL'
              ? 'SMC • Menunggu konfirmasi'
              : 'SMC • $side',
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      color: const Color(0xFF0D171C),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: const [
            _LegendItem(
              color: Colors.greenAccent,
              text: 'BUY',
            ),
            SizedBox(width: 12),
            _LegendItem(
              color: Colors.redAccent,
              text: 'SELL',
            ),
            SizedBox(width: 12),
            _LegendItem(
              color: Colors.orangeAccent,
              text: 'SWEEP',
            ),
            SizedBox(width: 12),
            _LegendItem(
              color: Colors.cyanAccent,
              text: 'BOS',
            ),
            SizedBox(width: 12),
            _LegendItem(
              color: Colors.purpleAccent,
              text: 'FVG',
            ),
            SizedBox(width: 12),
            _LegendItem(
              color: Colors.yellowAccent,
              text: 'OB',
            ),
            SizedBox(width: 12),
            _LegendItem(
              color: Colors.blueAccent,
              text: 'EMA200',
            ),
          ],
        ),
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
          style: const TextStyle(
            fontSize: 10,
          ),
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
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (candles.isEmpty ||
        size.width <= 0 ||
        size.height <= 0) {
      return;
    }

    const left = 58.0;
    const right = 14.0;
    const top = 18.0;
    const bottom = 34.0;

    final chartWidth =
        math.max(
      1.0,
      size.width - left - right,
    );

    final chartHeight =
        math.max(
      1.0,
      size.height - top - bottom,
    );

    final visibleCount =
        math.min(100, candles.length);

    final data = candles.sublist(
      candles.length - visibleCount,
    );

    final prices = <double>[];

    for (final candle in data) {
      prices
        ..add(candle.high)
        ..add(candle.low);
    }

    if (signal != null) {
      prices
        ..add(signal!.entry)
        ..add(signal!.stop)
        ..add(signal!.tp);
    }

    final maxPrice =
        prices.reduce(math.max);

    final minPrice =
        prices.reduce(math.min);

    final padding = math.max(
      (maxPrice - minPrice) * 0.08,
      0.000001,
    );

    final high =
        maxPrice + padding;

    final low =
        minPrice - padding;

    double xFor(int index) {
      if (data.length <= 1) {
        return left +
            chartWidth / 2;
      }

      return left +
          index /
              (data.length - 1) *
              chartWidth;
    }

    double yFor(double price) {
      final range =
          high - low;

      if (range <= 0) {
        return top +
            chartHeight / 2;
      }

      return top +
          (high - price) /
              range *
              chartHeight;
    }

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color =
            const Color(0xFF081014),
    );

    final gridPaint = Paint()
      ..color = Colors.white.withValues(
        alpha: 0.055,
      )
      ..strokeWidth = 1;

    for (int i = 0; i <= 5; i++) {
      final y =
          top +
              chartHeight *
                  i /
                  5;

      canvas.drawLine(
        Offset(left, y),
        Offset(
          size.width - right,
          y,
        ),
        gridPaint,
      );
    }

    for (int i = 0; i <= 8; i++) {
      final x =
          left +
              chartWidth *
                  i /
                  8;

      canvas.drawLine(
        Offset(x, top),
        Offset(
          x,
          size.height - bottom,
        ),
        gridPaint,
      );
    }

    const textStyle = TextStyle(
      color: Colors.white54,
      fontSize: 9,
    );

    for (int i = 0; i <= 5; i++) {
      final price =
          high -
              (high - low) *
                  i /
                  5;

      final painter = TextPainter(
        text: TextSpan(
          text: _formatPrice(price),
          style: textStyle,
        ),
        textDirection:
            TextDirection.ltr,
      )..layout();

      painter.paint(
        canvas,
        Offset(
          3,
          top +
              chartHeight *
                  i /
                  5 -
              6,
        ),
      );
    }

    _drawFvg(
      canvas,
      data,
      xFor,
      yFor,
    );

    _drawOrderBlocks(
      canvas,
      data,
      xFor,
      yFor,
    );

    final candleWidth =
        math.max(
      2.0,
      math.min(
        11.0,
        chartWidth /
                data.length *
                0.72,
      ),
    );

    for (int i = 0;
        i < data.length;
        i++) {
      final candle =
          data[i];

      final x =
          xFor(i);

      final candleColor =
          candle.close >= candle.open
              ? Colors.greenAccent
              : Colors.redAccent;

      canvas.drawLine(
        Offset(
          x,
          yFor(candle.high),
        ),
        Offset(
          x,
          yFor(candle.low),
        ),
        Paint()
          ..color =
              candleColor
          ..strokeWidth = 1,
      );

      final bodyTop =
          yFor(
        math.max(
          candle.open,
          candle.close,
        ),
      );

      final bodyBottom =
          yFor(
        math.min(
          candle.open,
          candle.close,
        ),
      );

      canvas.drawRect(
        Rect.fromLTWH(
          x -
              candleWidth /
                  2,
          bodyTop,
          candleWidth,
          math.max(
            1.5,
            bodyBottom -
                bodyTop,
          ),
        ),
        Paint()
          ..color =
              candleColor,
      );
    }

    final ema =
        _calculateEma(
      candles,
      200,
    );

    final emaStart =
        math.max(
      0,
      ema.length -
          data.length,
    );

    final emaVisible =
        ema.sublist(
      emaStart,
    );

    if (emaVisible.length > 1) {
      final emaPaint = Paint()
        ..color =
            Colors.blueAccent
        ..strokeWidth = 1.8
        ..style =
            PaintingStyle.stroke;

      final path = Path();

      for (int i = 0;
          i < emaVisible.length;
          i++) {
        final x =
            xFor(
          i +
              data.length -
                  emaVisible.length,
        );

        final y =
            yFor(
          emaVisible[i],
        );

        if (i == 0) {
          path.moveTo(
            x,
            y,
          );
        } else {
          path.lineTo(
            x,
            y,
          );
        }
      }

      canvas.drawPath(
        path,
        emaPaint,
      );
    }

    _drawSmcEvents(
      canvas,
      data,
      xFor,
      yFor,
    );

    if (signal != null) {
      _drawSignalLevels(
        canvas,
        size,
        yFor,
        signal!,
      );
    }

    final last =
        data.last.close;

    final currentY =
        yFor(last);

    canvas.drawLine(
      Offset(
        left,
        currentY,
      ),
      Offset(
        size.width - right,
        currentY,
      ),
      Paint()
        ..color =
            Colors.white54
        ..strokeWidth = 1,
    );

    final currentText =
        TextPainter(
      text: TextSpan(
        text: _formatPrice(last),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight:
              FontWeight.bold,
        ),
      ),
      textDirection:
          TextDirection.ltr,
    )..layout();

    currentText.paint(
      canvas,
      Offset(
        size.width -
            right -
            currentText.width,
        currentY - 14,
      ),
    );
  }

  void _drawFvg(
    Canvas canvas,
    List<Candle> data,
    double Function(int) xFor,
    double Function(double) yFor,
  ) {
    if (data.length < 3) {
      return;
    }

    for (int i = 2;
        i < data.length;
        i++) {
      final a =
          data[i - 2];

      final c =
          data[i];

      if (a.high < c.low) {
        _drawZone(
          canvas,
          xFor(i - 2),
          xFor(i),
          yFor(c.low),
          yFor(a.high),
          Colors.purpleAccent,
        );
      }

      if (a.low > c.high) {
        _drawZone(
          canvas,
          xFor(i - 2),
          xFor(i),
          yFor(a.low),
          yFor(c.high),
          Colors.deepPurpleAccent,
        );
      }
    }
  }

  void _drawOrderBlocks(
    Canvas canvas,
    List<Candle> data,
    double Function(int) xFor,
    double Function(double) yFor,
  ) {
    if (data.length < 8) {
      return;
    }

    for (int i = 3;
        i < data.length;
        i++) {
      final previous =
          data[i - 1];

      final current =
          data[i];

      final previousRange =
          previous.high -
              previous.low;

      final currentRange =
          current.high -
              current.low;

      if (previousRange <= 0 ||
          currentRange <= 0) {
        continue;
      }

      final bullishImpulse =
          current.close >
                  previous.high &&
              current.close >
                  current.open &&
              currentRange >
                  previousRange *
                      1.25;

      final bearishImpulse =
          current.close <
                  previous.low &&
              current.close <
                  current.open &&
              currentRange >
                  previousRange *
                      1.25;

      if (bullishImpulse &&
          previous.close <
              previous.open) {
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
          previous.close >
              previous.open) {
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

    final rect =
        Rect.fromLTRB(
      x1,
      top,
      x2,
      bottom,
    );

    canvas.drawRect(
      rect,
      Paint()
        ..color =
            color.withValues(
          alpha: 0.08,
        ),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..color =
            color.withValues(
          alpha: 0.35,
        )
        ..style =
            PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawSmcEvents(
    Canvas canvas,
    List<Candle> data,
    double Function(int) xFor,
    double Function(double) yFor,
  ) {
    if (data.length < 8) {
      return;
    }

    for (int i = 5;
        i < data.length;
        i++) {
      final current =
          data[i];

      double previousHigh =
          data[i - 5].high;

      double previousLow =
          data[i - 5].low;

      for (int j = i - 5;
          j < i;
          j++) {
        previousHigh =
            math.max(
          previousHigh,
          data[j].high,
        );

        previousLow =
            math.min(
          previousLow,
          data[j].low,
        );
      }

      final bullishBos =
          current.close >
              previousHigh;

      final bearishBos =
          current.close <
              previousLow;

      final bullishSweep =
          current.low <
                  previousLow &&
              current.close >
                  previousLow;

      final bearishSweep =
          current.high >
                  previousHigh &&
              current.close <
                  previousHigh;

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

  void _drawSignalLevels(
    Canvas canvas,
    Size size,
    double Function(double) yFor,
    Signal signal,
  ) {
    final isBuy =
        signal.side.toUpperCase() ==
            'BUY';

    final entryColor =
        isBuy
            ? Colors.greenAccent
            : Colors.redAccent;

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
    if (y < 12 ||
        y > size.height - 25) {
      return;
    }

    canvas.drawLine(
      Offset(48, y),
      Offset(
        size.width - 8,
        y,
      ),
      Paint()
        ..color =
            color.withValues(
          alpha: 0.8,
        )
        ..strokeWidth = 1.2,
    );

    final painter =
        TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight:
              FontWeight.bold,
        ),
      ),
      textDirection:
          TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(
        54,
        y - 13,
      ),
    );
  }

  void _label(
    Canvas canvas,
    String text,
    double x,
    double y,
    Color color,
  ) {
    final painter =
        TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight:
              FontWeight.bold,
        ),
      ),
      textDirection:
          TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(
        math.max(
          58.0,
          x -
              painter.width /
                  2,
        ),
        math.max(
          4.0,
          y,
        ),
      ),
    );
  }

  List<double> _calculateEma(
    List<Candle> source,
    int period,
  ) {
    if (source.isEmpty) {
      return [];
    }

    final result =
        <double>[];

    final alpha =
        2.0 /
            (period + 1);

    double previous =
        source.first.close;

    result.add(previous);

    for (int i = 1;
        i < source.length;
        i++) {
      previous =
          (source[i].close -
                  previous) *
              alpha +
          previous;

      result.add(previous);
    }

    return result;
  }

  String _formatPrice(
    double value,
  ) {
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
