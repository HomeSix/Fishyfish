import 'package:flutter/material.dart';
import '../game.dart';

class WelcomePopup extends StatelessWidget {
  final FishyFishGame game;
  const WelcomePopup({super.key, required this.game});

  static const _text = '''Dahulu, lautan dikenali sebagai “Laut Biru Abadi” — tempat yang penuh dengan kehidupan, warna, dan keseimbangan antara manusia dan alam. Ikan-ikan berenang bebas, terumbu karang berkembang, dan hidupan laut hidup harmoni.

Namun, lama-kelamaan, manusia mula mencemarkan laut dengan pelbagai bahan buangan — plastik, sisa toksik, dan sampah sarap. Laut yang dulunya jernih kini semakin keruh. Banyak hidupan laut jatuh sakit, habitat musnah, dan ada yang hampir pupus.

Pemain mengambil peranan sebagai seorang penyelam muda yang berani, dihantar untuk meneroka dan memulihkan lautan. Setiap kali menyelam, pemain akan menemui pelbagai “sea stuff” yang yang masih hidup dan perlukan bantuan, ada juga yang telah rosak akibat pencemaran.

Sepanjang perjalanan, pemain akan:

- Membersihkan ikan dan membantu hidupan laut yang terjejas
- Mengutip dan mengurus bahan buangan dengan betul
- Belajar tentang jenis sampah dan kesannya terhadap alam
- Meneroka kawasan laut berbeza yang semakin terjejas

Namun, semakin dalam pemain menyelam, semakin jelas bahawa kerosakan ini bukan sesuatu yang kecil. Laut sedang “sakit”, dan hanya dengan usaha berterusan, keseimbangan itu boleh dikembalikan.

Matlamat utama pemain bukan sekadar untuk bermain, tetapi untuk memulihkan Laut Biru Abadi dan mengembalikan harapan kepada semua hidupan laut.''';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 620),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1724),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: Column(
              children: [
                const Text(
                  'Welcome to Fishyfish',
                  style: TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      _text,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        game.overlays.remove('WelcomePopup');
                      },
                      child: const Text('Close', style: TextStyle(color: Colors.white70)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
