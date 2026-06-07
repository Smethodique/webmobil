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

  static const _marker = '\x00MATH\x00';

  String _normalizeLatex(String input) {
    String s = input;

    // 1. $$...$$ (display math)
    s = s.replaceAllMapped(RegExp(r'\$\$(.+?)\$\$', dotAll: true),
        (m) => _marker + m.group(1)! + _marker);

    // 3. \(...\) — handles 1-3 backslashes (some JSON/AI responses triple-escape)
    s = s.replaceAllMapped(RegExp(r'\\{1,3}\((.+?)\\{1,3}\)', dotAll: true),
        (m) => _marker + m.group(1)! + _marker);

    // 4. \[...\] — handles 1-3 backslashes
    s = s.replaceAllMapped(RegExp(r'\\{1,3}\[(.+?)\\{1,3}\]', dotAll: true),
        (m) => _marker + m.group(1)! + _marker);

    // 4. AI content: $...$ with math content
    if (isAiContent) {
      s = s.replaceAllMapped(RegExp(r'\$([^$]{2,}?)\$'), (m) {
        final c = m.group(1)!;
        if (c.contains('\\') || c.contains('^') || c.contains('_') ||
            c.contains('{') || c.contains('=') || RegExp(r'\d').hasMatch(c)) {
          return _marker + c + _marker;
        }
        return m.group(0)!;
      });
    }
    return s;
  }

  List<InlineSpan> _buildSpans(String input) {
    final spans = <InlineSpan>[];
    final color = textColor ?? AppColors.textPrimary;
    final parts = input.split(_marker);
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
    if (!cleaned.contains(_marker)) {
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
