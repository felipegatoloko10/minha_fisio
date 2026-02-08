import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MinhaFisioApp());
}

class MinhaFisioApp extends StatelessWidget {
  const MinhaFisioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minha Fisio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade800),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      locale: const Locale('pt', 'BR'),
      home: const LoginPage(),
    );
  }
}

class StorageService {
  static const String _usersKey = 'users_list';
  static const String _treatmentsKey = 'all_treatments_list';

  static Future<List<dynamic>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? usersRaw = prefs.getString(_usersKey);
    return usersRaw != null ? json.decode(usersRaw) : [];
  }

  static Future<bool> saveUser(Map<String, String> user) async {
    final prefs = await SharedPreferences.getInstance();
    List<dynamic> users = await getUsers();
    if (users.any((u) => u['email'] == user['email'])) return false;
    users.add(user);
    return await prefs.setString(_usersKey, json.encode(users));
  }

  static Future<void> addTreatment(Map<String, dynamic> treatment) async {
    final prefs = await SharedPreferences.getInstance();
    List<dynamic> treatments = await getTreatments();
    treatments.add(treatment);
    await prefs.setString(_treatmentsKey, json.encode(treatments));
  }

  static Future<List<dynamic>> getTreatments() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_treatmentsKey);
    return raw != null ? json.decode(raw) : [];
  }

  static Future<void> updateTreatments(List<dynamic> treatments) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_treatmentsKey, json.encode(treatments));
  }
}

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
  }

  void _login() async {
    final users = await StorageService.getUsers();
    final user = users.firstWhere(
      (u) => u['email'] == _emailController.text && u['password'] == _passwordController.text,
      orElse: () => null,
    );
    if (user != null) {
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
              const Icon(Icons.medical_services, size: 80, color: Colors.blue),
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
              TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())), child: const Text('Não tem conta? Cadastre-se')),
            ],
          ),
        ),
      ),
    );
  }
}

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
              if (await StorageService.saveUser({'name': _nameController.text, 'email': _emailController.text, 'password': _passwordController.text})) {
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => LoginPage(initialEmail: _emailController.text, initialPassword: _passwordController.text)), (r) => false);
              }
            }, child: const Text('CADASTRAR'))),
          ],
        ),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  final dynamic user;
  const DashboardPage({super.key, required this.user});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  List<dynamic> _treatments = [];
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final data = await StorageService.getTreatments();
    int? currentIndex = _tabController?.index;
    
    setState(() { 
      _treatments = data; 
      // FIX: Preserva o index da aba atual ao recarregar os dados
      _tabController = TabController(
        length: _treatments.length, 
        vsync: this,
        initialIndex: (currentIndex != null && currentIndex < _treatments.length) ? currentIndex : 0
      );
    });
  }

  void _deleteCurrentTreatment() async {
    if (_tabController == null) return;
    int idx = _tabController!.index;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir Tratamento"),
        content: Text("Deseja realmente excluir '${_treatments[idx]['info']['nome']}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () async {
              _treatments.removeAt(idx);
              await StorageService.updateTreatments(_treatments);
              Navigator.pop(ctx);
              _loadData();
            }, 
            child: const Text("EXCLUIR", style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, ${widget.user['name'].split(' ')[0]}'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()))),
        ],
        bottom: _treatments.isEmpty 
          ? null 
          : TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: _treatments.map((t) => Tab(text: t['info']['nome'])).toList(),
            ),
      ),
      body: _treatments.isEmpty
          ? Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTreatmentPage())).then((_) => _loadData()),
                child: const Text("ADICIONAR PRIMEIRO TRATAMENTO"),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: _treatments.map((t) => TreatmentView(
                    treatment: t, 
                    onChanged: (updated) async {
                      int idx = _treatments.indexWhere((item) => item['id'] == updated['id']);
                      _treatments[idx] = updated;
                      await StorageService.updateTreatments(_treatments);
                      // Ao chamar _loadData aqui, o TabController será recriado mantendo o index.
                      _loadData();
                    },
                  )).toList(),
            ),
      floatingActionButton: _treatments.isEmpty ? null : Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: "delete",
            backgroundColor: Colors.red.shade100,
            onPressed: _deleteCurrentTreatment,
            child: const Icon(Icons.delete, color: Colors.red),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: "edit",
            backgroundColor: Colors.blue.shade100,
            onPressed: () {
              int idx = _tabController!.index;
              Navigator.push(context, MaterialPageRoute(builder: (_) => CreateTreatmentPage(treatmentToEdit: _treatments[idx]))).then((_) => _loadData());
            },
            child: const Icon(Icons.edit, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "add",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTreatmentPage())).then((_) => _loadData()),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class TreatmentView extends StatefulWidget {
  final dynamic treatment;
  final Function(dynamic) onChanged;
  const TreatmentView({super.key, required this.treatment, required this.onChanged});

  @override
  State<TreatmentView> createState() => _TreatmentViewState();
}

class _TreatmentViewState extends State<TreatmentView> {
  late dynamic _t;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _t = widget.treatment;
  }

  @override
  void didUpdateWidget(TreatmentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _t = widget.treatment;
  }

  String _getEndDate() {
    List<dynamic> sessions = _t['sessions'];
    if (sessions.isEmpty) return "N/A";
    List<DateTime> dates = sessions.map((s) => DateTime.parse(s['date'])).toList();
    dates.sort();
    return DateFormat('dd/MM/yyyy').format(dates.last);
  }

  String _getNextSession() {
    List<dynamic> sessions = _t['sessions'];
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    
    List<dynamic> pending = sessions.where((s) {
      DateTime sDate = DateTime.parse(s['date']);
      return s['status'] == 'Pendente' && (sDate.isAfter(today) || sDate.isAtSameMomentAs(today));
    }).toList();

    if (pending.isEmpty) return "Nenhuma sessão pendente";
    
    pending.sort((a, b) => a['date'].compareTo(b['date']));
    var next = pending.first;
    DateTime date = DateTime.parse(next['date']);
    return "Próxima sessão: ${DateFormat('dd/MM').format(date)} às ${next['time']}";
  }

  void _showStatusPicker(DateTime day) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    int index = _t['sessions'].indexWhere((s) => s['date'] == dateStr);
    if (index == -1) return;
    final session = _t['sessions'][index];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Sessão de ${DateFormat('dd/MM').format(day)} às ${session['time']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _statusTile(Icons.check_circle, Colors.blue, "Realizada", index),
              _statusTile(Icons.cancel, Colors.red, "Cancelada", index),
              _statusTile(Icons.update, Colors.purple, "Remarcada", index),
              _statusTile(Icons.hourglass_empty, Colors.orange, "Pendente", index),
            ],
          ),
        );
      }
    );
  }

  Widget _statusTile(IconData icon, Color color, String status, int index) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(status),
      onTap: () => _updateStatus(index, status),
    );
  }

  void _updateStatus(int index, String status) async {
    String oldStatus = _t['sessions'][index]['status'];
    if (oldStatus == status) { Navigator.pop(context); return; }
    
    if (status == "Remarcada") {
      Navigator.pop(context); 
      DateTime? newDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        helpText: 'DATA DA REMARCAÇÃO',
      );
      if (newDate != null) {
        String newDateStr = DateFormat('yyyy-MM-dd').format(newDate);
        int existingIdx = _t['sessions'].indexWhere((s) => s['date'] == newDateStr);
        
        if (existingIdx != -1) {
          if (!mounted) return;
          bool? editTime = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Aviso"),
              content: const Text("Esse dia já faz parte do tratamento. Deseja editar a hora do tratamento nesse dia?"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("NÃO")),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("SIM")),
              ],
            )
          );
          
          if (editTime == true) {
            TimeOfDay? newTime = await showTimePicker(
              context: context,
              initialTime: const TimeOfDay(hour: 14, minute: 0),
              helpText: 'NOVO HORÁRIO',
            );
            if (newTime != null) {
              setState(() {
                _t['sessions'][existingIdx]['time'] = '${newTime.hour}:${newTime.minute.toString().padLeft(2, '0')}';
                _t['sessions'][existingIdx]['status'] = 'Pendente';
                _t['sessions'][index]['status'] = 'Pendente'; 
              });
              widget.onChanged(_t);
            }
          }
        } else {
          TimeOfDay? newTime = await showTimePicker(
            context: context,
            initialTime: const TimeOfDay(hour: 14, minute: 0),
            helpText: 'HORÁRIO DA REMARCAÇÃO',
          );
          if (newTime != null) {
            setState(() {
              _t['sessions'][index]['status'] = 'Remarcada';
              _t['sessions'].add({
                'date': newDateStr,
                'status': 'Pendente',
                'time': '${newTime.hour}:${newTime.minute.toString().padLeft(2, '0')}'
              });
            });
            widget.onChanged(_t);
          }
        }
      }
      return;
    }

    setState(() { _t['sessions'][index]['status'] = status; });
    
    if (status == "Cancelada" && oldStatus != "Cancelada") { 
      _addSessionAtEnd(); 
    }
    else if (oldStatus == "Cancelada" && (status == "Pendente" || status == "Realizada")) { 
      _removeLastSession(); 
    }
    
    Navigator.pop(context);
    widget.onChanged(_t);
  }

  void _addSessionAtEnd() {
    List<DateTime> dates = (_t['sessions'] as List).map((s) => DateTime.parse(s['date'])).toList();
    dates.sort();
    DateTime lastDate = dates.last;
    List<int> targetDays = List<int>.from(_t['info']['days_indices'] ?? []);
    if (targetDays.isEmpty) return;
    DateTime nextDate = lastDate.add(const Duration(days: 1));
    while (!targetDays.contains(nextDate.weekday)) { nextDate = nextDate.add(const Duration(days: 1)); }
    _t['sessions'].add({
      'date': DateFormat('yyyy-MM-dd').format(nextDate),
      'status': 'Pendente',
      'time': _t['sessions'].first['time']
    });
  }

  void _removeLastSession() {
    if (_t['sessions'].length > (_t['info']['total'] ?? 0)) {
      (_t['sessions'] as List).sort((a, b) => a['date'].compareTo(b['date']));
      (_t['sessions'] as List).removeLast();
    }
  }

  @override
  Widget build(BuildContext context) {
    int originalTotal = _t['info']['total'] ?? 0;
    int done = (_t['sessions'] as List).where((s) => s['status'] == 'Realizada').length;
    double progress = originalTotal > 0 ? (done / originalTotal).clamp(0.0, 1.0) : 0;
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_t['info']['nome'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Profissional: ${_t['info']['profissional']}', style: const TextStyle(fontSize: 14, color: Colors.blueGrey)),
                  const SizedBox(height: 12),
                  LinearPercentIndicator(animation: true, lineHeight: 15, percent: progress, center: Text("${(progress * 100).toInt()}%"), progressColor: Colors.blue.shade700, backgroundColor: Colors.white, barRadius: const Radius.circular(10)),
                  const SizedBox(height: 8),
                  Text('$done de $originalTotal sessões realizadas', style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          TableCalendar(
            locale: 'pt_BR',
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: 'Mês'},
            onDaySelected: (s, f) { setState(() => _focusedDay = f); _showStatusPicker(s); },
            calendarBuilders: CalendarBuilders(
              prioritizedBuilder: (context, day, focusedDay) {
                final dateStr = DateFormat('yyyy-MM-dd').format(day);
                final sessionsOnDay = (_t['sessions'] as List).where((s) => s['date'] == dateStr).toList();
                
                // Verifica se é hoje para adicionar o destaque
                bool isToday = day.year == today.year && day.month == today.month && day.day == today.day;

                if (sessionsOnDay.isNotEmpty) {
                  final status = sessionsOnDay.first['status'];
                  Color color = Colors.orange.shade400;
                  if (status == 'Realizada') color = Colors.blue.shade600;
                  if (status == 'Cancelada') color = Colors.red.shade600;
                  if (status == 'Remarcada') color = Colors.purple.shade600;
                  
                  return Container(
                    margin: const EdgeInsets.all(4), 
                    alignment: Alignment.center, 
                    decoration: BoxDecoration(
                      color: color, 
                      shape: BoxShape.circle,
                      // FIX: Se for hoje, coloca uma borda preta para destacar mantendo a cor do status
                      border: isToday ? Border.all(color: Colors.black, width: 2) : null,
                    ), 
                    child: Text(day.day.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                  );
                } else if (isToday) {
                  // Se for hoje mas não tiver sessão, apenas o visual padrão do hoje
                  return Container(
                    margin: const EdgeInsets.all(4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                    child: Text(day.day.toString(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  );
                }
                return null;
              },
            ),
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                Text(_getNextSession(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                Text("Término previsto: ${_getEndDate()}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_legendaItem(Colors.orange, "Pendente"), _legendaItem(Colors.blue, "Realizada"), _legendaItem(Colors.red, "Cancelada"), _legendaItem(Colors.purple, "Remarcada")]),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _legendaItem(Color c, String t) => Row(children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)), const SizedBox(width: 4), Text(t, style: const TextStyle(fontSize: 10))]);
}

class CreateTreatmentPage extends StatefulWidget {
  final dynamic treatmentToEdit;
  const CreateTreatmentPage({super.key, this.treatmentToEdit});

  @override
  State<CreateTreatmentPage> createState() => _CreateTreatmentPageState();
}

class _CreateTreatmentPageState extends State<CreateTreatmentPage> {
  final _qtdController = TextEditingController();
  final _nomeController = TextEditingController();
  final _profController = TextEditingController();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 0);
  final List<bool> _selectedDays = List.generate(7, (_) => false);
  final List<String> _dayNames = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  @override
  void initState() {
    super.initState();
    if (widget.treatmentToEdit != null) {
      _nomeController.text = widget.treatmentToEdit['info']['nome'];
      _profController.text = widget.treatmentToEdit['info']['profissional'];
      _qtdController.text = widget.treatmentToEdit['info']['total'].toString();
      List<int> days = List<int>.from(widget.treatmentToEdit['info']['days_indices']);
      for (int d in days) { _selectedDays[d - 1] = true; }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.treatmentToEdit != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar Tratamento' : 'Novo Tratamento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nome do Tratamento:', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _nomeController),
            const SizedBox(height: 16),
            const Text('Nome do Profissional:', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _profController),
            const SizedBox(height: 16),
            const Text('Total de sessões:', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _qtdController, keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            const Text('Dias da semana:', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(spacing: 8, children: List.generate(7, (i) => FilterChip(label: Text(_dayNames[i]), selected: _selectedDays[i], onSelected: (v) => setState(() => _selectedDays[i] = v)))),
            const SizedBox(height: 24),
            ListTile(title: Text("Horário: ${_selectedTime.format(context)}"), trailing: const Icon(Icons.access_time), onTap: () async { final t = await showTimePicker(context: context, initialTime: _selectedTime); if (t != null) setState(() => _selectedTime = t); }),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                int qtd = int.parse(_qtdController.text);
                List<int> targetDays = [];
                for (int i = 0; i < 7; i++) { if (_selectedDays[i]) targetDays.add(i + 1); }

                if (isEditing) {
                  List<dynamic> treatments = await StorageService.getTreatments();
                  int idx = treatments.indexWhere((t) => t['id'] == widget.treatmentToEdit['id']);
                  treatments[idx]['info'] = {
                    'total': qtd, 
                    'days_indices': targetDays,
                    'nome': _nomeController.text,
                    'profissional': _profController.text,
                  };
                  await StorageService.updateTreatments(treatments);
                } else {
                  List<dynamic> sessions = [];
                  DateTime current = DateTime.now();
                  int count = 0;
                  while (count < qtd) {
                    if (targetDays.contains(current.weekday)) {
                      sessions.add({'date': DateFormat('yyyy-MM-dd').format(current), 'status': 'Pendente', 'time': '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}'});
                      count++;
                    }
                    current = current.add(const Duration(days: 1));
                  }
                  await StorageService.addTreatment({
                    'id': DateTime.now().millisecondsSinceEpoch,
                    'info': {
                      'total': qtd, 
                      'days_indices': targetDays,
                      'nome': _nomeController.text,
                      'profissional': _profController.text,
                    }, 
                    'sessions': sessions
                  });
                }
                if (!mounted) return;
                Navigator.pop(context);
              }, 
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), 
              child: Text(isEditing ? 'SALVAR ALTERAÇÕES' : 'CRIAR TRATAMENTO')
            ),
          ],
        ),
      ),
    );
  }
}