import 'package:flutter/material.dart';

void main() {
  runApp(const ScaleBuddyApp());
}

class ScaleBuddyApp extends StatelessWidget {
  const ScaleBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScaleBuddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5), // Blau akzentuiert
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9), // Helles Slate-Grau
      ),
      home: const MainLayoutScreen(),
    );
  }
}

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Obere Leiste (AppBar) mit Titel und globalen Aktionen
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.architecture,
                color: Theme.of(context).colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ScaleBuddy',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Screen-Bauzeichnungs-Messtool',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Beispiel-Aktionsbuttons für die Desktop-Top-Leiste
          FilledButton.tonalIcon(
            onPressed: () {},
            icon: const Icon(Icons.crop, size: 18),
            label: const Text('Weitere Messung'),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Verkleinern (Zoom -)',
            icon: const Icon(Icons.zoom_out),
            onPressed: () {},
          ),
          IconButton(
            tooltip: 'Vergrößern (Zoom +)',
            icon: const Icon(Icons.zoom_in),
            onPressed: () {},
          ),
          const SizedBox(width: 12),
        ],
      ),

      // Hauptbereich: Aufgeteilt in linke Sidebar und rechte Arbeitsfläche
      body: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. LINKE SIDEBAR (Feste Breite für die 4 Menüpunkte)
                Container(
                  width: 300,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      right: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sidebar-Kopfbereich
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ARBEITSABLAUF',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Folge den 4 Schritten von oben nach unten.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),

                      // Platzhalter für Schritt 2 (wird im nächsten Schritt befüllt)
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Platzhalter:\nHier entstehen die 4 Workflow-Menüs\n(Schritt 2)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. RECHTER ARBEITSBEREICH (Canvas / Zeichenfläche)
                Expanded(
                  child: Container(
                    color: const Color(0xFF1E293B), // Dunkler CAD-Hintergrund für Zeichnungen
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_search,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Arbeitsbereich / Canvas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hier wird später das Bild, die Entzerrung und die Messung angezeigt.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. UNTERE STATUSLEISTE (StatusBar)
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, size: 14, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(
                  'Bereit.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
                const Spacer(),
                Text(
                  'Maßstab: Nicht kalibriert  |  Zoom: 100%',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
