import 'package:flutter/material.dart';

class GapFillingPage extends StatefulWidget {
  const GapFillingPage({super.key});

  @override
  State<GapFillingPage> createState() => _GapFillingPageState();
}

class _GapFillingPageState extends State<GapFillingPage> {
  final _controller = TextEditingController();
  final String _correctAnswer = 'school';
  String? _result;
  bool? _isCorrect;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gap Filling Assessment'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF4ECDC4).withOpacity(0.1),
                        Color(0xFF4ECDC4).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Color(0xFF4ECDC4).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Complete the sentence',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Color(0xFF4ECDC4),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'I am going to ____',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Colors.black87,
                          fontSize: 28,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40),
                TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Type your answer here',
                    prefixIcon: Icon(Icons.edit_outlined, color: Color(0xFF4ECDC4)),
                  ),
                  onChanged: (_) => setState(() => _result = null),
                ),
                SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        if (_controller.text.trim().toLowerCase() == _correctAnswer) {
                          _result = 'Correct!';
                          _isCorrect = true;
                        } else {
                          _result = 'Try again!';
                          _isCorrect = false;
                        }
                      });
                    },
                    icon: Icon(Icons.check_circle_outline, size: 24),
                    label: Text('Check Answer'),
                  ),
                ),
                if (_result != null)
                  Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _isCorrect == true
                            ? Color(0xFF6BCB77).withOpacity(0.15)
                            : Color(0xFFFF6B6B).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isCorrect == true
                              ? Color(0xFF6BCB77)
                              : Color(0xFFFF6B6B),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isCorrect == true
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: _isCorrect == true
                                ? Color(0xFF6BCB77)
                                : Color(0xFFFF6B6B),
                            size: 32,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _result!,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _isCorrect == true
                                        ? Color(0xFF6BCB77)
                                        : Color(0xFFFF6B6B),
                                  ),
                                ),
                                if (_isCorrect == false)
                                  Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Text(
                                      'The correct answer is: $_correctAnswer',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFFFF6B6B),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}