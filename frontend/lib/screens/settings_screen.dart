import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  String _primaryLanguage = 'German';
  String _learningPace = 'Moderate';

  @override
  void initState() {
    super.initState();
    _fetchUserSettings();
  }

  Future<void> _fetchUserSettings() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/v1/tutor/progress'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        setState(() {
          _primaryLanguage = jsonResponse['primary_language'] ?? 'German';
          _learningPace = jsonResponse['learning_pace'] ?? 'Moderate';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching settings preferences: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateBackendPreferences(String newLanguage, String newPace) async {
    try {
      await http.post(
        Uri.parse('http://localhost:8000/api/v1/tutor/update-preferences'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "primary_language": newLanguage,
          "learning_pace": newPace,
        }),
      );
    } catch (e) {
      debugPrint('Error saving preferences to backend: $e');
    }
  }

  void _showEditPreferenceDialog(String title, String currentValue, Function(String) onSaved) {
    String selectedValue = currentValue;
    
    List<String> options = title == 'Primary Language' 
        ? ['German', 'English', 'Spanish', 'French'] 
        : ['Relaxed', 'Moderate', 'Intensive'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D24),
        title: Text('Edit $title', style: const TextStyle(color: Colors.white)),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((option) {
              return RadioListTile<String>(
                title: Text(option, style: const TextStyle(color: Colors.white)),
                value: option,
                groupValue: selectedValue,
                activeColor: const Color(0xFFD4AF37),
                onChanged: (value) {
                  setDialogState(() {
                    selectedValue = value!;
                  });
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
            onPressed: () async {
              onSaved(selectedValue);
              Navigator.pop(context);

              if (title == 'Primary Language') {
                await _updateBackendPreferences(selectedValue, _learningPace);
              } else {
                await _updateBackendPreferences(_primaryLanguage, selectedValue);
              }
            },
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = supabase.auth.currentUser?.email ?? 'No active session';

    return Scaffold(
      backgroundColor: const Color(0xFF121418),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D24),
        title: const Text('Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Account', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: const Color(0xFF1A1D24), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Email', style: TextStyle(color: Colors.white, fontSize: 15)),
                      Text(userEmail, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                
                // Change Password Action
                _buildSettingsItem('Change Password', onTap: () async {
                  final email = supabase.auth.currentUser?.email;
                  if (email != null) {
                    try {
                      await supabase.auth.resetPasswordForEmail(email);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password reset email sent! Check your inbox.')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  }
                }),

                // Manage Subscription Action
                _buildSettingsItem('Manage Subscription', onTap: () async {
                  final Uri url = Uri.parse('https://billing.stripe.com/p/login/your_portal_link');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open subscription management portal.')),
                      );
                    }
                  }
                }),

                const SizedBox(height: 20),
                const Text('Learning Preferences', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                
                // Interactive Editable Preference Rows
                _buildEditablePreferenceRow('Primary Language', _primaryLanguage, (newValue) {
                  setState(() => _primaryLanguage = newValue);
                }),
                _buildEditablePreferenceRow('Learning Pace', _learningPace, (newValue) {
                  setState(() => _learningPace = newValue);
                }),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B0000), 
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      await supabase.auth.signOut();
                    },
                    child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
    );
  }

  // Wrapped in Material widget to provide proper background context and ink splash targets for ListTiles
  Widget _buildSettingsItem(String title, {required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildEditablePreferenceRow(String title, String value, Function(String) onSaved) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              const Icon(Icons.edit, color: Colors.grey, size: 16),
            ],
          ),
          onTap: () => _showEditPreferenceDialog(title, value, onSaved),
        ),
      ),
    );
  }
}