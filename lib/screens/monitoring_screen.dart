import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class HealthRecord {
  final String type; // glucosa o ritmo
  final int value;
  final DateTime date;

  HealthRecord({required this.type, required this.value, required this.date});
}

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  int heartRate = 72;
  String bloodPressure = "120/80";

  List<int> heartHistory = [];
  List<HealthRecord> records = [];

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startSimulation();
  }

  void startSimulation() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        heartRate = 65 + Random().nextInt(40);

        heartHistory.add(heartRate);
        if (heartHistory.length > 10) {
          heartHistory.removeAt(0);
        }
      });
    });
  }

  Color getHeartColor() {
    if (heartRate < 60) return Colors.blue;
    if (heartRate > 100) return Colors.red;
    return Colors.green;
  }

  String getStatus() {
    if (heartRate < 60) return "Bajo";
    if (heartRate > 100) return "Alto";
    return "Normal";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // -------------------- UI CARDS --------------------

  Widget buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.teal.shade700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  // -------------------- HEART REAL TIME --------------------

  Widget buildHeartRate() {
    return Column(
      children: [
        Icon(Icons.favorite, color: getHeartColor(), size: 50),
        Text(
          "$heartRate BPM",
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: getHeartColor(),
          ),
        ),
        Text(getStatus(), style: GoogleFonts.poppins(color: Colors.grey)),
      ],
    );
  }

  // -------------------- AGREGAR REGISTROS --------------------

  void showAddRecordDialog(String type) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Agregar ${type == "glucosa" ? "Glucosa" : "Ritmo Cardíaco"}",
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "Ingresa valor"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value != null) {
                  setState(() {
                    records.add(
                      HealthRecord(
                        type: type,
                        value: value,
                        date: DateTime.now(),
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  // -------------------- EXPORTAR PDF --------------------
  Future<void> exportToPDF() async {
    final pdf = pw.Document();

    final glucosa = records.where((r) => r.type == "glucosa").toList();
    final ritmo = records.where((r) => r.type == "ritmo").toList();

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          // 🧠 TÍTULO
          pw.Center(
            child: pw.Text(
              "NeuroMedX - Reporte de Salud",
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal,
              ),
            ),
          ),

          pw.SizedBox(height: 10),

          pw.Center(
            child: pw.Text(
              "Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),

          pw.Divider(),

          // ❤️ FRECUENCIA ACTUAL
          pw.Text(
            "Frecuencia Cardíaca Actual",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),

          pw.Text("$heartRate BPM\nEstado: ${getStatus()}"),

          pw.SizedBox(height: 20),

          // 🍬 GLUCOSA
          pw.Text(
            "Historial de Glucosa",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 10),

          ...glucosa.map(
            (g) => pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 4),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.teal50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("${g.value} mg/dL"),
                  pw.Text("${g.date.day}/${g.date.month}"),
                ],
              ),
            ),
          ),

          pw.SizedBox(height: 20),

          // ❤️ RITMO
          pw.Text(
            "Historial de Ritmo Cardíaco",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 10),

          ...ritmo.map(
            (r) => pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 4),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.teal50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("${r.value} BPM"),
                  pw.Text("${r.date.day}/${r.date.month}"),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    var bool = await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // -------------------- LISTA HISTORIAL --------------------

  Widget buildRecordList(String type) {
    final filtered = records.where((r) => r.type == type).toList().reversed;

    return Column(
      children: filtered.map((record) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${record.value} ${type == "glucosa" ? "mg/dL" : "BPM"}",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              Text(
                "${record.date.day}/${record.date.month}",
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // -------------------- SECCIONES --------------------

  Widget buildGlucoseSection() {
    return buildCard(
      title: "Nivel de Azúcar",
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () => showAddRecordDialog("glucosa"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text("Agregar registro"),
          ),
          const SizedBox(height: 10),
          buildRecordList("glucosa"),
        ],
      ),
    );
  }

  Widget buildHeartManualSection() {
    return buildCard(
      title: "Registro de Ritmo Cardíaco",
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () => showAddRecordDialog("ritmo"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text("Agregar registro"),
          ),
          const SizedBox(height: 10),
          buildRecordList("ritmo"),
        ],
      ),
    );
  }

  // -------------------- HISTORIAL GRAFICO SIMPLE --------------------

  Widget buildHistory() {
    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: heartHistory.map((value) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: value.toDouble(),
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // -------------------- UI --------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: Text(
          "Monitoreo de Salud",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        //backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: exportToPDF,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("Exportar PDF"),
              ),
              buildCard(
                title: "Frecuencia Cardíaca (Tiempo Real)",
                child: buildHeartRate(),
              ),
              buildGlucoseSection(),
              buildHeartManualSection(),
              buildCard(
                title: "Historial en tiempo real",
                child: buildHistory(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
