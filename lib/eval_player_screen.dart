// Reemplaza todo tu archivo con este contenido

// ...imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class EvalPlayerScreen extends StatefulWidget {
  final String dni;

  const EvalPlayerScreen({super.key, required this.dni});

  @override
  State<EvalPlayerScreen> createState() => _EvalPlayerScreenState();
}

class _EvalPlayerScreenState extends State<EvalPlayerScreen> {
  Map<DateTime, double> valores = {};
  List<String> variables = [];
  String? variableSeleccionada;
  String firstname = '---';
  String surname = '---';
  String peso = '---';
  String talla = '---';

  // Form controllers
  final _valorEsperadoController = TextEditingController();
  final _valorController = TextEditingController();
  final _comentarioController = TextEditingController();

  // Crear Variable Controllers
  final _nombreVariableController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _unidadController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchEstudiante();
    _cargarVariables();
  }

  Future<void> _fetchEstudiante() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('IOON_CLIENTE')
            .where('dni', isEqualTo: widget.dni)
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      setState(() {
        firstname = data['firstname'] ?? '---';
        surname = data['surname'] ?? '---';
        peso = data['peso']?.toString() ?? '---';
        talla = data['altura']?.toString() ?? '---';
      });
    }
  }

  Future<void> _cargarVariables() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('VARIABLES_EVAL').get();

    final nombres = snapshot.docs.map((doc) => doc.id).toList();

    if (nombres.isNotEmpty) {
      setState(() {
        variables = nombres;
        variableSeleccionada = nombres.first;
      });

      await _cargarDatos();
    }
  }

  Future<void> _cargarDatos() async {
    if (variableSeleccionada == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('EVALUACIONES')
            .where('dni', isEqualTo: widget.dni)
            .where('var_id', isEqualTo: variableSeleccionada)
            .orderBy('fecha', descending: true)
            .limit(5)
            .get();

    final temp = <DateTime, double>{};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final valor = (data['valor'] as num).toDouble();
      final fecha = DateTime.fromMillisecondsSinceEpoch(data['fecha']);
      temp[fecha] = valor;
    }

    setState(() {
      valores = Map.fromEntries(temp.entries.toList().reversed);
    });
  }

  List<FlSpot> _getLineSpots() {
    final sortedDates = valores.keys.toList()..sort();
    return sortedDates.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final valor = valores[entry.value]!;
      return FlSpot(index, valor);
    }).toList();
  }

  Future<void> _guardarEvaluacion() async {
    if (variableSeleccionada == null ||
        _valorEsperadoController.text.trim().isEmpty ||
        _valorController.text.trim().isEmpty ||
        _comentarioController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Completa todos los campos antes de guardar.')),
      );
      return;
    }

    final valorEsperado = double.tryParse(_valorEsperadoController.text);
    final valor = double.tryParse(_valorController.text);

    if (valorEsperado == null || valor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ingresa valores numéricos válidos.')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('EVALUACIONES').add({
      'dni': widget.dni,
      'var_id': variableSeleccionada,
      'valor_esperado': valorEsperado,
      'valor': valor,
      'comentario': _comentarioController.text.trim(),
      'fecha': DateTime.now().millisecondsSinceEpoch,
    });

    _valorEsperadoController.clear();
    _valorController.clear();
    _comentarioController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Evaluación guardada exitosamente.')),
    );

    _cargarDatos();
  }

  Future<void> _crearVariable() async {
    final nombre = _nombreVariableController.text.trim();
    if (nombre.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('VARIABLES_EVAL')
        .doc(nombre)
        .set({
          'nombre': nombre,
          'descripcion': _descripcionController.text.trim(),
          'unidad_medida': _unidadController.text.trim(),
        });

    _nombreVariableController.clear();
    _descripcionController.clear();
    _unidadController.clear();

    _cargarVariables();
    Navigator.of(context).pop();
  }

  void _mostrarDialogoCrearVariable() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Crear Nueva Variable'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nombreVariableController,
                  decoration: InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: _descripcionController,
                  decoration: InputDecoration(labelText: 'Descripción'),
                ),
                TextField(
                  controller: _unidadController,
                  decoration: InputDecoration(labelText: 'Unidad de Medida'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancelar'),
              ),
              ElevatedButton(onPressed: _crearVariable, child: Text('Crear')),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Datos del Estudiante',
          style: GoogleFonts.outfit(textStyle: TextStyle(color: Colors.white)),
        ),
        backgroundColor: Colors.green.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Información General',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoBox('$firstname $surname', '$peso kg', '$talla cm'),
            const SizedBox(height: 32),
            Text(
              'Resumen avance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
              ),
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1.6,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child:
                      valores.isEmpty
                          ? Center(child: Text('No hay datos para mostrar'))
                          : LineChart(
                            LineChartData(
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toStringAsFixed(1),
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 25,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      final sortedDates =
                                          valores.keys.toList()..sort();
                                      if (value.toInt() >= 0 &&
                                          value.toInt() < sortedDates.length) {
                                        final date = sortedDates[value.toInt()];
                                        return Text(
                                          '${date.day}/${date.month}',
                                          style: const TextStyle(fontSize: 10),
                                        );
                                      } else {
                                        return const Text('');
                                      }
                                    },
                                  ),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  isCurved: true,
                                  color: Colors.green,
                                  barWidth: 3,
                                  dotData: FlDotData(show: true),
                                  spots: _getLineSpots(),
                                ),
                              ],
                            ),
                          ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade800),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: variableSeleccionada,
                        onChanged: (value) {
                          setState(() {
                            variableSeleccionada = value;
                            valores = {};
                          });
                          _cargarDatos();
                        },
                        items:
                            variables
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v,
                                    child: Text(v.toUpperCase()),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _mostrarDialogoCrearVariable,
                  style: botonVerde,
                  child: Text('Crear Variable'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Evaluar Alumno',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valorEsperadoController,
              decoration: InputDecoration(labelText: 'Valor Esperado'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _valorController,
              decoration: InputDecoration(labelText: 'Valor'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _comentarioController,
              decoration: InputDecoration(labelText: 'Comentario'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _guardarEvaluacion,
              style: botonVerde,
              child: Text('Guardar Evaluación'),
            ),
          ],
        ),
      ),
    );
  }

  final ButtonStyle botonVerde = ElevatedButton.styleFrom(
    foregroundColor: Colors.green.shade800, // color del texto
    backgroundColor: Colors.white, // fondo blanco
    side: BorderSide(color: Colors.green.shade800),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: const TextStyle(fontWeight: FontWeight.bold),
  );

  Widget _buildInfoBox(String nombre, String peso, String talla) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color.fromARGB(255, 192, 233, 192)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            nombre,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Peso: $peso", style: TextStyle(fontSize: 16)),
              const SizedBox(width: 20),
              Text("Talla: $talla", style: TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}
