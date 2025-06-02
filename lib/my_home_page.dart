import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:google_fonts/google_fonts.dart';

final _log = Logger();

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.dni});

  final String title;
  final String dni;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  Map<String, dynamic>? userData;
  String? userDocId;
  late AnimationController _animationController;

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Administrativa'),
    BottomNavigationBarItem(
      icon: Icon(Icons.sports_basketball),
      label: 'Deportiva',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.photo_album), label: 'Fotos'),
  ];

  @override
  void initState() {
    super.initState();
    fetchUserDataByDni();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchUserDataByDni() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('IOON_CLIENTE')
              .where('dni', isEqualTo: widget.dni)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          userData = snapshot.docs.first.data();
          userDocId = snapshot.docs.first.id;
        });
        _animationController.forward(); // Start animation
      }
    } catch (e) {
      _log.w('Error al obtener los datos: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchEvaluacionesConVariables(
    String dni,
  ) async {
    try {
      // Obtener las evaluaciones de la base de datos, ordenadas por fecha (descendente)
      final evalSnap =
          await FirebaseFirestore.instance
              .collection('EVALUACIONES')
              .where('dni', isEqualTo: dni)
              .orderBy('fecha', descending: true)
              .get();

      if (evalSnap.docs.isEmpty) {
        _log.w('No se encontraron evaluaciones para el dni: $dni');
        return [];
      }

      final evaluaciones = evalSnap.docs.map((doc) => doc.data()).toList();
      _log.i('Evaluaciones encontradas: ${evaluaciones.length}');

      // Agrupar evaluaciones por var_id
      final Map<String, List<Map<String, dynamic>>> agrupadasPorVarId = {};

      for (final eval in evaluaciones) {
        final varId = eval['var_id'];
        if (varId == null) {
          _log.w('Evaluación sin var_id válida: $eval');
          continue;
        }

        agrupadasPorVarId.putIfAbsent(varId, () => []).add(eval);
      }

      // Obtener los nombres de las variables
      final variableIds = agrupadasPorVarId.keys.toList();
      final varSnap =
          await FirebaseFirestore.instance
              .collection('VARIABLES_EVAL')
              .where(FieldPath.documentId, whereIn: variableIds)
              .get();

      final variableNombres = {
        for (var doc in varSnap.docs)
          doc.id: {
            'nombre': doc.data()['nombre'] ?? '—',
            'descripcion': doc.data()['descripcion'] ?? '—',
          },
      };

      // Procesar los resultados
      final resultados =
          agrupadasPorVarId.entries.map((entry) {
            final varId = entry.key;
            final datos = entry.value;

            // Ordenar las evaluaciones por fecha en orden descendente
            datos.sort((a, b) => b['fecha'].compareTo(a['fecha']));

            // Obtener los dos últimos registros (el último y el penúltimo)
            final ultimo = datos[0];
            final penultimo = datos.length > 1 ? datos[1] : null;

            return {
              'nombre': variableNombres[varId]?['nombre'] ?? '—',
              'descripcion': variableNombres[varId]?['descripcion'] ?? '—',
              'valor_esperado': ultimo['valor_esperado'] ?? '—',
              'valor': ultimo['valor'] ?? '—',
              'penultimo': penultimo?['valor'] ?? '—',
            };
          }).toList();

      _log.i('Resultados procesados: ${resultados.length}');
      return resultados;
    } catch (e, stack) {
      _log.e(
        'Error al obtener evaluaciones con variables',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  Widget buildTitledGrid(String title, Map<String, dynamic> fields) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeTransition(
            opacity: _animationController,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 3, 105, 7),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 3 / 1.5,
            ),
            itemCount: fields.length,
            itemBuilder: (context, index) {
              final entry = fields.entries.elementAt(index);
              return FadeTransition(
                opacity: _animationController,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            entry.value?.toString().isNotEmpty == true
                                ? entry.value.toString()
                                : '—',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildTablaRendimiento() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchEvaluacionesConVariables(widget.dni),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No hay datos de rendimiento.',
              style: TextStyle(color: Colors.green),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color.fromARGB(255, 2, 63, 4),
                ),
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return const Color.fromARGB(255, 200, 255, 200);
                  }
                  return null;
                }),
                columns: const [
                  DataColumn(label: Text('Variable')),
                  DataColumn(label: Text('Esperado')),
                  DataColumn(label: Text('Penúltimo')),
                  DataColumn(label: Text('Último')),
                ],
                rows:
                    data.map((row) {
                      return DataRow(
                        cells: [
                          DataCell(
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: Container(
                                          padding: const EdgeInsets.all(12),
                                          color: Colors.green.shade700,
                                          child: Text(
                                            row['nombre'].toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        content: Container(
                                          color: Colors.white,
                                          padding: const EdgeInsets.all(16),
                                          child: Text(
                                            row['descripcion'].toString(),
                                            style: const TextStyle(
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                );
                              },
                              child: Text(
                                row['nombre'].toString(),
                                style: const TextStyle(
                                  color: Colors.green,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),

                          DataCell(Text(row['valor_esperado'].toString())),
                          DataCell(Text(row['penultimo'].toString())),
                          DataCell(
                            Text(
                              row['valor'].toString(),
                              style: const TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildAdminPage() {
    if (userData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final fields = {
      'Nombres': userData!['firstname'],
      'Apellidos': userData!['surname'],
      'DNI': userData!['dni'],
      'Tipo de sangre': userData!['tipo_sangre'],
      'Correo': userData!['mail'],
      'Dirección': userData!['address'],
      'Nacimiento': _formatDate(userData!['date_birthday']),
      'Lugar de nacimiento': userData!['lugar_nacimiento'],
      'Nombre de mamá': userData!['name_mama'],
      'Nombre de papá': userData!['name_papa'],
      'Teléfono': userData!['phone'],
      'Tel. Emergencia': userData!['phone_emergencia'],
      'Tel. Mamá': userData!['phone_mama'],
      'Tel. Papá': userData!['phone_papa'],
      'Seguro': userData!['seguro_'],
      'Sexo': _formatSexo(userData!['sexo']),
      'Centro de estudios': userData!['study_center'],
      'Tutor legal': userData!['tutor_legal'],
    };

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTitledGrid('Información administrativa', fields),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Historial de pagos',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 2, 92, 2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('PRS_MOVEMENT')
                      .where('id_cliente_ioon', isEqualTo: userDocId)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay historial de pagos.',
                      style: TextStyle(color: Color.fromARGB(255, 38, 133, 41)),
                    ),
                  );
                }

                final payments = snapshot.data!.docs;

                return Container(
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        const Color.fromARGB(255, 2, 63, 4), // Verde oscuro
                      ),
                      headingTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      dataRowColor: WidgetStateProperty.resolveWith<Color?>((
                        Set<WidgetState> states,
                      ) {
                        if (states.contains(WidgetState.hovered)) {
                          return const Color.fromARGB(255, 27, 104, 30);
                        }
                        return null;
                      }),
                      columns: const [
                        DataColumn(label: Text('Cliente')),
                        DataColumn(label: Text('Monto')),
                        DataColumn(label: Text('Fecha')),
                        DataColumn(label: Text('Descripción')),
                      ],
                      rows:
                          payments.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(data['name_cliente_ioon'] ?? '—'),
                                ),
                                DataCell(
                                  Text(
                                    'S/ ${data['amount_payment']?.toStringAsFixed(2) ?? '0.00'}',
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                ),
                                DataCell(
                                  Text(_formatDate(data['date_payment'])),
                                ),
                                DataCell(Text(data['description'] ?? '—')),
                              ],
                            );
                          }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget buildSportPage() {
    if (userData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final fields = {
      'Altura': userData!['altura'],
      'Peso': userData!['peso'],
      'Enfermedad 1': userData!['enfermedad_1'],
      'Enfermedad 2': userData!['enfermedad_2'],
      'Lesión 1': userData!['lesion_1'],
      'Lesión 2': userData!['lesion_2'],
      'Alergia 1': userData!['alergia_1'],
      'Alergia 2': userData!['alergia_2'],
      'Alergia 3': userData!['alergia_3'],
      'Alergia 4': userData!['alergia_4'],
      'Extra 1': userData!['extra1'],
      'Extra 2': userData!['extra2'],
    };

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTitledGrid('Información médica/deportiva', fields),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Rendimiento',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 2, 92, 2),
              ),
            ),
          ),
          buildTablaRendimiento(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      buildAdminPage(),
      buildSportPage(),
      const Center(
        child: Text('Galería de Fotos', style: TextStyle(fontSize: 24)),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.bungeeInline(
            textStyle: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 2, 63, 4),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  static String _formatDate(dynamic millis) {
    if (millis == null) return '—';
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    return '${date.day}/${date.month}/${date.year}';
  }

  static String _formatSexo(dynamic value) {
    if (value == 1) return 'Masculino';
    if (value == 0) return 'Femenino';
    return '—';
  }
}
