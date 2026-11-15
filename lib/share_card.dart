import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'widgets/brand_footer.dart';
import 'widgets/sample_stats.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'api.dart';
import 'theme.dart';

/// A branded, share-ready card: BullDozer mark, a title, a mini ranked bar
/// chart and a source/footer line. Rendered on a preview screen and captured
/// to PNG for sharing — free marketing when a chart lands on social.
class ShareCard extends StatelessWidget {
  final String tag;
  final String title;
  final List<(String, double)> bars; // (label, value) desc
  final String footer;
  /// Every value in the ranking, not only the bars drawn: the card states the
  /// median and mean of the whole sample and ticks the median in each bar.
  final List<double> all;
  final String unit;
  const ShareCard(
      {super.key,
      required this.tag,
      required this.title,
      required this.bars,
      required this.footer,
      this.all = const [],
      this.unit = ''});

  @override
  Widget build(BuildContext context) {
    final maxV = bars.isEmpty
        ? 1.0
        : bars.map((b) => b.$2.abs()).reduce((a, b) => a > b ? a : b);
    // Always dark — the share card reads the same everywhere, theme aside.
    const bg = Color(0xFF0E0F11);
    const card = Color(0xFF1C1F23);
    const amber = Color(0xFFFFB000);
    const text = Color(0xFFE7E9EC);
    const dim = Color(0xFF9AA1A9);
    final med = all.length >= 3 ? medianOf(all) : double.nan;
    final medFrac = med.isNaN || med < 0 || maxV == 0 ? null : (med / maxV).clamp(0.0, 1.0);
    return Container(
      width: 400,
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(color: bg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [amber, Color(0xFFFF7A00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: const Text('B',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1300))),
              ),
              const SizedBox(width: 8),
              const Text.rich(TextSpan(children: [
                TextSpan(
                    text: 'Bull',
                    style: TextStyle(
                        color: text, fontWeight: FontWeight.w800)),
                TextSpan(
                    text: 'Dozer',
                    style: TextStyle(
                        color: amber, fontWeight: FontWeight.w800)),
              ]), style: TextStyle(fontSize: 19)),
            ],
          ),
          const SizedBox(height: 16),
          Text(tag.toUpperCase(),
              style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                  color: amber)),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: text)),
          const SizedBox(height: 14),
          if (all.length >= 3)
            SampleStats(
                values: all,
                unit: unit,
                color: dim,
                tickColor: text.withValues(alpha: 0.6),
                fontSize: 11),
          const SizedBox(height: 2),
          for (final b in bars.take(6))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(b.$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: text)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 17,
                      child: LayoutBuilder(builder: (context, c) {
                        final bar = Container(
                          height: 9,
                          decoration: BoxDecoration(
                              color: card,
                              borderRadius: BorderRadius.circular(4)),
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor:
                                (maxV == 0 ? 0.0 : b.$2.abs() / maxV)
                                    .clamp(0.03, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: amber,
                                  borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                        );
                        if (medFrac == null) return Align(alignment: Alignment.centerLeft, child: bar);
                        return Stack(alignment: Alignment.centerLeft, children: [
                          bar,
                          Positioned(
                            left: (medFrac * c.maxWidth - 1).clamp(0.0, c.maxWidth - 2),
                            top: 0,
                            bottom: 0,
                            child: Container(width: 2, color: text.withValues(alpha: 0.6)),
                          ),
                        ]);
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 48,
                    child: Text(formatValue(b.$2),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: text)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Text(footer,
              style: const TextStyle(fontSize: 11, color: dim)),
          const SizedBox(height: 4),
          const BrandFooter(color: amber, dim: dim, align: MainAxisAlignment.start),
        ],
      ),
    );
  }
}

/// Full-screen preview of a [ShareCard] with a Share button. The card is on
/// screen, so capturing it to PNG is a plain RepaintBoundary read.
class SharePreviewPage extends StatefulWidget {
  final String tag;
  final String title;
  final List<(String, double)> bars;
  final String footer;
  final List<double> all;
  final String unit;
  const SharePreviewPage(
      {super.key,
      required this.tag,
      required this.title,
      required this.bars,
      required this.footer,
      this.all = const [],
      this.unit = ''});

  @override
  State<SharePreviewPage> createState() => _SharePreviewPageState();
}

class _SharePreviewPageState extends State<SharePreviewPage> {
  final _boundaryKey = GlobalKey();
  bool _busy = false;

  final _buttonKey = GlobalKey();

  /// Captures the card and opens the share sheet. The first tap used to spin
  /// for ~8 s and then do nothing (reviewers, 15 Nov 2026): the capture ran
  /// before the card's first paint had settled, and on iPad the sheet needs an
  /// anchor rect or it never appears. Now the button stays busy until the
  /// sheet is up, the capture is bounded, and any failure says so.
  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final file = await _capture().timeout(const Duration(seconds: 12));
      if (!mounted) return;
      final origin = _anchorRect();
      // On iOS the call returns when the sheet is dismissed; on Android once
      // it is up. Either way a call that has not returned after a minute is
      // an open sheet, not a failure — release the button quietly.
      await SharePlus.instance
          .share(ShareParams(
            files: [XFile(file, mimeType: 'image/png')],
            text: '${widget.title} — BullDozer Stats · azenha.ai/bulldozer',
            sharePositionOrigin: origin,
          ))
          .timeout(const Duration(seconds: 60), onTimeout: () => ShareResult.unavailable);
    } on TimeoutException {
      _fail('Creating the image took too long. Please try again.');
    } catch (_) {
      _fail('Couldn\'t share the image. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String> _capture() async {
    // Let the card finish painting (fonts, the SVG store marks) first.
    await WidgetsBinding.instance.endOfFrame;
    final boundary = _boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) throw StateError('card not on screen');
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) throw StateError('no image data');
    final dir = await getTemporaryDirectory();
    return _writeTemp(dir.path, data.buffer.asUint8List());
  }

  /// The Share button's rect — the iPad share popover anchors to it.
  Rect? _anchorRect() {
    final box = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _fail(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<String> _writeTemp(String dir, Uint8List bytes) async {
    // A fresh name each time: some share targets cache by path.
    final path = '$dir/bulldozer_share_${DateTime.now().millisecondsSinceEpoch}.png';
    await _FileWriter.write(path, bytes);
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: ShareCard(
                      tag: widget.tag,
                      title: widget.title,
                      bars: widget.bars,
                      footer: widget.footer,
                      all: widget.all,
                      unit: widget.unit),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: _buttonKey,
                onPressed: _busy ? null : _share,
                style: FilledButton.styleFrom(
                    backgroundColor: kAmber,
                    foregroundColor: kOnAmber,
                    disabledBackgroundColor: kAmber.withValues(alpha: 0.55),
                    disabledForegroundColor: kOnAmber),
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: kOnAmber))
                    : const Icon(Icons.share),
                label: Text(_busy ? 'Preparing…' : 'Share image',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small dart:io wrapper kept apart so the rest of the file stays web-safe.
class _FileWriter {
  static Future<void> write(String path, Uint8List bytes) async {
    await File(path).writeAsBytes(bytes);
  }
}
