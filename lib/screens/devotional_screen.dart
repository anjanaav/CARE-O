import 'package:flutter/material.dart';

import 'prayers_screen.dart';
import 'devotional_music_screen.dart';
import 'quotes_screen.dart';

class DevotionalScreen extends StatelessWidget {
  const DevotionalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Devotion'),
          bottom: TabBar(
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: colorScheme.primary,
            tabs: const [
              Tab(
                icon: Icon(Icons.book),
                text: 'Prayers',
              ),
              Tab(
                icon: Icon(Icons.music_note),
                text: 'Devotion songs',
              ),
              Tab(
                icon: Icon(Icons.format_quote),
                text: 'Quotes',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            PrayersScreen(),
            DevotionalMusicScreen(),
            QuotesScreen(),
          ],
        ),
      ),
    );
  }
}