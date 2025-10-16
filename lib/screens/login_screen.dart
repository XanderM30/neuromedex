import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'register_screen.dart'; // pantalla de registro

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black, Colors.teal.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SingleChildScrollView(
                child: SizedBox(
                  height: size.height,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo / icono
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.teal.shade400,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.tealAccent.shade100.withAlpha(150),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.medical_services,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Título de la app
                      Text(
                        "NeuroMedX",
                        style: GoogleFonts.lobster(
                          fontSize: 40,
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
                      const SizedBox(height: 40),

                      // Campos de login
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          children: [
                            TextField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "Correo electrónico",
                                hintStyle: TextStyle(
                                  color: Colors.white.withAlpha(150),
                                ),
                                filled: true,
                                fillColor: Colors.teal.shade700.withAlpha(100),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(
                                  Icons.email,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "Contraseña",
                                hintStyle: TextStyle(
                                  color: Colors.white.withAlpha(150),
                                ),
                                filled: true,
                                fillColor: Colors.teal.shade700.withAlpha(100),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Botón de login
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Lógica de login
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade400,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 5,
                                ),
                                child: const Text(
                                  "Iniciar sesión",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),

                            // Botón de crear cuenta
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Colors.tealAccent,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  "Crear cuenta",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.tealAccent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      // Texto secundario
                      Text(
                        "¿Olvidaste tu contraseña?",
                        style: TextStyle(
                          color: Colors.white.withAlpha(150),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
