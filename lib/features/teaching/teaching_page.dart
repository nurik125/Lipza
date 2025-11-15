import 'package:flutter/material.dart';

class TeachingPage extends StatelessWidget {
  const TeachingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teaching Materials'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFA500), Color(0xFFFFB74D)],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFAFAFA), Color(0xFFF5F5F5)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Learn Lip Reading',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Master basic phrases and common words',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              _TeachingItem(word: 'Hello', hint: 'hel-OH', description: 'Common greeting', videoPath: 'assets/videos/hello.mp4', index: 0),
              _TeachingItem(word: 'Goodbye', hint: 'good-BYE', description: 'Farewell expression', videoPath: 'assets/videos/goodbye.mp4', index: 1),
              _TeachingItem(word: 'Thank You', hint: 'THANK you', description: 'Show gratitude', videoPath: 'assets/videos/thank_you.mp4', index: 2),
              _TeachingItem(word: 'Please', hint: 'PLEASE', description: 'Make a request politely', videoPath: 'assets/videos/please.mp4', index: 3),
              _TeachingItem(word: 'Water', hint: 'WAH-ter', description: 'Common beverage', videoPath: 'assets/videos/water.mp4', index: 4),
              _TeachingItem(word: 'Coffee', hint: 'COP-fee', description: 'Popular drink', videoPath: 'assets/videos/coffee.mp4', index: 5),
              _TeachingItem(word: 'Smile', hint: 'SMILE', description: 'Show happiness', videoPath: 'assets/videos/smile.mp4', index: 6),
              _TeachingItem(word: 'Help', hint: 'HELP', description: 'Ask for assistance', videoPath: 'assets/videos/help.mp4', index: 7),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeachingItem extends StatefulWidget {
  final String word;
  final String hint;
  final String description;
  final String videoPath;
  final int index;

  const _TeachingItem({
    required this.word,
    required this.hint,
    required this.description,
    required this.videoPath,
    required this.index,
  });

  @override
  State<_TeachingItem> createState() => _TeachingItemState();
}

class _TeachingItemState extends State<_TeachingItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = [
      Color(0xFFFF6B6B),
      Color(0xFFFFA500),
      Color(0xFF4ECDC4),
      Color(0xFF6BCB77),
    ];

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value, 0),
          child: Opacity(
            opacity: _controller.value,
            child: child,
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.only(bottom: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [colors[widget.index % colors.length], colors[widget.index % colors.length].withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Playing video: ${widget.videoPath}'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.play_circle_filled,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.word,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Pronunciation: ${widget.hint}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            widget.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap to watch video',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.6),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}