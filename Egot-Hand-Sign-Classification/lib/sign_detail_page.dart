import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'data/sign_data.dart';
import 'services/history_service.dart';

class SignDetailPage extends StatelessWidget {
  final ClassificationResult result;

  const SignDetailPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final content = SignRepository.getContent(result.label);

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
          'Sign Detail',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share, color: Colors.white54, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroCard(result: result, content: content),
            const SizedBox(height: 32),
            _SectionHeader(icon: Icons.insights, title: 'Class Distribution'),
            const SizedBox(height: 16),
            _ClassDistribution(result: result),
            const SizedBox(height: 32),
            _SectionHeader(icon: Icons.info, title: 'Meaning & Context'),
            const SizedBox(height: 16),
            _ContextCard(content: content),
            const SizedBox(height: 32),
            _SectionHeader(icon: Icons.lightbulb, title: 'How to Perform'),
            const SizedBox(height: 16),
            _InstructionsCard(content: content),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4ADE80), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final ClassificationResult result;
  final SignContent content;

  const _HeroCard({required this.result, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF14201A),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        gradient: LinearGradient(
          colors: [const Color(0xFF1E3A2F), const Color(0xFF14201A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4ADE80).withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
              image: result.imagePath != null
                  ? DecorationImage(
                      image: FileImage(File(result.imagePath!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: result.imagePath == null
                ? const Icon(
                    Icons.image_not_supported,
                    color: Colors.white54,
                    size: 48,
                  )
                : null,
          ),
          const SizedBox(height: 24),
          Text(
            content.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: content.tags.map((tag) => _Tag(tag)).toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'CONFIDENCE',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white54,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(result.confidence * 100).toStringAsFixed(1)}%',
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              if (content.accuracyTrend != '-' &&
                  content.accuracyTrend != 'Stable')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ADE80).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    content.accuracyTrend,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4ADE80),
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

class _Tag extends StatelessWidget {
  final String text;

  const _Tag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      ),
    );
  }
}

class _ClassDistribution extends StatelessWidget {
  final ClassificationResult result;

  const _ClassDistribution({required this.result});

  @override
  Widget build(BuildContext context) {
    // Sort probabilities
    var entries = result.probabilities?.entries.toList() ?? [];
    entries.sort((a, b) => b.value.compareTo(a.value));

    // Take top 3 or all if less than 3
    final topEntries = entries.take(3).toList();

    // If empty (legacy data without probabilities), show fallback
    if (topEntries.isEmpty) {
      return Center(
        child: Text(
          "No detailed stats available",
          style: GoogleFonts.inter(color: Colors.white54),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF14201A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < topEntries.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            _DistributionItem(
              topEntries[i].key,
              topEntries[i].value,
              topEntries[i].key ==
                  result.label, // Highlight if it matches the main label
            ),
          ],
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.table_chart, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  'View Raw Data',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DistributionItem extends StatelessWidget {
  final String label;
  final double percentage;
  final bool isHighlight;

  const _DistributionItem(this.label, this.percentage, this.isHighlight);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                color: isHighlight ? Colors.white : Colors.white70,
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isHighlight ? const Color(0xFF4ADE80) : Colors.white54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isHighlight ? const Color(0xFF4ADE80) : Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ContextCard extends StatelessWidget {
  final SignContent content;

  const _ContextCard({required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF14201A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Text(
            content.contextDescription,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.6,
              color: Colors.white70,
            ),
          ),
          if (content.culturalNote != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.public,
                    color: Color(0xFFFACC15), // Yellow warning
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 1.5,
                          color: Colors.white70,
                        ),
                        children: [
                          TextSpan(
                            text: 'Cultural Note: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          TextSpan(text: content.culturalNote),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InstructionsCard extends StatelessWidget {
  final SignContent content;

  const _InstructionsCard({required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF14201A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < content.instructions.length; i++) ...[
            if (i > 0) const SizedBox(height: 24),
            _InstructionItem(step: content.instructions[i]),
          ],
        ],
      ),
    );
  }
}

class _InstructionItem extends StatelessWidget {
  final InstructionStep step;

  const _InstructionItem({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF0D1612),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E3A2F)),
          ),
          child: Center(
            child: step.isIcon
                ? Icon(
                    Icons.receipt_long,
                    color: const Color(0xFF4ADE80),
                    size: 16,
                  )
                : Text(
                    step.step,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4ADE80),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step.desc,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  height: 1.5,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
