import 'package:flutter/material.dart';
import 'prayers_screen.dart';
import 'devotional_music_screen.dart';
import 'quotes_screen.dart';

class DevotionalScreen extends StatelessWidget {
  const DevotionalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Devotion'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.book), text: 'Prayers'),
              Tab(icon: Icon(Icons.music_note), text: 'Devotion songs'),
              Tab(icon: Icon(Icons.format_quote), text: 'Quotes'),
            ],
          ),
        ),
        body: const TabBarView(
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
