// register_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum RegisterMode { newUser, newDni }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  RegisterMode? _mode; // null = elección inicial

  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {
    'firstname': TextEditingController(),
    'surname': TextEditingController(),
    'dni': TextEditingController(),
    'mail': TextEditingController(),
    'password': TextEditingController(),
    'address': TextEditingController(),
    'altura': TextEditingController(),
    'peso': TextEditingController(),
    'date_birthday': TextEditingController(),
    'extra1': TextEditingController(),
    'extra2': TextEditingController(),
    'enfermedad_1': TextEditingController(),
    'enfermedad_2': TextEditingController(),
    'lesion_1': TextEditingController(),
    'lesion_2': TextEditingController(),
    'lugar_nacimiento': TextEditingController(),
    'name_mama': TextEditingController(),
    'name_papa': TextEditingController(),
    'phone': TextEditingController(),
    'phone_emergencia': TextEditingController(),
    'phone_mama': TextEditingController(),
    'phone_papa': TextEditingController(),
    'seguro_': TextEditingController(),
    'sexo': TextEditingController(),
    'study_center': TextEditingController(),
    'tipo_sangre': TextEditingController(),
    'tutor_legal': TextEditingController(),
    'alergia_1': TextEditingController(),
    'alergia_2': TextEditingController(),
    'alergia_3': TextEditingController(),
    'alergia_4': TextEditingController(),
  };

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = controllers['mail']!.text.trim();
    final dni = controllers['dni']!.text.trim();
    final pw = controllers['password']!.text.trim();

    // Construir datos comunes
    final data = <String, dynamic>{
      'dni': dni,
      'mail': email,
      'date_register': DateTime.now().millisecondsSinceEpoch,
    };
    controllers.forEach((k, c) {
      if (k == 'password') return;
      final val = c.text.trim();
      if (val.isEmpty) return;
      if (k == 'sexo' || k == 'date_birthday') {
        data[k] = int.tryParse(val) ?? 0;
      } else {
        data[k] = val;
      }
    });

    try {
      // Guardar en Firestore
      await FirebaseFirestore.instance.collection('IOON_CLIENTE').add(data);

      // Registrar en Auth si es nuevo usuario
      if (_mode == RegisterMode.newUser) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: pw,
        );
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Registro exitoso")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al registrar: $e")));
    }
  }

  Widget _buildTextField(
    String key,
    String label, {
    bool obscure = false,
    TextInputType? inputType,
    bool optional = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controllers[key],
        obscureText: obscure,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Colors.black),
          ),
        ),
        validator: (v) {
          if (optional) return null;
          if (v == null || v.isEmpty) return 'Ingrese $label';
          return null;
        },
      ),
    );
  }

  Widget _formForMode() {
    final isNewUser = _mode == RegisterMode.newUser;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 5, 44, 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Image.asset('images/osos_logo.png', height: 120),
                const SizedBox(height: 12),
                Text(
                  isNewUser ? 'Registro nuevo usuario' : 'Agregar nuevo DNI',
                  style: const TextStyle(fontSize: 20, color: Colors.green),
                ),
                const SizedBox(height: 12),

                // Campos comunes
                _buildTextField('firstname', 'Nombres'),
                _buildTextField('surname', 'Apellidos'),
                _buildTextField('dni', 'DNI', inputType: TextInputType.number),
                _buildTextField(
                  'mail',
                  'Correo electrónico',
                  inputType: TextInputType.emailAddress,
                ),

                // Contraseña solo para nuevo usuario
                if (isNewUser)
                  _buildTextField('password', 'Contraseña', obscure: true),

                // Resto de campos
                _buildTextField('address', 'Dirección'),
                _buildTextField('altura', 'Altura', optional: true),
                _buildTextField('peso', 'Peso', optional: true),
                _buildTextField(
                  'date_birthday',
                  'Fecha de nacimiento (ms)',
                  optional: true,
                ),
                _buildTextField('extra1', 'Extra 1', optional: true),
                _buildTextField('extra2', 'Extra 2', optional: true),
                _buildTextField('enfermedad_1', 'Enfermedad 1', optional: true),
                _buildTextField('enfermedad_2', 'Enfermedad 2', optional: true),
                _buildTextField('lesion_1', 'Lesión 1', optional: true),
                _buildTextField('lesion_2', 'Lesión 2', optional: true),
                _buildTextField('lugar_nacimiento', 'Lugar de nacimiento'),
                _buildTextField('name_mama', 'Nombre de mamá'),
                _buildTextField('name_papa', 'Nombre de papá'),
                _buildTextField('phone', 'Teléfono'),
                _buildTextField('phone_emergencia', 'Teléfono emergencia'),
                _buildTextField('phone_mama', 'Teléfono mamá'),
                _buildTextField('phone_papa', 'Teléfono papá'),
                _buildTextField('seguro_', 'Seguro'),
                _buildTextField('sexo', 'Sexo (1: M, 2: F)', optional: false),
                _buildTextField('study_center', 'Centro de estudios'),
                _buildTextField('tipo_sangre', 'Tipo de sangre'),
                _buildTextField('tutor_legal', 'Tutor legal'),
                _buildTextField('alergia_1', 'Alergia 1', optional: true),
                _buildTextField('alergia_2', 'Alergia 2', optional: true),
                _buildTextField('alergia_3', 'Alergia 3', optional: true),
                _buildTextField('alergia_4', 'Alergia 4', optional: true),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    isNewUser ? 'Registrar usuario' : 'Agregar DNI',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla inicial de elección
    if (_mode == null) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 5, 44, 0),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Elija su forma de registro',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => setState(() => _mode = RegisterMode.newUser),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Registrar un nuevo usuario',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => setState(() => _mode = RegisterMode.newDni),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Agregar nuevo jugador a correo existente',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Formulario según el modo
    return _formForMode();
  }
}
