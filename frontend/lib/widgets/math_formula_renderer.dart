import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../constants/colors.dart';

class MathFormulaRenderer extends StatelessWidget {
  final String text;
  final double textScale;
  final Color? textColor;
  final bool isAiContent;

  const MathFormulaRenderer({
    super.key,
    required this.text,
    this.textScale = 1.0,
    this.textColor,
    this.isAiContent = false,
  });

  // Two literal dollar signs — safe from Dart $ interpolation
  static final _dd = '\x24\x24';

  String _normalizeLatex(String input) {
    String s = input;
    s = s.replaceAll('\\(', _dd);
    s = s.replaceAll('\\)', _dd);
    s = s.replaceAll('\\[', _dd);
    s = s.replaceAll('\\]', _dd);
    if (isAiContent) {
      // Only match $...$ with math content (contains backslash, ^, _, numbers, etc.)
      final singleDollar = RegExp(r'\$([^$]{2,}?)\$');
      s = s.replaceAllMapped(singleDollar, (m) {
        final content = m.group(1)!;
        // Only convert if it looks like math (has LaTeX commands or math symbols)
        if (content.contains('\\') || 
            content.contains('^') || 
            content.contains('_') ||
            content.contains('{') ||
            content.contains('=') ||
            RegExp(r'\d').hasMatch(content)) {
          return _dd + content + _dd;
        }
        return m.group(0)!; // Not math, keep as-is
      });
    }
    return s;
  }

  List<InlineSpan> _buildSpans(String input) {
    final spans = <InlineSpan>[];
    final color = textColor ?? AppColors.textPrimary;
    final parts = input.split(_dd);
    for (var i = 0; i < parts.length; i++) {
      if (i.isOdd) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _SafeMath(tex: parts[i], color: color, fontSize: 14 * textScale),
        ));
      } else if (parts[i].isNotEmpty) {
        spans.add(TextSpan(
          text: parts[i],
          style: TextStyle(color: color, fontSize: 14 * textScale, height: 1.5),
        ));
      }
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final cleaned = _normalizeLatex(text);
    if (!cleaned.contains(_dd)) {
      return Text(text, style: TextStyle(
        color: textColor ?? AppColors.textPrimary,
        fontSize: 14 * textScale, height: 1.5,
      ));
    }
    return RichText(text: TextSpan(children: _buildSpans(cleaned)));
  }
}

class _SafeMath extends StatelessWidget {
  final String tex;
  final Color color;
  final double fontSize;
  const _SafeMath({required this.tex, required this.color, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    try {
      return Math.tex(tex, textStyle: TextStyle(color: color, fontSize: fontSize),
        onErrorFallback: (error) => Text(tex,
          style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: fontSize * 0.9, fontStyle: FontStyle.italic)),
      );
    } catch (_) {
      return Text(tex, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: fontSize));
    }
  }
}
