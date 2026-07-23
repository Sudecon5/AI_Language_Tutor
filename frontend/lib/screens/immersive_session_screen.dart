import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'dart:convert';
import 'practice_dashboard_screen.dart';

class ImmersiveSessionScreen extends StatefulWidget {
  final String tutorName;
  final String tutorExpertise;

  const ImmersiveSessionScreen({
    super.key,
    required this.tutorName,
    required this.tutorExpertise,
  });

  @override
  State<ImmersiveSessionScreen> createState() => _ImmersiveSessionScreenState();
}

class _ImmersiveSessionScreenState extends State<ImmersiveSessionScreen> {
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  bool _isLoading = false;

  // Stores conversation history including feedback corrections
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    // Initial welcome message from the tutor persona
    _messages.add({
      'sender': 'tutor',
      'reply': 'Hallo! I am ${widget.tutorName}. Let\'s practice ${widget.tutorExpertise}. Erzähl mir mal auf Deutsch!',
      'correction': null,
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  // 1. Start capturing microphone input
  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(
          const RecordConfig(), // Cleaned up to use default encoder configuration
          path: '',
        );
        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
    }
  }

  // 2. Stop recording and upload the audio file to FastAPI backend
  Future<void> _stopRecordingAndSend() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isLoading = true;
      });

      if (path != null) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://localhost:8000/api/v1/tutor/chat'),
        );

        if (kIsWeb) {
          final blobResponse = await http.get(Uri.parse(path));
          final audioBytes = blobResponse.bodyBytes;

          request.files.add(
            http.MultipartFile.fromBytes(
              'file',
              audioBytes,
              filename: 'audio_recording.webm',
            ),
          );
        } else {
          request.files.add(await http.MultipartFile.fromPath('file', path));
        }

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          var jsonResponse = jsonDecode(response.body);
          var data = jsonResponse['data'];

          String userTranscription = data['transcription'] ?? '';
          String tutorReply = data['reply'] ?? '';
          String? correction = data['correction'];

          setState(() {
            // Append user spoken transcript
            if (userTranscription.isNotEmpty) {
              _messages.add({
                'sender': 'user',
                'reply': userTranscription,
                'correction': null,
              });
            }
            // Append tutor reply and optional grammar correction feedback
            _messages.add({
              'sender': 'tutor',
              'reply': tutorReply,
              'correction': (correction != null && correction != 'None') ? correction : null,
            });
          });
        }
      }
    } catch (e) {
      debugPrint('Error uploading audio: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121418),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D24),
        leading: IconButton(
          icon: const Text('⬅️', style: TextStyle(fontSize: 28)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.tutorName, style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Text('📈', style: TextStyle(fontSize: 28)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PracticeDashboardScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat conversation list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                bool isUser = msg['sender'] == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFFD4AF37) : const Color(0xFF1A1D24),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['reply'],
                          style: TextStyle(
                            color: isUser ? Colors.black : Colors.white,
                            fontSize: 15,
                          ),
                        ),
                        // Render optional grammar/spelling correction feedback if provided by Llama
                        if (msg['correction'] != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFD4AF37), width: 0.5),
                            ),
                            child: Text(
                              '💡 Correction: ${msg['correction']}',
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            ),
          
          // Audio Recording control bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            color: const Color(0xFF1A1D24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _isRecording ? _stopRecordingAndSend : _startRecording,
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording ? Colors.red : const Color(0xFFD4AF37),
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : const Color(0xFFD4AF37)).withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      _isRecording ? '⏹️' : '🎙️',
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}