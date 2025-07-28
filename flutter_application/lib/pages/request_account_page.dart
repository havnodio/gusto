import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application/pages/login_page.dart';

class RequestAccountPage extends StatefulWidget {
  const RequestAccountPage({super.key});

  @override
  State<RequestAccountPage> createState() => _RequestAccountPageState();
}

class _RequestAccountPageState extends State<RequestAccountPage> {
  final nameController = TextEditingController();
  final surnameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  Future<void> _signUp() async {
    final name = nameController.text.trim();
    final surname = surnameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (name.isEmpty ||
        surname.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() {
        errorMessage = 'Veuillez remplir tous les champs';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        errorMessage = 'Les mots de passe ne correspondent pas';
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        errorMessage = 'Le mot de passe doit contenir au moins 8 caractères';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse(
          'https://flutter-backend-xhrw.onrender.com/api/users/register',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'surname': surname,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte créé avec succès ! Veuillez vous connecter.'),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        setState(() {
          errorMessage =
              jsonDecode(response.body)['message'] ??
              'Échec de la création du compte';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur: $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    surnameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un compte', style: TextStyle(fontSize: 24)),
        backgroundColor: Colors.grey[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nom',
                border: const OutlineInputBorder(),
                errorText: errorMessage != null && nameController.text.isEmpty
                    ? 'Champ requis'
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: surnameController,
              decoration: InputDecoration(
                labelText: 'Prénom',
                border: const OutlineInputBorder(),
                errorText:
                    errorMessage != null && surnameController.text.isEmpty
                    ? 'Champ requis'
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: const OutlineInputBorder(),
                errorText: errorMessage != null && emailController.text.isEmpty
                    ? 'Champ requis'
                    : null,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                border: const OutlineInputBorder(),
                errorText:
                    errorMessage != null && passwordController.text.isEmpty
                    ? 'Champ requis'
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirmer votre mot de passe',
                border: const OutlineInputBorder(),
                errorText:
                    errorMessage != null &&
                        confirmPasswordController.text.isEmpty
                    ? 'Champ requis'
                    : null,
              ),
            ),
            if (errorMessage != null &&
                nameController.text.isNotEmpty &&
                surnameController.text.isNotEmpty &&
                emailController.text.isNotEmpty &&
                passwordController.text.isNotEmpty &&
                confirmPasswordController.text.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 30),
            isLoading
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 14,
                      ),
                    ),
                    onPressed: _signUp,
                    child: const Text(
                      'Créer',
                      style: TextStyle(fontSize: 22, color: Colors.white),
                    ),
                  ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text('Déjà un compte ? Se connecter'),
            ),
          ],
        ),
      ),
    );
  }
}
