import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dni_selection_screen.dart';
import 'register_screen.dart';
import 'eval_rendim_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      try {
        // Primero, verifica si el correo está en la colección 'Admins'
        final adminSnapshot =
            await FirebaseFirestore.instance
                .collection('Admins')
                .where('mail', isEqualTo: email)
                .get();

        if (adminSnapshot.docs.isNotEmpty) {
          // Si es un admin, navega a la pantalla de evaluación
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EvalRendimScreen(email: email),
            ),
          );
          return;
        }

        // Si no está en Admins, busca en 'IOON_CLIENTE'
        final clientSnapshot =
            await FirebaseFirestore.instance
                .collection('IOON_CLIENTE')
                .where('mail', isEqualTo: email)
                .get();

        if (clientSnapshot.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Correo no registrado en la base de datos")),
          );
          return;
        }

        final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(
          email,
        );

        if (methods.isEmpty) {
          bool? confirm = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text('Crear cuenta'),
                  content: Text(
                    'El correo está registrado en la base de datos pero no tiene una cuenta. ¿Deseas crear una con la contraseña ingresada?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Crear'),
                    ),
                  ],
                ),
          );

          if (confirm == true) {
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
          } else {
            return;
          }
        } else {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        }

        // Si el correo está en 'IOON_CLIENTE', navega a la pantalla de selección de DNI
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DniSelectionScreen(email: email),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 5, 44, 0),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Image.asset('images/osos_logo.png', height: 150),
                SizedBox(height: 10),
                Text(
                  'Iniciar sesión',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "Correo electrónico",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Ingrese su correo'
                              : null,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Ingrese su contraseña'
                              : null,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text(
                    "Iniciar sesión",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterScreen()),
                    );
                  },
                  child: Text(
                    "¿No tienes una cuenta? Regístrate aquí",
                    style: TextStyle(
                      color: Colors.blueAccent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
