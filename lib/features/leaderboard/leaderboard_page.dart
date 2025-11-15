import 'package:flutter/material.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final users = [
      {'name': 'Amy', 'score': 120, 'level': 'Expert', 'streak': 15},
      {'name': 'Ben', 'score': 98, 'level': 'Advanced', 'streak': 12},
      {'name': 'Cara', 'score': 75, 'level': 'Intermediate', 'streak': 8},
      {'name': 'David', 'score': 62, 'level': 'Beginner', 'streak': 5},
      {'name': 'Emma', 'score': 55, 'level': 'Beginner', 'streak': 3},
      {'name': 'Frank', 'score': 48, 'level': 'Beginner', 'streak': 2},
      {'name': 'Grace', 'score': 42, 'level': 'Beginner', 'streak': 1},
    ];

    final colors = [
      [Color(0xFFFFD700), Color(0xFFFFC700)], // Gold
      [Color(0xFFC0C0C0), Color(0xFF808080)], // Silver
      [Color(0xFFCD7F32), Color(0xFFB87333)], // Bronze
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Leaderboard'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4ECDC4), Color(0xFF81E6D9)],
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
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top Performers',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Weekly rankings',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  // Top 3 podium
                  SizedBox(
                    height: 220,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _PodiumItem(
                          rank: 2,
                          name: users[1]['name'] as String,
                          score: users[1]['score'] as int,
                          streak: users[1]['streak'] as int,
                          height: 140,
                          gradient: colors[1],
                        ),
                        SizedBox(width: 8),
                        _PodiumItem(
                          rank: 1,
                          name: users[0]['name'] as String,
                          score: users[0]['score'] as int,
                          streak: users[0]['streak'] as int,
                          height: 200,
                          gradient: colors[0],
                        ),
                        SizedBox(width: 8),
                        _PodiumItem(
                          rank: 3,
                          name: users[2]['name'] as String,
                          score: users[2]['score'] as int,
                          streak: users[2]['streak'] as int,
                          height: 100,
                          gradient: colors[2],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  Text(
                    'All Rankings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  ...users.asMap().entries.map((entry) {
                    int idx = entry.key;
                    Map user = entry.value;
                    bool isTopThree = idx < 3;

                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: isTopThree
                            ? Color(0xFFFFF3E0).withOpacity(0.5)
                            : Colors.white,
                        border: Border.all(
                          color: isTopThree
                              ? Color(0xFFFFA500).withOpacity(0.3)
                              : Colors.grey.withOpacity(0.1),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${user['name']} - Level: ${user['level']} (${user['streak']} day streak)',
                                ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: idx < 3
                                        ? LinearGradient(colors: colors[idx])
                                        : LinearGradient(
                                      colors: [
                                        Color(0xFF4ECDC4),
                                        Color(0xFF81E6D9),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (idx < 3
                                            ? colors[idx][0]
                                            : Color(0xFF4ECDC4))
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${idx + 1}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user['name'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Color(0xFF4ECDC4).withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              user['level'],
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF4ECDC4),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.local_fire_department, size: 14, color: Color(0xFFFF6B6B)),
                                          SizedBox(width: 4),
                                          Text(
                                            '${user['streak']} days',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFFFF6B6B),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isTopThree
                                        ? Color(0xFFFFA500).withOpacity(0.2)
                                        : Color(0xFF4ECDC4).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${user['score']} pts',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isTopThree
                                          ? Color(0xFFFFA500)
                                          : Color(0xFF4ECDC4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final int rank;
  final String name;
  final int score;
  final int streak;
  final double height;
  final List<Color> gradient;

  const _PodiumItem({
    required this.rank,
    required this.name,
    required this.score,
    required this.streak,
    required this.height,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: gradient),
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withOpacity(0.4),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              rank.toString(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '$score pts',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF757575),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_fire_department, size: 12, color: Color(0xFFFF6B6B)),
              SizedBox(width: 2),
              Text(
                '$streak',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFFFF6B6B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            width: 100,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}