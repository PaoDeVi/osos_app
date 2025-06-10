// register_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

enum RegisterMode { newUser, newDni }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  RegisterMode? _mode;

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

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = controllers['mail']!.text.trim();
    final dni = controllers['dni']!.text.trim();
    final pw = controllers['password']!.text.trim();

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
      await FirebaseFirestore.instance.collection('IOON_CLIENTE').add(data);

      /*await FirebaseFirestore.instance.collection('PENDING_IOON_CLIENTE').add({
        ...data,
        'status': 'pending',
      });*/

      if (_mode == RegisterMode.newUser) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: pw,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registro exitoso - Espere su validación"),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al registrar: $e")));
    }
  }

  Widget animatedButton({required String label, required VoidCallback onTap}) {
    bool _pressed = false;
    return StatefulBuilder(
      builder:
          (context, setInnerState) => GestureDetector(
            onTapDown: (_) => setInnerState(() => _pressed = true),
            onTapUp: (_) => setInnerState(() => _pressed = false),
            onTapCancel: () => setInnerState(() => _pressed = false),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              decoration: BoxDecoration(
                color: _pressed ? Colors.green.shade700 : Colors.green,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Text(
                label,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
    );
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
        style: const TextStyle(color: Colors.white), // texto blanco
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white),
          filled: true,
          fillColor: const Color.fromARGB(255, 39, 97, 39), // verde oscuro
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.green, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Colors.lightGreenAccent,
              width: 1.5,
            ),
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
        child: FadeTransition(
          opacity: _fadeAnimation,
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
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          color: Colors.black45,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildTextField('firstname', 'Nombres'),
                  _buildTextField('surname', 'Apellidos'),
                  _buildTextField(
                    'dni',
                    'DNI',
                    inputType: TextInputType.number,
                  ),
                  _buildTextField(
                    'mail',
                    'Correo electrónico',
                    inputType: TextInputType.emailAddress,
                  ),
                  if (isNewUser)
                    _buildTextField('password', 'Contraseña', obscure: true),

                  _buildTextField('address', 'Dirección'),
                  _buildTextField('altura', 'Altura', optional: false),
                  _buildTextField('peso', 'Peso', optional: false),
                  _buildTextField(
                    'date_birthday',
                    'Fecha de nacimiento (ms)',
                    optional: false,
                  ),
                  _buildTextField('extra1', 'Extra 1', optional: true),
                  _buildTextField('extra2', 'Extra 2', optional: true),
                  _buildTextField(
                    'enfermedad_1',
                    'Enfermedad 1',
                    optional: true,
                  ),
                  _buildTextField(
                    'enfermedad_2',
                    'Enfermedad 2',
                    optional: true,
                  ),
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
                  animatedButton(
                    label: isNewUser ? 'Registrar usuario' : 'Agregar DNI',
                    onTap: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == null) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 5, 44, 0),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Elija su forma de registro',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 20),
              animatedButton(
                label: 'Registrar un nuevo usuario',
                onTap: () => setState(() => _mode = RegisterMode.newUser),
              ),
              const SizedBox(height: 15),
              animatedButton(
                label: 'Agregar nuevo jugador a correo existente',
                onTap: () => setState(() => _mode = RegisterMode.newDni),
              ),
            ],
          ),
        ),
      );
    }

    return _formForMode();
  }
}
