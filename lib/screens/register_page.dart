import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _passwordController, obscureText: _obscurePassword, decoration: InputDecoration(labelText: 'Senha', border: const OutlineInputBorder(), suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)))),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () async {
              final name = _nameController.text.trim();
              final email = _emailController.text.trim();
              final password = _passwordController.text.trim();

              if (name.isEmpty || email.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha todos os campos'), backgroundColor: Colors.orange));
                return;
              }

              if (await StorageService.saveUser({'name': name, 'email': email, 'password': password})) {
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => LoginPage(initialEmail: email, initialPassword: password)), (r) => false);
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Este e-mail já está cadastrado'), backgroundColor: Colors.red));
              }
            }, child: const Text('CADASTRAR'))),
          ],
        ),
      ),
    );
  }
}
