import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String _userName = "Usuario";
  final TextEditingController _symptomController = TextEditingController();
  List<String> _selectedSymptoms = [];

  // Chips de ejemplo
  final List<String> _commonSymptoms = [
    "Fiebre",
    "Dolor de cabeza",
    "Tos",
    "Cansancio",
    "Dolor muscular",
  ];

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

    // Fondo animado turquesa
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _backgroundAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.teal.shade50,
    ).animate(_gradientController);

    // Animación saludo
    _greetingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
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
    _symptomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _gradientController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _backgroundAnimation.value,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 👋 Saludo animado
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Text(
                        "Hola \n$_userName 👋",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtítulo centrado
                  Text(
                    "¿Cómo te sientes hoy?",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.teal.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Campo de síntomas con chips + micrófono
                  _buildSymptomInputWithChips(),

                  const SizedBox(height: 30),

                  // ⚙️ Panel rápido (tarjetas)
                  _buildFeatureGrid(),

                  const SizedBox(height: 30),

                  // 💡 Título del carrusel
                  Text(
                    "Recomendaciones de salud",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 💡 Carrusel de tips desde Firebase
                  _buildTipsCarousel(),

                  const SizedBox(height: 30),

                  // 🤖 Asistente de salud IA
                  _buildHealthAssistantCard(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Campo para ingresar síntomas + chips sugeridos
  Widget _buildSymptomInputWithChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.shade100,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _symptomController,
                  decoration: const InputDecoration(
                    hintText: "Describe tus síntomas...",
                    border: InputBorder.none,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("🎤 Grabación iniciada (simulada)"),
                    ),
                  );
                },
                child: Lottie.asset(
                  'assets/lottie/Microphone.json',
                  width: 50,
                  height: 50,
                  repeat: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _commonSymptoms.map((symptom) {
            final isSelected = _selectedSymptoms.contains(symptom);
            return ChoiceChip(
              label: Text(symptom),
              selected: isSelected,
              selectedColor: Colors.teal.shade300,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSymptoms.add(symptom);
                  } else {
                    _selectedSymptoms.remove(symptom);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // Carrusel de tips desde Firebase
  final List<String> _testTips = [
    "Bebe suficiente agua todos los días",
    "Realiza estiramientos por la mañana",
    "Duerme al menos 7 horas",
    "Evita el exceso de azúcar",
    "Camina 30 minutos diarios",
  ];

  // Carrusel de tips mejorado
  Widget _buildTipsCarousel() {
    final tips = _testTips;

    return CarouselSlider.builder(
      itemCount: tips.length,
      itemBuilder: (context, index, realIdx) {
        final tip = tips[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              colors: [Colors.teal.shade300, Colors.teal.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.shade200.withValues(alpha: 0.6),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                tip,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal.shade900,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
      options: CarouselOptions(
        height: 200,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.85,
        autoPlayInterval: const Duration(seconds: 3),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        scrollPhysics: const BouncingScrollPhysics(),
      ),
    );
  }

  // Panel rápido
  Widget _buildFeatureGrid() {
    final features = [
      {'title': 'Medicación', 'icon': 'assets/lottie/Pills.json'},
      {'title': 'Monitoreo', 'icon': 'assets/lottie/Heart.json'},
      {'title': 'Citas', 'icon': 'assets/lottie/Calendar.json'},
      {'title': 'Recordatorios', 'icon': 'assets/lottie/Notification.json'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final item = features[index];
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Container(
            decoration: BoxDecoration(
              color: Colors.teal.shade200,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.shade100,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Lottie.asset(item['icon']!, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['title']!,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Asistente IA
  Widget _buildHealthAssistantCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade700,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "🤖 Tu asistente de salud\nAnaliza tus síntomas con IA",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.teal.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              // Abrir asistente IA
            },
            child: const Text("Analizar"),
          ),
        ],
      ),
    );
  }
}
