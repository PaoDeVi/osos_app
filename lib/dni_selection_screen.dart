import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'my_home_page.dart';

// Clase para almacenar los datos del cliente
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

class DniSelectionScreen extends StatelessWidget {
  final String email;

  const DniSelectionScreen({super.key, required this.email});

  // Función que obtiene los datos del cliente desde Firestore
  Future<List<ClienteData>> fetchDnis() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('IOON_CLIENTE')
            .where('mail', isEqualTo: email)
            .get();

    return snapshot.docs.map((doc) {
      return ClienteData(
        dni: doc['dni'].toString(),
        firstname: doc['firstname'] ?? '',
        surname: doc['surname'] ?? '',
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Lista de Jugadores Asociados",
          style: GoogleFonts.outfit(textStyle: TextStyle(color: Colors.white)),
        ),
        backgroundColor: const Color.fromARGB(255, 2, 63, 4),
      ),
      body: FutureBuilder<List<ClienteData>>(
        future: fetchDnis(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text("No se encontraron registros con este correo"),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              itemCount: snapshot.data!.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Dos columnas
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 3 / 2, // Ajusta esto según el contenido
              ),
              itemBuilder: (context, index) {
                final cliente = snapshot.data![index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => MyHomePage(
                              title: 'OSOS DE LA SALLE',
                              dni: cliente.dni,
                            ),
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
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: const Color.fromARGB(255, 4, 133, 8),
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(height: 8),
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
          );
        },
      ),
    );
  }
}
