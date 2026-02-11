import 'package:flutter/material.dart';
import '../models/treatment_model.dart';
import '../repositories/treatment_repository.dart';
import '../services/notification_service.dart';
import '../utils/app_constants.dart';

class TreatmentController extends ChangeNotifier {
  final ITreatmentRepository _repository;
  
  List<TreatmentModel> _treatments = [];
  bool _isLoading = false;
  String? _error;

  List<TreatmentModel> get treatments => _treatments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  TreatmentController(this._repository);

  Future<void> loadTreatments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _treatments = await _repository.getTreatments();
    } catch (e) {
      _error = 'Erro ao carregar tratamentos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTreatment(TreatmentModel treatment) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.addTreatment(treatment);
      _treatments.add(treatment); // Otimista ou recarregar
      await loadTreatments(); // Recarrega para garantir ID e ordem
      await NotificationService.scheduleTreatmentNotifications(treatment, _treatments, isStatusUpdate: false);
    } catch (e) {
      _error = 'Erro ao adicionar tratamento';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTreatment(TreatmentModel treatment) async {
    try {
      await _repository.updateTreatment(treatment);
      int index = _treatments.indexWhere((t) => t.id == treatment.id);
      if (index != -1) {
        _treatments[index] = treatment;
        notifyListeners();
      }
      // Notificações são atualizadas aqui ou na UI? Idealmente aqui.
      // Mas o método scheduleTreatmentNotifications é estático por enquanto.
      await NotificationService.scheduleTreatmentNotifications(treatment, _treatments, isStatusUpdate: true);
    } catch (e) {
      print("Erro ao atualizar tratamento: $e");
      // Tratamento de erro mais robusto viria aqui
    }
  }

  Future<void> deleteTreatment(int id) async {
    try {
      await _repository.deleteTreatment(id);
      _treatments.removeWhere((t) => t.id == id);
      // Reagenda tudo para limpar as notificações do tratamento excluído
      await NotificationService.rescheduleAll(_treatments);
      notifyListeners();
    } catch (e) {
       print("Erro ao deletar: $e");
    }
  }

  // Lógica de Negócio: Atualizar Status da Sessão
  Future<void> updateSessionStatus(int treatmentId, int sessionIndex, String newStatus, {DateTime? newDate, String? newTime}) async {
    int tIndex = _treatments.indexWhere((t) => t.id == treatmentId);
    if (tIndex == -1) return;

    TreatmentModel treatment = _treatments[tIndex];
    var session = treatment.sessions[sessionIndex];
    String oldStatus = session.status;

    // Atualiza status localmente
    session.status = newStatus;
    
    // Lógica específica de Remarcação
    if (newStatus == AppConstants.statusRemarcada && newDate != null && newTime != null) {
       // Adiciona nova sessão
       treatment.sessions.add(SessionModel(date: newDate, time: newTime, status: AppConstants.statusPendente));
    }
    
    // Lógica de Cancelamento (Adicionar no final)
    if (newStatus == AppConstants.statusCancelada && oldStatus != AppConstants.statusCancelada) {
       _addSessionAtEnd(treatment);
    }
    // Reverter Cancelamento (Remover do final)
    else if (oldStatus == AppConstants.statusCancelada && (newStatus == AppConstants.statusPendente || newStatus == AppConstants.statusRealizada)) {
       _removeLastSession(treatment);
    }

    // Salva no banco
    await updateTreatment(treatment);
  }

  void _addSessionAtEnd(TreatmentModel t) {
    if (t.sessions.isEmpty) return;
    List<DateTime> dates = t.sessions.map((s) => s.date).toList()..sort();
    DateTime lastDate = dates.last;
    if (t.daysIndices.isEmpty) return;
    DateTime nextDate = lastDate.add(const Duration(days: 1));
    while (!t.daysIndices.contains(nextDate.weekday)) { 
      nextDate = nextDate.add(const Duration(days: 1)); 
    }
    t.sessions.add(SessionModel(
      date: nextDate,
      status: AppConstants.statusPendente,
      time: t.sessions.first.time
    ));
  }

  void _removeLastSession(TreatmentModel t) {
    if (t.sessions.length > t.total) {
      t.sessions.sort((a, b) => a.date.compareTo(b.date));
      t.sessions.removeLast();
    }
  }
}
