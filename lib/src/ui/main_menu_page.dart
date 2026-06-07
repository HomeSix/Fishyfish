import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_page.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  bool _isPlayHovered = false;

  Future<void> _startGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fishyfish_save_data');
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GamePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.displaySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ) ??
        const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        );

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_mainPage.png',
              fit: BoxFit.cover,
            ),
          ),
          // Positioned.fill(
          //   child: DecoratedBox(
          //     decoration: const BoxDecoration(
          //       gradient: LinearGradient(
          //         colors: [Color(0xCC0B2630), Color(0xCC123C4B)],
          //         begin: Alignment.topLeft,
          //         end: Alignment.bottomRight,
          //       ),
          //     ),
          //   ),
          // ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('FishyFish', style: titleStyle),
                      const SizedBox(height: 24),
                      MouseRegion(
                        onEnter: (_) => setState(() => _isPlayHovered = true),
                        onExit: (_) => setState(() => _isPlayHovered = false),
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _startGame,
                          child: AnimatedScale(
                            scale: _isPlayHovered ? 1.08 : 1.0,
                            duration: const Duration(milliseconds: 140),
                            curve: Curves.easeOut,
                            child: Image.asset(
                              'assets/images/playBtn.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
