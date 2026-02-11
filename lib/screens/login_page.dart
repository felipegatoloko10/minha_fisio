import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
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
    
    // Tenta login biométrico ao iniciar, se disponível/configurado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptBiometricLogin();
    });
  }

  Future<void> _attemptBiometricLogin() async {
    final controller = context.read<AuthController>();
    // AuthController já verifica disponibilidade no construtor, mas é assíncrono.
    // Vamos dar um pequeno delay ou esperar que a UI reaja.
    // Melhor: chamar um método que verifica e loga.
    final user = await controller.loginWithBiometrics();
    if (user != null && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardPage(user: user)));
    }
  }

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha todos os campos')));
      return;
    }

    final controller = context.read<AuthController>();
    final user = await controller.login(email, password);

    if (!mounted) return;

    if (user != null) {
      // Se tiver biometria disponível mas não habilitada pro user, pergunta se quer habilitar
      if (controller.isBiometricAvailable && !controller.isBiometricEnabled) {
        // Verifica se o usuário não rejeitou recentemente (poderíamos salvar isso em prefs, mas por hora pergunta sempre)
        bool? enableBio = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Habilitar Biometria?"),
            content: const Text("Deseja usar sua impressão digital/face para entrar na próxima vez?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Agora não")),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Sim")),
            ],
          )
        );
        if (enableBio == true) {
          await controller.toggleBiometrics(true, email);
        }
      } else if (controller.isBiometricEnabled) {
         // Atualiza o email para garantir que o último logado é este
         await controller.toggleBiometrics(true, email);
      }
      
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardPage(user: user)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(controller.error ?? 'Falha no login'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/icon/logo.png', height: 120),
              const SizedBox(height: 32),
              const Text(
                'Minha Fisio',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: controller.isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ENTRAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              if (controller.isBiometricEnabled && !controller.isLoading)
                IconButton(
                  icon: const Icon(Icons.fingerprint, size: 40, color: Color(0xFF1565C0)),
                  onPressed: _attemptBiometricLogin,
                  tooltip: 'Entrar com biometria',
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                child: const Text('Não tem conta? Cadastre-se'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
