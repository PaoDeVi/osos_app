import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'eval_player_screen.dart';
import 'dart:math';
import 'package:logger/logger.dart';
import 'package:google_fonts/google_fonts.dart';

final _log = Logger();

// Modelo para estudiante
class ClienteData {
  final String dni;
  final String firstname;
  final String surname;

  ClienteData({
    required this.dni,
    required this.firstname,
    required this.surname,
  });
}

class EvalRendimScreen extends StatefulWidget {
  final String email;

  const EvalRendimScreen({super.key, required this.email});

  @override
  State<EvalRendimScreen> createState() => _EvalRendimScreenState();
}

class _EvalRendimScreenState extends State<EvalRendimScreen> {
  Map<String, double> valores = {};
  List<String> variables = [];
  String? variableSeleccionada;

  List<ClienteData> estudiantes = [];
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cargarVariables();
    _cargarEstudiantes();
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

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('EVALUACIONES')
              .where('var_id', isEqualTo: variableSeleccionada)
              .orderBy('fecha', descending: true)
              .get();

      Map<String, double> temp = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();

        if (data.containsKey('dni') &&
            data.containsKey('valor') &&
            data.containsKey('fecha')) {
          final alumnoId = data['dni'];
          final valor = (data['valor'] as num).toDouble();

          if (!temp.containsKey(alumnoId)) {
            temp[alumnoId] = valor;
          }
        }
      }

      setState(() {
        valores = temp;
      });
    } catch (e) {
      _log.w('Error al cargar datos: $e');
    }
  }

  Future<void> _cargarEstudiantes() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('IOON_CLIENTE').get();

      final lista =
          snapshot.docs.map((doc) {
            return ClienteData(
              dni: doc['dni'].toString(),
              firstname: doc['firstname'] ?? '',
              surname: doc['surname'] ?? '',
            );
          }).toList();

      setState(() {
        estudiantes = lista;
      });
    } catch (e) {
      _log.w('Error al cargar estudiantes: $e');
    }
  }

  List<PieChartSectionData> _getPieChartData() {
    if (valores.isEmpty) return [];

    final valoresList = valores.values.toList();
    final minValor = valoresList.reduce(min);
    final maxValor = valoresList.reduce(max);

    final n = valores.length;
    final cantidadRangos = max(1, (1 + log(n) / log(2)).ceil());
    final intervalo = (maxValor - minValor) / cantidadRangos;

    Map<String, int> distribucionRangos = {};

    for (var valor in valores.values) {
      for (int i = 0; i < cantidadRangos; i++) {
        final inicio = minValor + i * intervalo;
        final fin = inicio + intervalo;
        final esUltimo = i == cantidadRangos - 1;

        if ((valor >= inicio && valor < fin) || (esUltimo && valor <= fin)) {
          final etiqueta = '${inicio.round()}–${fin.round()}';
          distribucionRangos[etiqueta] =
              (distribucionRangos[etiqueta] ?? 0) + 1;
          break;
        }
      }
    }

    final total = valores.length;
    final colores = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
    ];

    int colorIndex = 0;

    return distribucionRangos.entries.map((entry) {
      final porcentaje = (entry.value / total) * 100;
      final color = colores[colorIndex % colores.length];
      colorIndex++;

      return PieChartSectionData(
        color: color,
        value: porcentaje,
        title: '${entry.key}: ${porcentaje.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 0, 58, 13),
        ),
        showTitle: true,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final estudiantesFiltrados =
        estudiantes.where((cliente) {
          final query = searchQuery.toLowerCase();
          return cliente.firstname.toLowerCase().contains(query) ||
              cliente.dni.toLowerCase().contains(query) ||
              cliente.surname.toLowerCase().contains(query);
        }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'OSOS DE LA SALLE',
          style: GoogleFonts.bungeeInline(
            textStyle: TextStyle(color: Colors.white),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECCIÓN: RESUMEN DE RENDIMIENTO
            const Text(
              'RESUMEN DE RENDIMIENTO',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 2, 63, 4),
              ),
            ),
            const SizedBox(height: 16),
            if (valores.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              AspectRatio(
                aspectRatio: 1,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: PieChart(
                      PieChartData(
                        sections: _getPieChartData(),
                        borderData: FlBorderData(show: false),
                        centerSpaceRadius: 70,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (variables.isNotEmpty)
              Container(
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
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: Colors.green.shade900,
                    ),
                    dropdownColor: Colors.white,
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontSize: 14,
                    ),
                    onChanged: (value) {
                      setState(() {
                        variableSeleccionada = value;
                        valores = {};
                      });
                      _cargarDatos();
                    },
                    items:
                        variables.map((v) {
                          return DropdownMenuItem(
                            value: v,
                            child: Center(
                              child: Text(
                                v.toUpperCase(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
            const SizedBox(height: 32),

            // SECCIÓN: LISTA DE ESTUDIANTES
            const Text(
              'LISTA DE ESTUDIANTES',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 2, 63, 4),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: searchController,
              //cursorColor: Color.fromARGB(255, 2, 63, 2),
              decoration: InputDecoration(
                labelText: 'Buscar por nombre o DNI',
                labelStyle: TextStyle(color: Color.fromARGB(255, 2, 63, 2)),
                prefixIcon: const Icon(Icons.search),
                //hoverColor: Color.fromARGB(255, 2, 63, 4),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color.fromARGB(255, 2, 63, 2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color.fromARGB(255, 2, 63, 2)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: estudiantesFiltrados.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 3 / 2,
              ),
              itemBuilder: (context, index) {
                final cliente = estudiantesFiltrados[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => EvalPlayerScreen(dni: cliente.dni),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  cliente.firstname,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color.fromARGB(255, 4, 133, 8),
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Flexible(
                                child: Text(
                                  "DNI: ${cliente.dni}",
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
