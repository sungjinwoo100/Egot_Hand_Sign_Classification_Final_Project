import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'services/history_service.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final HistoryService _historyService = HistoryService();
  AnalyticsData? _data;
  bool _isLoading = true;
  int _selectedFilterIndex = 0; // 0: 7 Days, 1: 30 Days, 2: Year

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _historyService.getAnalytics();
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  }

  List<int> get _currentChartData {
    if (_data == null) return [];
    switch (_selectedFilterIndex) {
      case 0:
        return _data!.last7Days;
      case 1:
        return _data!.last30Days;
      case 2:
        return _data!.last12Months;
      default:
        return [];
    }
  }

  String get _currentChartLabel {
    switch (_selectedFilterIndex) {
      case 0:
        return 'Weekly';
      case 1:
        return 'Monthly';
      case 2:
        return 'Yearly';
      default:
        return 'Activity';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1612),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Statistics',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white54, size: 20),
            onPressed: _isLoading ? null : _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4ADE80)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Classification\nAnalytics',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _TimeFilter(
                    selectedIndex: _selectedFilterIndex,
                    onChanged: (index) {
                      setState(() {
                        _selectedFilterIndex = index;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  _ActivityChartCard(
                    data: _currentChartData,
                    filterIndex: _selectedFilterIndex,
                    titleLabel: _currentChartLabel,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          title: 'AVG CONFIDENCE',
                          value: '${(_data!.averageConfidence * 100).toInt()}%',
                          change: _data!.totalDetections > 0
                              ? 'Based on ${_data!.totalDetections} scans'
                              : 'No data yet',
                          changeColor: const Color(0xFF4ADE80),
                          showProgress: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _MetricCard(
                          title: 'TOP SIGN',
                          value: _data!.topSign,
                          subValue: '${_data!.topSignCount} detections',
                          icon: Icons.emoji_events,
                          showProgress: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Top Recognitions',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_data!.classFrequency.isEmpty)
                    Center(
                      child: Text(
                        "No data available",
                        style: GoogleFonts.inter(color: Colors.white24),
                      ),
                    )
                  else
                    ..._buildRecognitionList(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildRecognitionList() {
    final entries = _data!.classFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 5
    final top = entries.take(5).toList();
    final total = _data!.totalDetections > 0 ? _data!.totalDetections : 1;

    return top.map((e) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _RecognitionItem(
          label: e.key,
          percentage: e.value / total,
          // Generic icon logic
          icon: Icons.star,
        ),
      );
    }).toList();
  }
}

class _TimeFilter extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _TimeFilter({required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF14201A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(0),
              child: _FilterButton('7 Days', isSelected: selectedIndex == 0),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(1),
              child: _FilterButton('30 Days', isSelected: selectedIndex == 1),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(2),
              child: _FilterButton('Year', isSelected: selectedIndex == 2),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FilterButton(this.label, {required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF4ADE80) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? const Color(0xFF0D1612) : Colors.white54,
          ),
        ),
      ),
    );
  }
}

class _ActivityChartCard extends StatelessWidget {
  final List<int> data;
  final int filterIndex; // 0, 1, 2
  final String titleLabel;

  const _ActivityChartCard({
    required this.data,
    required this.filterIndex,
    required this.titleLabel,
  });

  @override
  Widget build(BuildContext context) {
    String legendLabel = 'Last 7 Days';
    if (filterIndex == 1) legendLabel = 'Last 30 Days';
    if (filterIndex == 2) legendLabel = 'Last 12 Months';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF14201A),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.insights,
                        color: const Color(0xFF4ADE80),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        titleLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Activity',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              _LegendItem(color: const Color(0xFF4ADE80), label: legendLabel),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            width: double.infinity,
            child: CustomPaint(painter: _ChartPainter(data)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _buildXAxisLabels(filterIndex),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildXAxisLabels(int index) {
    final now = DateTime.now();
    List<Widget> labels = [];

    if (index == 0) {
      // 7 Days
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        labels.add(_AxisLabel(DateFormat('E').format(date).substring(0, 1)));
      }
    } else if (index == 1) {
      // 30 Days - Show approx every 5 days
      for (int i = 29; i >= 0; i -= 5) {
        final date = now.subtract(Duration(days: i));
        labels.add(_AxisLabel("${date.day}"));
      }
    } else {
      // Year - Show every 2 months or abbreviated
      for (int i = 11; i >= 0; i -= 2) {
        // rough month subtraction
        final date = DateTime(now.year, now.month - i, 1);
        labels.add(_AxisLabel(DateFormat('MMM').format(date)));
      }
    }

    return labels;
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: Colors.white54),
        ),
      ],
    );
  }
}

class _AxisLabel extends StatelessWidget {
  final String text;
  const _AxisLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 10, color: Colors.white24),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? change;
  final String? subValue;
  final Color? changeColor;
  final IconData? icon;
  final bool showProgress;

  const _MetricCard({
    required this.title,
    required this.value,
    this.change,
    this.subValue,
    this.changeColor,
    this.icon,
    required this.showProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF14201A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white54,
              letterSpacing: 1.0,
            ),
          ),
          if (icon != null)
            Center(child: Icon(icon, size: 48, color: Colors.white)),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (showProgress)
            Stack(
              children: [
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  height: 4,
                  width: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ADE80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          if (change != null)
            Text(
              change!,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: changeColor,
              ),
            ),
          if (subValue != null)
            Center(
              child: Text(
                subValue!,
                style: GoogleFonts.inter(fontSize: 10, color: Colors.white54),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecognitionItem extends StatelessWidget {
  final String label;
  final double percentage;
  final IconData icon;

  const _RecognitionItem({
    required this.label,
    required this.percentage,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    const Color color = Color(0xFF4ADE80);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF14201A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '${(percentage * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<int> data;

  _ChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grid lines (vertical)
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw background vertical grid
    // Dynamic segments based on data length? Or static?
    // Let's use 6 segments as a safe default
    int segments = 6;
    for (int i = 0; i <= segments; i++) {
      double x = w * (i / segments);
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }

    if (data.isEmpty) return;

    // Find max value for normalization
    final maxVal = data.fold(0, (max, v) => v > max ? v : max);
    // Avoid division by zero, set min height
    final scale = maxVal > 0 ? h * 0.8 / maxVal : 0.0;

    // Line (Green)
    final greenPaint = Paint()
      ..color = const Color(0xFF4ADE80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path1 = Path();

    // Create points
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = w * (i / (data.length - 1));
      // y is inverted (0 is top), also add some padding from bottom
      final val = data[i] * scale;
      final y = h - (val + h * 0.1);
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      path1.moveTo(points[0].dx, points[0].dy);
      for (int i = 0; i < points.length - 1; i++) {
        // Cubic logic
        // Adjust control points for smoother or sharper curves depending on density
        final p1 = points[i];
        final p2 = points[i + 1];

        // If we have many points (like 30), maybe simple line to avoid overshooting loops
        if (data.length > 15) {
          path1.lineTo(p2.dx, p2.dy);
        } else {
          final controlPoint1 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p1.dy);
          final controlPoint2 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p2.dy);
          path1.cubicTo(
            controlPoint1.dx,
            controlPoint1.dy,
            controlPoint2.dx,
            controlPoint2.dy,
            p2.dx,
            p2.dy,
          );
        }
      }
    }

    // Draw shadow/gradient fill for Green Line
    final fillPath = Path.from(path1);
    fillPath.lineTo(w, h);
    fillPath.lineTo(0, h);
    fillPath.close();

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF4ADE80).withValues(alpha: 0.3),
          const Color(0xFF4ADE80).withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(fillPath, gradientPaint);
    canvas.drawPath(path1, greenPaint);

    // Dots on points (only if few points)
    if (data.length < 15) {
      for (final point in points) {
        canvas.drawCircle(point, 6, Paint()..color = Colors.white);
        canvas.drawCircle(point, 4, Paint()..color = const Color(0xFF4ADE80));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
