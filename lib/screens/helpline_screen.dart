import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HelplineScreen extends StatefulWidget {
  const HelplineScreen({super.key});

  @override
  State<HelplineScreen> createState() => _HelplineScreenState();
}

class _HelplineScreenState extends State<HelplineScreen> {
  final List<Map<String, String>> helplineNumbers = [
    {
      'title': 'Medical Emergency',
      'subtitle': 'Call 102',
      'number': '102',
      'icon': 'local_hospital',
      'color': 'red',
    },
    {
      'title': 'Mental Health Support',
      'subtitle': 'Call 1800-XYZ-ABC',
      'number': '1800XYZABC',
      'icon': 'support_agent',
      'color': 'blue',
    },
    {
      'title': 'Police Helpline',
      'subtitle': 'Call 100',
      'number': '100',
      'icon': 'local_police',
      'color': 'black',
    },
    {
      'title': 'Senior Citizen Support',
      'subtitle': 'Call 14567',
      'number': '14567',
      'icon': 'elderly',
      'color': 'green',
    },
  ];

  final TextEditingController _customNumberController =
      TextEditingController();

  String _customEmergencyNumber = '112';

  @override
  void initState() {
    super.initState();
    _loadCustomEmergencyNumber();
  }

  @override
  void dispose() {
    _customNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomEmergencyNumber() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _customEmergencyNumber =
          prefs.getString('customEmergencyNumber') ?? '112';
    });
  }

  Future<void> _saveCustomEmergencyNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final String newNumber = _customNumberController.text.trim();

    if (newNumber.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an emergency number.'),
        ),
      );
      return;
    }

    await prefs.setString('customEmergencyNumber', newNumber);

    if (!mounted) return;

    setState(() {
      _customEmergencyNumber = newNumber;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Custom Emergency Number Set: $newNumber'),
      ),
    );
  }

  Future<void> _callHelpline(String number) async {
    final Uri phoneUri = Uri.parse('tel:$number');

    try {
      final bool launched = await launchUrl(phoneUri);

      if (!launched) {
        debugPrint('Could not launch $number');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Helpline'),
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Emergency Helpline Numbers',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: helplineNumbers.length,
                itemBuilder: (context, index) {
                  final helpline = helplineNumbers[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 2,
                    color: colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: colorScheme.outlineVariant,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _getColor(
                            helpline['color']!,
                            colorScheme,
                          ).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIcon(helpline['icon']!),
                          color: _getColor(
                            helpline['color']!,
                            colorScheme,
                          ),
                        ),
                      ),
                      title: Text(
                        helpline['title']!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        helpline['subtitle']!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Icon(
                        Icons.call,
                        color: colorScheme.primary,
                      ),
                      onTap: () => _callHelpline(helpline['number']!),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _customNumberController,
              keyboardType: TextInputType.phone,
              style: TextStyle(
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                labelText: 'Enter Custom Emergency Number',
                labelStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                ),
                prefixIcon: Icon(
                  Icons.phone,
                  color: colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: colorScheme.outline,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 30,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.save),
                label: const Text(
                  'Set Custom Number',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
                onPressed: _saveCustomEmergencyNumber,
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 30,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.sos),
                label: Text(
                  'Emergency SOS (Call $_customEmergencyNumber)',
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
                onPressed: () => _callHelpline(_customEmergencyNumber),
              ),
            ),

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'local_hospital':
        return Icons.local_hospital;
      case 'support_agent':
        return Icons.support_agent;
      case 'local_police':
        return Icons.local_police;
      case 'elderly':
        return Icons.elderly;
      default:
        return Icons.phone;
    }
  }

  Color _getColor(
    String colorName,
    ColorScheme colorScheme,
  ) {
    switch (colorName) {
      case 'red':
        return colorScheme.error;

      case 'blue':
        return colorScheme.primary;

      case 'black':
        return colorScheme.onSurface;

      case 'green':
        return colorScheme.secondary;

      default:
        return colorScheme.onSurfaceVariant;
    }
  }
}