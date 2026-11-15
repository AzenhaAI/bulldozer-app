import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The project's name, address and the two stores, under every chart and on
/// every shared image: a picture passed around with only "azenha.ai/bulldozer"
/// under it did not say what the app was called or where to get it (owner,
/// 14 Nov 2026). The marks are the same 24-unit paths azenha.ai/apps uses.
const _apple =
    'M16.4 12.8c0-2.1 1.7-3.1 1.8-3.2-1-1.4-2.5-1.6-3-1.6-1.3-.1-2.5.7-3.1.7-.7 0-1.7-.7-2.8-.7-1.4 0-2.7.8-3.4 2.1-1.5 2.6-.4 6.4 1.1 8.5.7 1 1.5 2.2 2.7 2.1 1.1 0 1.5-.7 2.8-.7s1.7.7 2.8.7c1.2 0 1.9-1 2.6-2.1.8-1.2 1.1-2.3 1.2-2.4 0 0-2.7-1-2.7-3.4ZM14.3 6.6c.6-.7 1-1.7.9-2.7-.9 0-1.9.6-2.5 1.3-.6.7-1 1.6-.9 2.6 1 .1 2-.5 2.5-1.2Z';
const _play =
    'M4.6 2.6a1 1 0 0 0-.5.9v17a1 1 0 0 0 .5.9l9.1-9.4-9.1-9.4Zm10.2 8.3 2.9-3-9.9-5.6 7 8.6Zm0 2.2-7 8.6 9.9-5.6-2.9-3Zm4.1-2.2-2.4-1.4-3 3.5 3 3.5 2.4-1.4c.9-.5.9-1.7 0-2.2Z';

Widget _mark(String d, Color c, double size) => SvgPicture.string(
      '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path fill="#000" d="$d"/></svg>',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
    );

class BrandFooter extends StatelessWidget {
  final Color color;
  final double fontSize;
  final MainAxisAlignment align;
  const BrandFooter({super.key, required this.color, this.fontSize = 11, this.align = MainAxisAlignment.center});

  @override
  Widget build(BuildContext context) {
    final t = TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, letterSpacing: 0.2, color: color);
    final icon = fontSize * 1.25;
    return Wrap(
      alignment: align == MainAxisAlignment.center
          ? WrapAlignment.center
          : align == MainAxisAlignment.end
              ? WrapAlignment.end
              : WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: fontSize * 0.5,
      runSpacing: 2,
      children: [
        // The name in capitals and the address in a lighter weight: set in
        // one run they read as one blur of text (owner, 15 Nov 2026).
        Text('BULLDOZER STATS',
            style: t.copyWith(fontWeight: FontWeight.w900, letterSpacing: fontSize * 0.12)),
        Text('azenha.ai/bulldozer',
            style: t.copyWith(fontWeight: FontWeight.w500, color: color.withValues(alpha: color.a * 0.8))),
        Row(mainAxisSize: MainAxisSize.min, children: [
          _mark(_apple, color, icon),
          SizedBox(width: fontSize * 0.2),
          Text('App Store', style: t.copyWith(fontWeight: FontWeight.w600)),
          SizedBox(width: fontSize * 0.6),
          _mark(_play, color, icon * 0.9),
          SizedBox(width: fontSize * 0.25),
          Text('Google Play', style: t.copyWith(fontWeight: FontWeight.w600)),
        ]),
      ],
    );
  }
}
