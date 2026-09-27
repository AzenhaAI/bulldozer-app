import 'package:flutter/material.dart';

import '../search_page.dart';
import '../theme.dart';

/// Theme, search and the menu — the three buttons at the top right.
///
/// They used to live only in the Home header, so on every other tab there was
/// no way to open the menu, switch the theme or search without going back
/// first — noticed during testing. One widget now, used by every tab's title row and
/// by Home, so the set cannot drift between screens. The menu button appears
/// only where there is a menu to open: on a page pushed over the tabs the
/// nearest Scaffold has no drawer.
class ShellActions extends StatelessWidget {
  const ShellActions({super.key});

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold.maybeOf(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
        onPressed: toggleTheme,
        icon: Text(isLight ? '🌙' : '☀️', style: const TextStyle(fontSize: 18)),
        tooltip: 'Toggle light/dark theme',
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
      IconButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const SearchPage())),
        icon: Icon(Icons.search, color: kText),
        tooltip: 'Search',
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
      if (scaffold?.hasEndDrawer ?? false)
        IconButton(
          onPressed: () => scaffold!.openEndDrawer(),
          icon: Icon(Icons.menu, color: kText),
          tooltip: 'Menu',
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
    ]);
  }
}
