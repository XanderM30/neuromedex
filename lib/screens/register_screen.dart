import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _errorMessage;
  bool _isLoading = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  // 🔹 Función de registro
  Future<void> _register() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    if (_passwordController.text != _confirmController.text) {
      setState(() {
        _errorMessage = "⚠️ Las contraseñas no coinciden";
        _isLoading = false;
      });
      return;
    }

    // 🔹 Verificación de conexión correcta
    var connectivityResult = await Connectivity().checkConnectivity();
    // ignore: unrelated_type_equality_checks
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _errorMessage = "⚠️ No hay conexión a Internet";
        _isLoading = false;
      });
      return;
    }
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final user = userCredential.user;

      // 🔹 Guardar usuario en Firestore
      await _firestore.collection('users').doc(user!.uid).set({
        'uid': user.uid,
        'nombre': _nameController.text.trim(),
        'correo': _emailController.text.trim(),
        'fecha_registro': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Registro exitoso, bienvenido a NeuroMedex"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      // 🔹 Redirige al login
      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'network-request-failed') {
          _errorMessage = "⚠️ No hay conexión a Internet";
        } else if (e.code == 'email-already-in-use') {
          _errorMessage = 'Este correo ya está registrado.';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'Correo electrónico inválido.';
        } else if (e.code == 'weak-password') {
          _errorMessage = 'La contraseña es demasiado débil.';
        } else {
          _errorMessage = 'Error al registrar usuario.';
        }
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage = "⚠️ Ocurrió un error inesperado";
        _isLoading = false;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
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
                            Icons.medical_services_rounded,
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
                              color: Colors.tealAccent.shade100,
                              offset: const Offset(2, 2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Formulario
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _nameController,
                              icon: Icons.person,
                              hint: "Nombre completo",
                            ),
                            const SizedBox(height: 15),
                            _buildTextField(
                              controller: _emailController,
                              icon: Icons.email,
                              hint: "Correo electrónico",
                            ),
                            const SizedBox(height: 15),
                            _buildTextField(
                              controller: _passwordController,
                              icon: Icons.lock,
                              hint: "Contraseña",
                              obscure: true,
                            ),
                            const SizedBox(height: 15),
                            _buildTextField(
                              controller: _confirmController,
                              icon: Icons.lock_outline,
                              hint: "Confirmar contraseña",
                              obscure: true,
                            ),
                            const SizedBox(height: 20),

                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 14,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 10),

                            // Botón Registrar
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade400,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text(
                                        "Registrar",
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Regresar a login
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                "¿Ya tienes cuenta? Inicia sesión",
                                style: TextStyle(
                                  color: Colors.tealAccent.withAlpha(200),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withAlpha(150)),
        filled: true,
        fillColor: Colors.teal.shade700.withAlpha(100),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(icon, color: Colors.white),
      ),
    );
  }
}
