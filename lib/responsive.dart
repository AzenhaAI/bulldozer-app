// Turning the phone column into a large-screen layout.
//
// Capping the content width was only half the job: on a 13" iPad the app still
// read as a phone screen someone had enlarged, because every deck of cards was
// a single column no matter how much room there was. A newspaper app on that
// display — FT, WSJ — runs its stories two and three abreast. This file is the
// piece that lets each deck do the same.
import 'package:flutter/widgets.dart';

/// How many card columns fit in [width] points.
///
/// 800 is the phone/tablet line: it clears the iPad mini in portrait (744, one
/// column — two would be cramped) and lets the 11" portrait (820) split. 1180
/// opens a third column, which is where the 13" landscape (1366) and a split
/// view on a Mac land.
int columnsFor(double width) => width < 800 ? 1 : (width < 1180 ? 2 : 3);

/// True when there is room for more than one column of cards.
bool isWide(BuildContext context) =>
    columnsFor(MediaQuery.sizeOf(context).width) > 1;

/// Two blocks that stack on a phone and sit side by side when there is room.
///
/// [flexA]/[flexB] split the width; the gap is only inserted in the wide case.
class SideBySide extends StatelessWidget {
  final Widget a;
  final Widget b;
  final int flexA;
  final int flexB;
  final double gap;

  const SideBySide(
      {super.key,
      required this.a,
      required this.b,
      this.flexA = 3,
      this.flexB = 2,
      this.gap = 12});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        if (columnsFor(c.maxWidth) == 1) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [a, SizedBox(height: gap + 4), b]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: flexA, child: a),
            SizedBox(width: gap),
            Expanded(flex: flexB, child: b),
          ],
        );
      });
}

/// A deck of cards that flows into as many columns as the width allows.
///
/// On a phone this is exactly a `Column` — same widgets, same order, nothing to
/// re-test. Wider, it fills rows left to right and top-aligns them, so a short
/// card next to a tall one leaves a gap rather than stretching.
class CardGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  /// Cap for decks that look silly very wide — three columns of two-line list
  /// tiles, for instance, is thinner than it is useful.
  final int maxColumns;

  const CardGrid(
      {super.key,
      required this.children,
      this.spacing = 10,
      this.maxColumns = 3});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, c) {
      final cols = columnsFor(c.maxWidth).clamp(1, maxColumns);
      if (cols == 1) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
      }
      final rows = <Widget>[];
      for (var i = 0; i < children.length; i += cols) {
        final slots = <Widget>[];
        for (var j = 0; j < cols; j++) {
          if (j > 0) slots.add(SizedBox(width: spacing));
          // The last row is usually short; empty Expandeds keep the cards that
          // are there at column width instead of letting them spread.
          slots.add(Expanded(
              child: i + j < children.length
                  ? children[i + j]
                  : const SizedBox.shrink()));
        }
        if (rows.isNotEmpty) rows.add(SizedBox(height: spacing));
        rows.add(Row(
            crossAxisAlignment: CrossAxisAlignment.start, children: slots));
      }
      return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
    });
  }
}
