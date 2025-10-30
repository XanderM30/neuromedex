import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  Interpreter? _interpreter;
  bool _isModelReady = false;
  bool _isDownloading = false;
  String? _taskId;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _startDownload();
  }

  void _initNotifications() {
    AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'model_updates',
        channelName: 'Model Updates',
        channelDescription: 'Notificaciones de descarga de modelo',
        defaultColor: Colors.teal,
        importance: NotificationImportance.High,
        channelShowBadge: true,
      ),
    ]);
  }

  Future<void> _startDownload() async {
    final dir = await getApplicationDocumentsDirectory();
    final modelFile = File('${dir.path}/modelo_medicamentos_dinamico.tflite');

    // Si el archivo ya existe, solo cargarlo
    if (modelFile.existsSync()) {
      _loadModel(modelFile);
      return;
    }

    final url =
        'https://raw.githubusercontent.com/XanderM30/Red-Neuronal-Medicamento/main/modelo_medicamentos_dinamico.tflite';

    setState(() {
      _isDownloading = true;
    });

    _taskId = await FlutterDownloader.enqueue(
      url: url,
      savedDir: dir.path,
      fileName: 'modelo_medicamentos_dinamico.tflite',
      showNotification: true,
      openFileFromNotification: false,
    );

    FlutterDownloader.registerCallback(downloadCallback as DownloadCallback);
  }

  @pragma('vm:entry-point')
  static void downloadCallback(
    String id,
    DownloadTaskStatus status,
    int progress,
  ) async {
    if (status == DownloadTaskStatus.complete) {
      final dir = await getApplicationDocumentsDirectory();
      final modelFile = File('${dir.path}/modelo_medicamentos_dinamico.tflite');

      // Crear notificación
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 1,
          channelKey: 'model_updates',
          title: 'Descarga completada ✅',
          body: 'El modelo de medicamentos ya está listo.',
        ),
      );

      // Cargar modelo
      try {
        Interpreter.fromFile(modelFile);
        debugPrint('✅ Modelo cargado correctamente en background');
      } catch (e) {
        debugPrint('Error cargando modelo: $e');
      }
    }
  }

  void _loadModel(File modelFile) {
    try {
      _interpreter = Interpreter.fromFile(modelFile);
      setState(() {
        _isModelReady = true;
        _isDownloading = false;
      });
      debugPrint("✅ Modelo cargado correctamente");
    } catch (e) {
      debugPrint("Error cargando modelo: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Medicación",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "💊 Tus medicamentos",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800,
              ),
            ),
            const SizedBox(height: 10),
            if (_isDownloading)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Descargando modelo..."),
                  SizedBox(height: 8),
                  LinearProgressIndicator(),
                  SizedBox(height: 12),
                ],
              )
            else
              Text(
                _isModelReady
                    ? "El modelo está listo para usar."
                    : "Cargando modelo, por favor espera...",
              ),
            const SizedBox(height: 30),
            const Center(
              child: Text(
                "🕓 Próximamente podrás añadir tus tratamientos.",
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
