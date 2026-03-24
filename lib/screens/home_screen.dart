import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tts/flutter_tts.dart';
import 'medication_screen.dart';
import 'monitoring_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _symptomController = TextEditingController();

  Interpreter? _interpreter;
  bool _isModelReady = false;
  String _predictionResult = "";

  late AnimationController _gradientController;
  late Animation<Color?> _backgroundAnimation;
  late AnimationController _greetingController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late FlutterTts _flutterTts;

  final List<dynamic> _diseasesData = [];
  final Map<String, List<String>> symptomDictionary = {};
  var logger = Logger();

  @override
  void initState() {
    super.initState();

    _flutterTts = FlutterTts()
      ..setLanguage("es-MX")
      ..setSpeechRate(0.5)
      ..setVolume(1.0)
      ..setPitch(1.0);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {}

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _backgroundAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.teal.shade50,
    ).animate(_gradientController);

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
    _checkAndUpdateModel();
  }

  Future<void> _checkAndUpdateModel() async {
    try {
      final dir = await getApplicationDocumentsDirectory();

      final versionFile = File('${dir.path}/version.txt');
      String localVersion = '0';
      if (versionFile.existsSync()) {
        localVersion = await versionFile.readAsString();
      }

      final versionUrl =
          'https://raw.githubusercontent.com/XanderM30/RedNeuronal/main/version.txt';
      String remoteVersion = localVersion;
      try {
        final versionResponse = await http.get(Uri.parse(versionUrl));
        if (versionResponse.statusCode == 200) {
          remoteVersion = versionResponse.body.trim();
        }
      } catch (_) {
        debugPrint("No hay internet, se usará versión local");
      }

      bool needUpdate = remoteVersion != localVersion;

      final modelFile = File('${dir.path}/modelo_enfermedades.tflite');
      if (needUpdate || !modelFile.existsSync()) {
        final modelUrl =
            'https://raw.githubusercontent.com/XanderM30/RedNeuronal/main/modelo_enfermedades.tflite';
        try {
          final modelResponse = await http.get(Uri.parse(modelUrl));
          if (modelResponse.statusCode == 200) {
            await modelFile.writeAsBytes(modelResponse.bodyBytes);
          }
        } catch (_) {
          debugPrint("No se pudo descargar modelo");
        }
      }

      final jsonFile = File('${dir.path}/control_red.json');
      if (needUpdate || !jsonFile.existsSync()) {
        try {
          final jsonUrl =
              'https://raw.githubusercontent.com/XanderM30/RedNeuronal/main/control_red.json';
          final jsonResponse = await http.get(Uri.parse(jsonUrl));
          if (jsonResponse.statusCode == 200) {
            await jsonFile.writeAsBytes(jsonResponse.bodyBytes);
          }
        } catch (_) {
          debugPrint("No se pudo descargar JSON, se usará assets");
          if (!jsonFile.existsSync()) {
            final assetData = await rootBundle.loadString(
              'assets/control_red.json',
            );
            await jsonFile.writeAsString(assetData);
          }
        }
      }

      if (needUpdate) await versionFile.writeAsString(remoteVersion);

      if (modelFile.existsSync()) {
        try {
          _interpreter = Interpreter.fromFile(modelFile);
        } catch (e) {
          debugPrint("Error cargando modelo: $e");
        }
      }
      if (_interpreter != null) setState(() => _isModelReady = true);

      String jsonString = jsonFile.existsSync()
          ? await jsonFile.readAsString()
          : await rootBundle.loadString('assets/control_red.json');

      final List<dynamic> diseasesList = jsonDecode(jsonString);
      _diseasesData.clear();
      _diseasesData.addAll(diseasesList);

      symptomDictionary.clear();
      for (var disease in diseasesList) {
        if (disease['sintomas'] != null) {
          for (var symptom in disease['sintomas']) {
            final key = symptom.toString().toLowerCase();
            symptomDictionary.putIfAbsent(key, () => [key]);
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🆕 Modelo y enfermedades cargados!")),
        );
      }
    } catch (e) {
      debugPrint("Error actualizando modelo: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error actualizando modelo: $e")),
        );
      }
    }
    _greetingController.forward();
  }

  // Simulación de animación de bienvenida
  Future<void> analyzeSymptoms() async {
    if (!_isModelReady || _interpreter == null) return;

    String inputText = _symptomController.text.toLowerCase().trim();
    if (inputText.isEmpty) return;

    String normalize(String text) {
      text = text.toLowerCase();
      final accents = 'áéíóúü';
      final replacements = 'aeiouu';
      for (int i = 0; i < accents.length; i++) {
        text = text.replaceAll(accents[i], replacements[i]);
      }
      text = text.replaceAll(RegExp(r'[^\w\s]'), '');
      return text;
    }

    inputText = normalize(inputText);

    final allSymptoms = <String>[];
    for (var disease in _diseasesData) {
      if (disease['sintomas'] != null) {
        for (var s in disease['sintomas']) {
          final normalizedSymptom = normalize(s.toString().trim());
          if (!allSymptoms.contains(normalizedSymptom)) {
            allSymptoms.add(normalizedSymptom);
          }
        }
      }
    }
    //
    List<double> inputVector = List.filled(allSymptoms.length, 0.0);
    for (int i = 0; i < allSymptoms.length; i++) {
      final symptom = allSymptoms[i];
      for (var word in inputText.split(RegExp(r'\s+'))) {
        if (symptom.contains(word) || word.contains(symptom)) {
          inputVector[i] = 1.0;
          break;
        }
      }
    }
    //
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    var output = List.generate(
      outputShape[0],
      (_) => List.filled(outputShape[1], 0.0),
    );

    _interpreter!.run([inputVector], output);

    final diseaseNames = _diseasesData
        .map((d) => d['nombre'].toString())
        .toList();

    final predictions = <Map<String, double>>[];
    for (int i = 0; i < diseaseNames.length; i++) {
      predictions.add({diseaseNames[i]: output[0][i]});
    }

    predictions.sort((a, b) => b.values.first.compareTo(a.values.first));

    String result = "Predicciones:\n";
    int top = predictions.length > 3 ? 3 : predictions.length;
    for (int i = 0; i < top; i++) {
      final entry = predictions[i];
      final name = entry.keys.first;
      final value = (entry.values.first * 100).toStringAsFixed(1);
      result += "$name: $value%\n";
    }

    setState(() => _predictionResult = result.trim());
    await _flutterTts.speak(_predictionResult);
  }

  // Simulación de animación de bienvenida
  @override
  void dispose() {
    _gradientController.dispose();
    _greetingController.dispose();
    _symptomController.dispose();
    _interpreter?.close();
    super.dispose();
  }

  Widget buildSymptomInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                  decoration: InputDecoration(
                    hintText: "Describe tus síntomas...",
                    prefixIcon: const Icon(Icons.search, color: Colors.teal),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: analyzeSymptoms, // Llama a la función de análisis
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 8,
              shadowColor: Colors.teal.withValues(alpha: 0.4),
            ),
            child: Text(
              "Analizar síntomas",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  final List<String> testTips = [
    "Bebe suficiente agua todos los días",
    "Realiza estiramientos por la mañana",
    "Duerme al menos 7 horas",
    "Evita el exceso de azúcar",
    "Camina 30 minutos diarios",
    "Incluye frutas y verduras en tu dieta",
    "Lávate las manos con frecuencia",
    "Practica técnicas de relajación",
    "Mantén una postura correcta",
    "Consulta a tu médico regularmente",
    "Usa protector solar al salir",
    "Evita el consumo excesivo de alcohol",
    "Realiza chequeos médicos anuales",
  ];

  Widget buildFeatureGrid() {
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
          onTap: () {
            if (item['title'] == 'Medicación') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MedicationScreen(),
                ),
              );
            } else if (item['title'] == 'Monitoreo') {
              // si el usuario da click en monitoreo, lo manda a la pantalla de monitoreo
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const MonitoringScreen(), //builder sirve para construir la pantalla de monitoreo
                ),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade300, Colors.teal.shade500],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
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

  Widget buildTipsCarousel() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 120, // esto sirve para que el carrusel no se vea tan pequeño
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.85,
      ),
      items: testTips.map((tip) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal.shade300,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Text(
              tip,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHealthAssistantCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade600, Colors.teal.shade800],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.health_and_safety, color: Colors.white, size: 50),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              "Asistente de salud con IA\nAnaliza tus síntomas en segundos",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundAnimation.value ?? Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          "NeuroMedX",
          style: GoogleFonts.lobster(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade800,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 5),
                  // Tarjeta IA
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildHealthAssistantCard(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Input síntomas
                  buildSymptomInput(),

                  const SizedBox(height: 20),

                  // Resultado IA
                  if (_predictionResult.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _predictionResult,
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Carrusel de tips
                  buildFeatureGrid(),
                  testTips.isNotEmpty ? const SizedBox(height: 5) : Container(),
                  if (testTips.isNotEmpty) buildTipsCarousel(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
