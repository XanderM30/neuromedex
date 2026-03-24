import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();

  late File _modelFile;
  late File _versionFile;
  late File _controlFile;
  late File _tokensFile;

  late Interpreter _interpreter;
  List<Map<String, dynamic>> _medicamentos = [];
  List<String> _tokens = [];
  List<Map<String, dynamic>> _resultados = [];
  bool _loading = true;

  // Animaciones
  late AnimationController _gradientController;
  late AnimationController _cardController;
  late Animation<Color?> _backgroundAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final String modelUrl =
      "https://raw.githubusercontent.com/XanderM30/RedNeuronalMedicamnetos/main/modelo_medicamentos.tflite";
  final String versionUrl =
      "https://raw.githubusercontent.com/XanderM30/RedNeuronalMedicamnetos/main/version.txt";
  final String controlUrl =
      "https://raw.githubusercontent.com/XanderM30/RedNeuronalMedicamnetos/main/control_medicamentos.json";
  final String tokensUrl =
      "https://raw.githubusercontent.com/XanderM30/RedNeuronalMedicamnetos/main/tokens.json";

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initFiles();
  }

  void _setupAnimations() {
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _backgroundAnimation = ColorTween(
      begin: Colors.teal.shade100,
      end: Colors.teal.shade50,
    ).animate(_gradientController);

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));
  }

  Future<void> _initFiles() async {
    setState(() => _loading = true);

    final dir = await getApplicationDocumentsDirectory();
    _modelFile = File('${dir.path}/modelo_medicamentos.tflite');
    _versionFile = File('${dir.path}/version.txt');
    _controlFile = File('${dir.path}/control_medicamentos.json');
    _tokensFile = File('${dir.path}/tokens.json');

    if (!await _versionFile.exists()) await _versionFile.writeAsString('0');

    await _checkAndUpdate();
    await _loadModelAndControl();

    setState(() => _loading = false);
  }

  // El método _checkAndUpdate verifica la versión local del modelo y los archivos de control, y los compara con la versión remota disponible en GitHub. Si la versión remota es más reciente o si alguno de los archivos necesarios no existe localmente, se descargan los archivos desde GitHub y se actualiza la versión local. Esto asegura que el usuario siempre tenga la última versión del modelo y los datos asociados sin necesidad de actualizar la aplicación desde la tienda.
  Future<void> _checkAndUpdate() async {
    int localVersion = int.tryParse(await _versionFile.readAsString()) ?? 0;
    int remoteVersion = 0;

    try {
      final res = await http.get(Uri.parse(versionUrl));
      if (res.statusCode == 200) {
        remoteVersion = int.tryParse(res.body.trim()) ?? 0;
      }
    } catch (e) {
      if (kDebugMode) print("Error leyendo versión remota: $e");
    }

    if (remoteVersion > localVersion ||
        !await _modelFile.exists() ||
        !await _controlFile.exists() ||
        !await _tokensFile.exists()) {
      if (kDebugMode) print("⬆️ Descargando archivos necesarios...");

      await _downloadFile(modelUrl, _modelFile);
      await _downloadFile(controlUrl, _controlFile);
      await _downloadFile(tokensUrl, _tokensFile);

      await _versionFile.writeAsString(remoteVersion.toString());
      if (kDebugMode) print("✅ Descarga completa");
    } else {
      if (kDebugMode) {
        print("✅ Ya tienes la versión más reciente: $localVersion");
      }
    }
  }

  Future<void> _downloadFile(String url, File dest) async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      await dest.writeAsBytes(res.bodyBytes);
    } else {
      throw Exception("Error descargando archivo: $url");
    }
  }

  Future<void> _loadModelAndControl() async {
    _interpreter = Interpreter.fromFile(_modelFile);

    String content = await _controlFile.readAsString();
    _medicamentos = List<Map<String, dynamic>>.from(json.decode(content));

    String tokensContent = await _tokensFile.readAsString();
    _tokens = List<String>.from(
      json.decode(tokensContent),
    ); // esperamos un array de strings con los tokens usados para el input de la red neuronal
  }

  String _normalize(String s) {
    s = s.toLowerCase();
    s = s.replaceAll(RegExp(r'[áàä]'), 'a');
    s = s.replaceAll(RegExp(r'[éèë]'), 'e');
    s = s.replaceAll(RegExp(r'[íìï]'), 'i');
    s = s.replaceAll(RegExp(r'[óòö]'), 'o');
    s = s.replaceAll(RegExp(r'[úùü]'), 'u');
    s = s.replaceAll(RegExp(r'[^a-z0-9 ]'), '');
    return s;
  }

  void _buscarMedicamento(String input) {
    if (input.isEmpty) {
      setState(() => _resultados = []);
      return;
    }

    input = _normalize(input);

    // Construir vector de entrada para la red neuronal basado en tokens del nombre exacto
    List<double> inputVector = List.filled(_tokens.length, 0.0);
    for (int i = 0; i < _tokens.length; i++) {
      // Solo activamos tokens que aparecen exactamente en el input
      if (input.contains(_tokens[i])) {
        inputVector[i] = 1.0;
      }
    }

    // Ejecutar la red neuronal
    List<List<double>> output = List.generate(
      1,
      (_) => List.filled(_medicamentos.length, 0.0),
    );
    _interpreter.run([inputVector], output);

    // Encontrar el medicamento cuya predicción sea máxima y además coincida en nombre
    double maxProb = -1;
    int maxIndex = -1;

    for (int i = 0; i < _medicamentos.length; i++) {
      double prob = output[0][i];
      // Normalizamos nombre del medicamento para comparación
      String medName = _normalize(_medicamentos[i]["nombre"]);
      if (prob > maxProb && medName.contains(input)) {
        maxProb = prob;
        maxIndex = i;
      }
    }

    // Guardar solo el top-1 que coincida
    List<Map<String, dynamic>> results = [];
    if (maxIndex != -1 && maxProb > 0.01) {
      results.add({
        "medicamento": _medicamentos[maxIndex]["nombre"],
        "probabilidad": (maxProb * 100).toStringAsFixed(1),
        "info": _medicamentos[maxIndex],
      });
    }
    _cardController.forward(from: 0);
    setState(() => _resultados = results);
  }

  // Construir la UI para mostrar los resultados de búsqueda
  Widget _buildSearchResults() {
    if (_resultados.isEmpty) {
      return const Center(child: Text("No se encontraron medicamentos"));
    }
    // Solo mostramos el medicamento con mayor probabilidad que además coincida en nombre
    return Column(
      children: _resultados.map((m) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m['medicamento'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text("Tipo: ${m['info']['tipo'] ?? ''}"),
                    Text("Descripción: ${m['info']['descripcion'] ?? ''}"),
                    Text("Usos: ${m['info']['usos'] ?? ''}"),
                    Text("Reacciones: ${m['info']['reacciones'] ?? ''}"),
                    Text("Presentación: ${m['info']['presentacion'] ?? ''}"),
                    Text(
                      "Contraindicaciones: ${m['info']['contraindicaciones'] ?? ''}",
                    ),
                    //Text("Dosis: ${m['info']['dosis'] ?? ''}"),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
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
                      child: Column(
                        children: [
                          Text(
                            "💊 Buscador inteligente",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Encuentra información médica confiable al instante",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.teal.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Busca tu medicamento",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.teal.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Ej. Paracetamol",
                      prefixIcon: const Icon(Icons.search, color: Colors.teal),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _buscarMedicamento("");
                        },
                      ),
                    ),
                    onChanged: _buscarMedicamento,
                  ),
                  const SizedBox(height: 20),
                  _loading
                      ? Column(
                          children: [
                            const SizedBox(height: 30),
                            const CircularProgressIndicator(color: Colors.teal),
                            const SizedBox(height: 10),
                            Text(
                              "Cargando modelo médico...",
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          ],
                        )
                      : _buildSearchResults(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

extension ListReshape on List {
  List<List<dynamic>> reshape(List<int> shape) {
    if (shape.length != 2) throw Exception("Solo soporta 2D");
    int rows = shape[0], cols = shape[1];
    if (length != rows * cols) throw Exception("Dimensiones no coinciden");
    List<List<dynamic>> result = [];
    for (int i = 0; i < rows; i++) {
      result.add(sublist(i * cols, (i + 1) * cols));
    }
    return result;
  }
}
