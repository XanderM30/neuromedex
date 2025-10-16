import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _dropController;
  late AnimationController _pulseController;
  late AnimationController _expandController;
  late AnimationController _gradientController;
  late Animation<double> _dropAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeTextAnimation;
  late Animation<Color?> _backgroundAnimation;

  bool _showText = false;
  final List<Offset> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Animación de caída
    _dropController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _dropAnimation = Tween<double>(begin: -100, end: 0).animate(
      CurvedAnimation(parent: _dropController, curve: Curves.bounceOut),
    );

    // Animación de "latido" individual tipo corazón
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pulseAnimation = Tween<double>(begin: 75, end: 100).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Expansión de bolita
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _expandAnimation = Tween<double>(begin: 75, end: 1000).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeInOutCubic),
    );

    // Texto fade + scale
    _fadeTextAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeInOut),
    );

    // Fondo animado (gradiente pastel)
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _backgroundAnimation = ColorTween(
      begin: Colors.blueGrey.shade900,
      end: Colors.teal.shade300,
    ).animate(_gradientController);

    // Inicializar partículas
    _generateParticles();

    // Secuencia de animaciones
    _dropController.forward().whenComplete(() async {
      // Latidos uno por uno tipo corazón
      for (int i = 0; i < 4; i++) {
        await _pulseController.forward();
        await _pulseController.reverse();
        await Future.delayed(const Duration(milliseconds: 150));
      }

      _expandController.forward().whenComplete(() {
        setState(() {
          _showText = true;
        });
        Timer(const Duration(seconds: 2), () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        });
      });
    });
  }

  void _generateParticles() {
    for (int i = 0; i < 30; i++) {
      _particles.add(Offset(_random.nextDouble(), _random.nextDouble()));
    }
  }

  @override
  void dispose() {
    _dropController.dispose();
    _pulseController.dispose();
    _expandController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _dropController,
        _pulseController,
        _expandController,
        _gradientController,
      ]),
      builder: (context, child) {
        final size = MediaQuery.of(context).size;
        final centerY = size.height / 2 - _expandAnimation.value / 2;
        final ballSize = _pulseController.isAnimating
            ? _pulseAnimation.value
            : _expandController.isAnimating
            ? _expandAnimation.value
            : 75.0;

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black,
                  _backgroundAnimation.value ?? Colors.black,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Partículas en movimiento
                ..._particles.map((p) {
                  final dx = p.dx * size.width;
                  final dy = (p.dy * size.height - 0.3) % size.height;
                  return Positioned(
                    left: dx,
                    top: dy,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.tealAccent.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),

                // Bolita con gradiente radial
                Positioned(
                  top: _dropAnimation.value + centerY,
                  child: Container(
                    width: ballSize,
                    height: ballSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Colors.teal.shade400, Colors.teal.shade900],
                        center: Alignment(-0.2, -0.2),
                        radius: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.tealAccent.shade100.withValues(
                            alpha: 0.6,
                          ),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),

                // Texto animado fade + scale
                if (_showText || _expandAnimation.value > 200)
                  Center(
                    child: FadeTransition(
                      opacity: _fadeTextAnimation,
                      child: ScaleTransition(
                        scale: _fadeTextAnimation,
                        child: Text(
                          "NeuroMedX",
                          style: GoogleFonts.lobster(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.teal.shade400,
                                offset: const Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
