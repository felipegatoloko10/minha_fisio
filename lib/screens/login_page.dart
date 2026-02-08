import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/biometric_service.dart';
import 'dashboard_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  final String? initialEmail;
  final String? initialPassword;
  const LoginPage({super.key, this.initialEmail, this.initialPassword});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
    _passwordController = TextEditingController(text: widget.initialPassword);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBiometricLogin());
  }

  void _checkBiometricLogin() async {
    bool enabled = await StorageService.isBiometricEnabled();
    if (enabled) {
      String? email = await StorageService.getLastUserEmail();
      if (email != null) {
        bool authenticated = await BiometricService.authenticate();
        if (authenticated) {
          final users = await StorageService.getUsers();
          final user = users.firstWhere((u) => u['email'] == email, orElse: () => {});
          if (user.isNotEmpty) {
            if (!mounted) return;
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardPage(user: user)));
          }
        }
      }
    }
  }

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha todos os campos'), backgroundColor: Colors.orange));
      return;
    }

    final users = await StorageService.getUsers();
    final user = users.firstWhere(
      (u) => u['email'] == email && u['password'] == password,
      orElse: () => {},
    );

    if (user.isNotEmpty) {
      if (!mounted) return;
      
      bool bioEnabled = await StorageService.isBiometricEnabled();
      bool canBio = await BiometricService.canAuthenticate();
      
      if (!bioEnabled && canBio) {
        bool? wantBio = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Login por Digital"),
            content: const Text("Deseja habilitar o acesso por biometria para os próximos acessos?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("AGORA NÃO")),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("SIM, HABILITAR")),
            ],
          )
        );
        if (wantBio == true) {
          await StorageService.setBiometricEnabled(true, user['email']);
        }
      }

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardPage(user: user)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('E-mail ou senha incorretos'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Image.asset('assets/icon/logo.png', height: 120),
              const SizedBox(height: 16),
              const Text('Minha Fisio', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _login, child: const Text('ENTRAR'))),
              const SizedBox(height: 16),
              FutureBuilder<bool>(
                future: StorageService.isBiometricEnabled(),
                builder: (context, snapshot) {
                  if (snapshot.data == true) {
                    return IconButton(
                      icon: const Icon(Icons.fingerprint, size: 40, color: Colors.blue),
                      onPressed: _checkBiometricLogin,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())), child: const Text('Não tem conta? Cadastre-se')),
            ],
          ),
        ),
      ),
    );
  }
}
