import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String _userName = "Usuario";
  late AnimationController _gradientController;
  late Animation<Color?> _backgroundAnimation;

  late AnimationController _greetingController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userName = user.displayName ?? user.email?.split("@")[0] ?? "Usuario";
    }

    // Animación de fondo degradado
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _backgroundAnimation = ColorTween(
      begin: Colors.black,
      end: Colors.teal.shade900,
    ).animate(_gradientController);

    // Animación del saludo
    _greetingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.3), // empieza un poco abajo
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _greetingController, curve: Curves.easeOut),
        );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_greetingController);

    _greetingController.forward();
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _greetingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _gradientController,
      builder: (context, child) {
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black,
                  _backgroundAnimation.value ?? Colors.teal.shade900,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Saludo animado
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Text(
                          'Hola,\n$_userName',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lobster(
                            fontSize: 36,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Dashboard horizontal con Lottie
                    SizedBox(
                      height: 180,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildDashboardCard(
                            title: 'Medicación',
                            color: Colors.deepPurple,
                            lottie: 'assets/lottie/Pills.json',
                          ),
                          _buildDashboardCard(
                            title: 'Monitoreo',
                            color: Colors.teal,
                            lottie: 'assets/lottie/Heart.json',
                          ),
                          _buildDashboardCard(
                            title: 'Citas',
                            color: Colors.orange,
                            lottie: 'assets/lottie/Calendar.json',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Grid con tarjetas verticales
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        children: [
                          _buildFeatureCard(
                            'Reportes',
                            Colors.pink,
                            'assets/lottie/Reports.json',
                          ),
                          _buildFeatureCard(
                            'Recordatorios',
                            Colors.indigo,
                            'assets/lottie/Notification.json',
                          ),
                          _buildFeatureCard(
                            'Perfil',
                            Colors.cyan,
                            'assets/lottie/Profile.json',
                          ),
                          _buildFeatureCard(
                            'Funciones Avanzadas',
                            Colors.amber,
                            'assets/lottie/Configuracion.json',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Dashboard horizontal
  Widget _buildDashboardCard({
    required String title,
    required Color color,
    required String lottie,
  }) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Lottie.asset(lottie, repeat: true, fit: BoxFit.contain),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tarjetas verticales del grid
  Widget _buildFeatureCard(String title, Color color, String lottie) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      color: color.withOpacity(0.85),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Lottie.asset(lottie, repeat: true, fit: BoxFit.contain),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
