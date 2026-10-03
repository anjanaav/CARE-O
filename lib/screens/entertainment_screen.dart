import 'package:flutter/material.dart';
import 'games_screen.dart';
import 'music_screen.dart';

class EntertainmentScreen extends StatelessWidget {
  const EntertainmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entertainment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCategoryTile(
              context,
              icon: Icons.videogame_asset,
              title: 'Games',
              subtitle: 'Play engaging games for mental stimulation.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GamesScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildCategoryTile(
              context,
              icon: Icons.music_note,
              title: 'Music',
              subtitle: 'Enjoy personalized playlists and soothing tracks.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MusicScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        color: theme.cardTheme.color,
        border: Border.all(color: theme.dividerColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20.0),
        leading: Icon(icon, size: 40, color: theme.colorScheme.primary),
        title: Text(title, style: theme.textTheme.titleLarge),
        subtitle: Text(subtitle, style: theme.textTheme.bodyMedium),
        onTap: onTap,
      ),
    );
  }
}
