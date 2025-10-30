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
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:logger/logger.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tts/flutter_tts.dart';
import 'medication_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String _userName = "Usuario";
  final TextEditingController _symptomController = TextEditingController();

  Interpreter? _interpreter;
  bool _isModelReady = false;
  String _predictionResult = "";

  late stt.SpeechToText _speech;
  bool _isListening = false;
  //String _voiceInput = "";
  late AnimationController _gradientController;
  late Animation<Color?> _backgroundAnimation;
  late AnimationController _greetingController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late FlutterTts _flutterTts;

  final List<dynamic> _diseasesData = [];
  final Map<String, List<String>> symptomDictionary = {};
  var logger = Logger();
  bool _isWakeWordMode = true;
  final bool _isAnalyzingConversation = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts()
      ..setLanguage("es-MX")
      ..setSpeechRate(0.5)
      ..setVolume(1.0)
      ..setPitch(1.0);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userName = user.displayName ?? user.email?.split("@")[0] ?? "Usuario";
    }

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
    Future.delayed(const Duration(seconds: 2), () {
      _startContinuousListening();
    });
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
  }

  Future<void> _analyzeSymptoms() async {
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

    final outputShape = _interpreter!.getOutputTensor(0).shape;
    var output = List.filled(
      outputShape.reduce((a, b) => a * b),
      0.0,
    ).reshape(outputShape);
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

  @override
  void dispose() {
    _gradientController.dispose();
    _greetingController.dispose();
    _symptomController.dispose();
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _startContinuousListening() async {
    logger.i("🎤 Iniciando modo pasivo (esperando 'Xander')...");

    if (_speech.isListening) return;

    bool available = await _speech.initialize(
      onStatus: (status) async {
        logger.d("Estado (pasivo): $status");

        if (status == "notListening" && !_isAnalyzingConversation) {
          await Future.delayed(const Duration(seconds: 4));
          if (mounted && !_speech.isListening && _isWakeWordMode) {
            logger.i("🔄 Reiniciando escucha pasiva...");
            _startContinuousListening();
          }
        }
      },
      onError: (error) {
        logger.e("Error en modo pasivo: $error");
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && !_speech.isListening && _isWakeWordMode) {
            _startContinuousListening();
          }
        });
      },
    );

    if (!available) {
      logger.w("⚠️ Reconocimiento de voz no disponible");
      return;
    }

    _isListening = true;

    _speech.listen(
      onResult: (val) async {
        final spoken = val.recognizedWords.toLowerCase().trim();
        if (spoken.isEmpty) return;

        logger.i("Detectado (pasivo): $spoken");

        if (spoken.contains("xander")) {
          logger.i("✅ Wake word detectada: Xander");
          _isWakeWordMode = false;
          _isListening = false;
          await _speech.stop();
          await _flutterTts.speak("¿Qué pasa?");
          await Future.delayed(const Duration(milliseconds: 600));
          _startSymptomListening();
        }
      },
      listenFor: const Duration(minutes: 10),
      pauseFor: const Duration(seconds: 6),
      partialResults: true,
      localeId: "es_MX",
    );
  }

  Future<void> _startSymptomListening() async {
    logger.i("🎧 Escuchando síntomas activamente...");

    if (_speech.isListening) await _speech.stop();

    bool available = await _speech.initialize(
      onStatus: (status) async {
        logger.d("Estado (síntomas): $status");

        if (status == "notListening" && !_isWakeWordMode) {
          await Future.delayed(const Duration(seconds: 3));
          _isWakeWordMode = true;
          _startContinuousListening();
        }
      },
      onError: (error) => logger.e("Error en modo síntoma: $error"),
    );

    if (!available) return;

    _speech.listen(
      onResult: (val) async {
        final spoken = val.recognizedWords.toLowerCase().trim();
        if (spoken.isEmpty) return;

        logger.i("Síntomas detectados: $spoken");

        if (spoken.contains("me duele") ||
            spoken.contains("tengo") ||
            spoken.contains("siento")) {
          _symptomController.text = spoken;
          await _flutterTts.speak("Déjame analizar tus síntomas...");
          await _analyzeSymptoms();

          await Future.delayed(const Duration(seconds: 3));
          _isWakeWordMode = true;
          _startContinuousListening();
        }
      },
      listenFor: const Duration(minutes: 2),
      pauseFor: const Duration(seconds: 10),
      partialResults: true,
      localeId: "es_MX",
    );
  }

  void _listen() {
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    } else {
      _startSymptomListening();
    }
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
                  Text(
                    "¿Cómo te sientes hoy?",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.teal.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSymptomInput(),
                  const SizedBox(height: 20),
                  if (_predictionResult.isNotEmpty) _buildPredictionCard(),
                  const SizedBox(height: 30),
                  _buildFeatureGrid(),
                  const SizedBox(height: 30),
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
                  _buildTipsCarousel(),
                  const SizedBox(height: 30),
                  _buildHealthAssistantCard(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPredictionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          colors: [Colors.teal.shade100, Colors.teal.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade200.withAlpha(100),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Predicciones de enfermedades",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
            ),
          ),
          const SizedBox(height: 12),
          ..._buildPredictionChips(_predictionResult),
        ],
      ),
    );
  }

  List<Widget> _buildPredictionChips(String predictionText) {
    final lines = predictionText.split('\n');
    return lines.map((line) {
      final parts = line.split(':');
      if (parts.length != 2) return const SizedBox.shrink();
      final name = parts[0].trim();
      final percent =
          double.tryParse(parts[1].replaceAll('%', '').trim()) ?? 0.0;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.teal.shade900,
              ),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percent / 100,
                backgroundColor: Colors.teal.shade50,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade600),
                minHeight: 10,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildSymptomInput() {
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
                  decoration: const InputDecoration(
                    hintText: "Describe tus síntomas...",
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.teal.shade700,
                ),
                onPressed: _listen,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _analyzeSymptoms,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 5,
            ),
            child: Text(
              "Analizar síntomas",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  final List<String> _testTips = [
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

  Widget _buildTipsCarousel() {
    return CarouselSlider.builder(
      itemCount: _testTips.length,
      itemBuilder: (context, index, realIdx) {
        final tip = _testTips[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(255, 0, 181, 163),
                Colors.teal.shade100,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.shade200.withAlpha(150),
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
          onTap: () {
            if (item['title'] == 'Medicación') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MedicationsScreen(),
                ),
              );
            }
          },
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
            onPressed: _analyzeSymptoms,
            child: const Text("Analizar"),
          ),
        ],
      ),
    );
  }
}
