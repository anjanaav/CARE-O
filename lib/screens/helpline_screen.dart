import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HelplineScreen extends StatefulWidget {
  const HelplineScreen({super.key});

  @override
  _HelplineScreenState createState() => _HelplineScreenState();
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

  final TextEditingController _customNumberController = TextEditingController();
  String _customEmergencyNumber = '112'; // Default emergency number

  @override
  void initState() {
    super.initState();
    _loadCustomEmergencyNumber();
  }

  Future<void> _loadCustomEmergencyNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _customEmergencyNumber =
          prefs.getString('customEmergencyNumber') ?? '112';
    });
  }

  Future<void> _saveCustomEmergencyNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String newNumber = _customNumberController.text.trim();
    if (newNumber.isNotEmpty) {
      await prefs.setString('customEmergencyNumber', newNumber);
      setState(() {
        _customEmergencyNumber = newNumber;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Custom Emergency Number Set: $newNumber')),
      );
    }
  }

  Future<void> _callHelpline(String number) async {
    final Uri phoneUri = Uri.parse("tel:$number");

    try {
      bool launched = await launchUrl(phoneUri);
      if (!launched) {
        debugPrint("Could not launch $number");
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Helpline'),
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Emergency Helpline Numbers:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: helplineNumbers.length,
                itemBuilder: (context, index) {
                  final helpline = helplineNumbers[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 3,
                    child: ListTile(
                      leading: Icon(
                        _getIcon(helpline['icon']!),
                        color: _getColor(helpline['color']!),
                      ),
                      title: Text(helpline['title']!),
                      subtitle: Text(helpline['subtitle']!),
                      trailing: const Icon(Icons.call, color: Colors.green),
                      onTap: () => _callHelpline(helpline['number']!),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Custom Emergency Number Input
            TextField(
              controller: _customNumberController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Enter Custom Emergency Number',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 10),

            // Button to Save Custom Emergency Number
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Set Custom Number',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
              onPressed: _saveCustomEmergencyNumber,
            ),
            const SizedBox(height: 20),

            // Emergency SOS Button with Custom Number
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.sos, color: Colors.white),
              label: Text(
                'Emergency SOS (Call $_customEmergencyNumber)',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              onPressed: () => _callHelpline(_customEmergencyNumber),
            ),
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

  Color _getColor(String colorName) {
    switch (colorName) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'black':
        return Colors.black;
      case 'green':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
