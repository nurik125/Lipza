import 'package:flutter/material.dart';
import 'features/leaderboard/leaderboard_page.dart';
// import 'features/practice/practice_page.dart';
import 'features/teaching/teaching_page.dart';
import 'features/silent_detecting/silent_detecting_page.dart';
import 'features/assessment/gap_filling_page.dart';

void main() {
  runApp(LipzaApp());
}

// Duolingo-inspired color scheme
class LipzaColors {
  static const Color primary = Color(0xFF1F1F1F); // Dark background
  static const Color accent1 = Color(0xFFFF6B6B); // Vibrant pink
  static const Color accent2 = Color(0xFFFFA500); // Orange
  static const Color accent3 = Color(0xFF4ECDC4); // Teal
  static const Color accent4 = Color(0xFFFFD93D); // Yellow
  static const Color accent5 = Color(0xFF6BCB77); // Green
  static const Color background = Color(0xFFFAFAFA); // Light background
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color text = Color(0xFF1F1F1F); // Dark text
  static const Color textLight = Color(0xFF757575); // Light text
}

class LipzaApp extends StatelessWidget {
  const LipzaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lipza',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: LipzaColors.accent1,
        scaffoldBackgroundColor: LipzaColors.background,
        appBarTheme: AppBarTheme(
          backgroundColor: LipzaColors.surface,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: LipzaColors.text,
          ),
          iconTheme: IconThemeData(color: LipzaColors.text),
        ),
        useMaterial3: true,
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: LipzaColors.text,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: LipzaColors.text,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: LipzaColors.text,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: LipzaColors.textLight,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: LipzaColors.accent1,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 4,
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: LipzaColors.surface,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: LipzaColors.accent1, width: 2),
          ),
          hintStyle: TextStyle(color: LipzaColors.textLight),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LipzaHomePage(),
      routes: {
        '/leaderboard': (_) => LeaderboardPage(),
        // '/practice': (_) => PracticePage(),
        '/teaching': (_) => TeachingPage(),
        '/silent-detecting': (_) => SilentDetectingPage(),
        '/gap-filling': (_) => GapFillingPage(),
      },
    );
  }
}

class LipzaHomePage extends StatelessWidget {
  const LipzaHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lipza'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF6B6B), Color(0xFFFF8787)],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAFAFA),
              Color(0xFFF5F5F5),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back!',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Master lip reading with fun lessons',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: LipzaColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    _FeatureTile(
                      label: 'Teaching',
                      icon: Icons.ondemand_video,
                      gradient: LinearGradient(
                        colors: [LipzaColors.accent1, Color(0xFFFF8787)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () => Navigator.pushNamed(context, '/teaching'),
                    ),
                    _FeatureTile(
                      label: 'Practice',
                      icon: Icons.record_voice_over,
                      gradient: LinearGradient(
                        colors: [LipzaColors.accent2, Color(0xFFFFB74D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () => Navigator.pushNamed(context, '/practice'),
                    ),
                    _FeatureTile(
                      label: 'Silent Detecting',
                      icon: Icons.visibility,
                      gradient: LinearGradient(
                        colors: [LipzaColors.accent3, Color(0xFF81E6D9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () => Navigator.pushNamed(context, '/silent-detecting'),
                    ),
                    _FeatureTile(
                      label: 'Gap Filling',
                      icon: Icons.edit,
                      gradient: LinearGradient(
                        colors: [LipzaColors.accent5, Color(0xFF95E1D3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () => Navigator.pushNamed(context, '/gap-filling'),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                _LeaderboardPreview(
                  onTap: () => Navigator.pushNamed(context, '/leaderboard'),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class _FeatureTile extends StatefulWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_FeatureTile> createState() => _FeatureTileState();
}

class _FeatureTileState extends State<_FeatureTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors[0].withOpacity(0.4),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 56, color: Colors.white),
                SizedBox(height: 12),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaderboardPreview extends StatelessWidget {
  final VoidCallback onTap;

  const _LeaderboardPreview({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final topUsers = [
      {'name': 'Amy', 'score': 120},
      {'name': 'Ben', 'score': 98},
    ];

    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                LipzaColors.accent4.withOpacity(0.1),
                LipzaColors.accent4.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Top Performers',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Icon(Icons.arrow_forward, color: LipzaColors.textLight),
                  ],
                ),
                SizedBox(height: 16),
                ...topUsers.asMap().entries.map((entry) {
                  int idx = entry.key;
                  Map user = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [LipzaColors.accent1, LipzaColors.accent2],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${idx + 1}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            user['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: LipzaColors.accent4.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${user['score']} pts',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: LipzaColors.accent1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 