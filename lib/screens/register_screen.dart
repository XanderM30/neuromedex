import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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
                      // Logo
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

                      // Título
                      Text(
                        "Registro",
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
                      const SizedBox(height: 30),

                      // Campos de registro
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          children: [
                            TextField(
                              controller: _nameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "Nombre completo",
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
                                  Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
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
                            const SizedBox(height: 15),
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
                            const SizedBox(height: 15),
                            TextField(
                              controller: _confirmController,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "Confirmar contraseña",
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
                                  Icons.lock_outline,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Botón registrar
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Lógica de registro
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade400,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 5,
                                ),
                                child: const Text(
                                  "Registrar",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Botón regresar a login
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                "¿Ya tienes una cuenta? Inicia sesión",
                                style: TextStyle(
                                  color: Colors.tealAccent.withAlpha(180),
                                ),
                              ),
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
      ),
    );
  }
}
