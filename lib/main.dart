import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'src/ui/main_menu_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const FishyFishApp());
}

class FishyFishApp extends StatelessWidget {
  const FishyFishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FishyFish',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1B7C8C),
      ),
      home: const MainMenuPage(),
    );
  }
}