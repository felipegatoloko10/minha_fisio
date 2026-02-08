import 'dart:convert';

class SessionModel {
  DateTime date;
  String time;
  String status;

  SessionModel({
    required this.date,
    required this.time,
    this.status = 'Pendente',
  });

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String().split('T')[0],
        'time': time,
        'status': status,
      };

  factory SessionModel.fromMap(Map<String, dynamic> map) => SessionModel(
        date: DateTime.parse(map['date']),
        time: map['time'],
        status: map['status'],
      );
}

class TreatmentModel {
  int id;
  String nome;
  String profissional;
  int total;
  DateTime startDate; // Novo campo
  List<int> daysIndices;
  List<SessionModel> sessions;

  TreatmentModel({
    required this.id,
    required this.nome,
    required this.profissional,
    required this.total,
    required this.startDate,
    required this.daysIndices,
    required this.sessions,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'profissional': profissional,
        'total': total,
        'start_date': startDate.toIso8601String().split('T')[0],
        'days_indices': json.encode(daysIndices),
        'sessions': json.encode(sessions.map((s) => s.toMap()).toList()),
      };

  factory TreatmentModel.fromMap(Map<String, dynamic> map) {
    return TreatmentModel(
      id: map['id'],
      nome: map['nome'] ?? map['info']?['nome'],
      profissional: map['profissional'] ?? map['info']?['profissional'],
      total: map['total'] ?? map['info']?['total'],
      startDate: DateTime.parse(map['start_date'] ?? map['info']?['start_date'] ?? DateTime.now().toIso8601String()),
      daysIndices: map['days_indices'] is String 
          ? List<int>.from(json.decode(map['days_indices']))
          : List<int>.from(map['info']?['days_indices'] ?? []),
      sessions: (map['sessions'] is String 
              ? json.decode(map['sessions']) as List 
              : map['sessions'] as List)
          .map((s) => SessionModel.fromMap(s))
          .toList(),
    );
  }
}