import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------
// 0. MAIN APPLICATION ENTRY POINT
// ---------------------------------------------------------
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Language Tutor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121418),
      ),
      // Set MainNavigationShell as the root widget
      home: const MainNavigationShell(),
    );
  }
}

// ---------------------------------------------------------
// 1. MAIN NAVIGATION CONTAINER (Connects Home, Practice, Settings)
// ---------------------------------------------------------
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 1; // Default to Practice tab

  // List of interconnected root screens
  final List<Widget> _screens = [
    const HomeScreen(),
    const PracticeDashboardScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1D24),
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Text('⌂', style: TextStyle(fontSize: 20)),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Text('🗣️', style: TextStyle(fontSize: 20)),
            label: 'Practice',
          ),
          BottomNavigationBarItem(
            icon: Text('⚙️', style: TextStyle(fontSize: 20)),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// 2. HOME SCREEN (Interconnected Page Placeholder)
// ---------------------------------------------------------
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121418),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D24),
        title: const Text('Home Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: const Center(
        child: Text(
          'Welcome to AI Language Tutor Home!',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 3. SETTINGS SCREEN (Interconnected Page Placeholder)
// ---------------------------------------------------------
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121418),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D24),
        title: const Text('Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: const Center(
        child: Text(
          'App Configuration & Preferences',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 4. PRACTICE DASHBOARD SCREEN WITH GROQ DYNAMIC AI QUIZ
// ---------------------------------------------------------
class PracticeDashboardScreen extends StatefulWidget {
  const PracticeDashboardScreen({super.key});

  @override
  State<PracticeDashboardScreen> createState() => _PracticeDashboardScreenState();
}

class _PracticeDashboardScreenState extends State<PracticeDashboardScreen> {
  bool _isLoading = true;
  bool _isFlashcardLoading = false;
  int _totalSessions = 0;
  
  // Dynamic flashcard state
  Map<String, dynamic> _activeFlashcard = {
    "word": "Feierabend",
    "level": "A2",
    "definition": "The end of the workday or evening relaxation."
  };

  // Groq Dynamic Quiz State
  bool _isQuizLoading = false;
  Map<String, dynamic> _activeQuiz = {
    "question": "Loading AI Quiz Challenge...",
    "options": ["Loading..."],
    "answer": "",
    "explanation": ""
  };
  
  String? _selectedAnswer;
  bool? _isAnswerCorrect;

  @override
  void initState() {
    super.initState();
    _fetchProgressData();
    _fetchAiQuiz(); // Fetches live from Groq when the dashboard opens
  }

  Future<void> _fetchProgressData() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/v1/tutor/progress'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        setState(() {
          _totalSessions = jsonResponse['total_sessions'] ?? 0;
          if (jsonResponse['flashcard'] != null) {
            _activeFlashcard = jsonResponse['flashcard'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching dashboard progress: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch a new AI-generated word from the backend endpoint
  Future<void> _fetchNewFlashcard() async {
    setState(() {
      _isFlashcardLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/v1/tutor/random-flashcard'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        setState(() {
          _activeFlashcard = {
            "word": jsonResponse['word'] ?? "Wunderkind",
            "level": jsonResponse['level'] ?? "B1",
            "definition": jsonResponse['definition'] ?? "A person who achieves success at an early age."
          };
          _isFlashcardLoading = false;
        });
      } else {
        setState(() => _isFlashcardLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching dynamic flashcard: $e');
      setState(() => _isFlashcardLoading = false);
    }
  }

  // Fetch a new AI-generated quiz question from the Groq FastAPI endpoint
  Future<void> _fetchAiQuiz() async {
    setState(() {
      _isQuizLoading = true;
      _selectedAnswer = null;
      _isAnswerCorrect = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/v1/tutor/random-quiz'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        setState(() {
          _activeQuiz = {
            "question": jsonResponse['question'] ?? "Complete: Das Buch ___ interessant.",
            "options": jsonResponse['options'] ?? ["ist", "sind", "hat"],
            "answer": jsonResponse['answer'] ?? "ist",
            "explanation": jsonResponse['explanation'] ?? "Singular noun takes 'ist'."
          };
          _isQuizLoading = false;
        });
      } else {
        setState(() => _isQuizLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching AI quiz from backend: $e');
      setState(() => _isQuizLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double progressPercent = min(_totalSessions * 20.0, 100.0);

    return Scaffold(
      backgroundColor: const Color(0xFF121418),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D24),
        title: const Text('Practice Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD4AF37),
            ),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Log Out'),
            onPressed: () async {
              try {
                await Supabase.instance.client.auth.signOut();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error logging out: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. DYNAMIC ODOMETER PROGRESS CARD
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A1D24), Color(0xFF222630)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: _totalSessions == 0 ? 0.05 : (progressPercent / 100),
                                strokeWidth: 8,
                                backgroundColor: Colors.black45,
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                              ),
                              Center(
                                child: Text(
                                  '$_totalSessions',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Session Odometer',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_totalSessions completed session logs',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Active Streak On Track 🔥',
                                  style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'AI-Generated Vocabulary Card',
                          style: TextStyle(
                            color: Colors.white, 
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _isFlashcardLoading ? null : _fetchNewFlashcard,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('✨', style: TextStyle(fontSize: 13)),
                            SizedBox(width: 4),
                            Text(
                              'Next AI Word', 
                              style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // 2. INTERACTIVE AI FLASHCARD TILE
                  GestureDetector(
                    onTap: _isFlashcardLoading ? null : _fetchNewFlashcard,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1F242D), Color(0xFF161920)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                            blurRadius: 15,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: _isFlashcardLoading
                          ? const SizedBox(
                              height: 120,
                              child: Center(
                                child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD4AF37),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Level: ${_activeFlashcard['level']}',
                                        style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: Center(
                                        child: Text(
                                          '🔄',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _activeFlashcard['word']!,
                                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _activeFlashcard['definition']!,
                                  style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 28),
                  
                  // 3. GROQ AI QUICK-FIRE QUIZ CHALLENGE SECTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'AI Quick-Fire Quiz 🔥',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: _isQuizLoading ? null : _fetchAiQuiz,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('✨', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 4),
                            Text(
                              'New AI Quiz',
                              style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Groq AI Quiz Card Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1D24),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: _isQuizLoading
                        ? const SizedBox(
                            height: 140,
                            child: Center(
                              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _activeQuiz['question'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Loop through options dynamically returned from Groq
                              ...((_activeQuiz['options'] as List<dynamic>? ?? []).map((option) {
                                String optionStr = option.toString();
                                bool isSelected = _selectedAnswer == optionStr;
                                Color buttonColor = const Color(0xFF222630);
                                Color borderColor = Colors.white10;

                                if (_selectedAnswer != null) {
                                  if (optionStr == _activeQuiz['answer']) {
                                    buttonColor = Colors.green.withValues(alpha: 0.2);
                                    borderColor = Colors.green;
                                  } else if (isSelected) {
                                    buttonColor = Colors.red.withValues(alpha: 0.2);
                                    borderColor = Colors.red;
                                  }
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: buttonColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: BorderSide(color: borderColor, width: 1.5),
                                        ),
                                      ),
                                      onPressed: _selectedAnswer != null 
                                          ? null 
                                          : () {
                                              setState(() {
                                                _selectedAnswer = optionStr;
                                                _isAnswerCorrect = (optionStr == _activeQuiz['answer']);
                                              });
                                            },
                                      child: Text(
                                        optionStr,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                );
                              })),

                              // Instant Feedback & Next Challenge Action
                              if (_selectedAnswer != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _isAnswerCorrect! 
                                      ? '🎉 Correct! Well done.' 
                                      : '❌ Incorrect. ${_activeQuiz['explanation'] ?? ""}',
                                  style: TextStyle(
                                    color: _isAnswerCorrect! ? Colors.greenAccent : Colors.redAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _fetchAiQuiz,
                                    child: const Text(
                                      'Next AI Challenge ➡️',
                                      style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}