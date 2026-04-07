enum ServiceStatus { completed, scheduled, upcoming }

extension ServiceStatusX on ServiceStatus {
  String get displayName {
    switch (this) {
      case ServiceStatus.completed:
        return 'Concluído';
      case ServiceStatus.scheduled:
        return 'Agendado';
      case ServiceStatus.upcoming:
        return 'Em breve';
    }
  }

  String get apiValue {
    switch (this) {
      case ServiceStatus.completed:
        return 'COMPLETED';
      case ServiceStatus.scheduled:
        return 'SCHEDULED';
      case ServiceStatus.upcoming:
        return 'UPCOMING';
    }
  }

  static ServiceStatus fromApiValue(String value) {
    switch (value.toUpperCase()) {
      case 'COMPLETED':
        return ServiceStatus.completed;
      case 'SCHEDULED':
        return ServiceStatus.scheduled;
      case 'UPCOMING':
        return ServiceStatus.upcoming;
      default:
        throw ArgumentError('Unknown status: $value');
    }
  }
}

class Service {
  final String id;
  final String serviceType;
  final DateTime date;
  final String? notes;
  final ServiceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Service({
    required this.id,
    required this.serviceType,
    required this.date,
    this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  String get formattedDate {
    final months = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];
    return '${date.day} ${months[date.month - 1].toUpperCase()} ${date.year}';
  }

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as String,
      serviceType: json['serviceType'] as String,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
      status: ServiceStatusX.fromApiValue(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceType': serviceType,
      'date': date.toIso8601String(),
      'notes': notes,
      'status': status.apiValue,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Service copyWith({
    String? id,
    String? serviceType,
    DateTime? date,
    String? notes,
    ServiceStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Service(
      id: id ?? this.id,
      serviceType: serviceType ?? this.serviceType,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Service(id: $id, serviceType: $serviceType, date: $date, status: $status)';
}

class ServiceResponse {
  final List<Service> data;
  final PaginationInfo pagination;
  final String message;

  ServiceResponse({
    required this.data,
    required this.pagination,
    required this.message,
  });

  factory ServiceResponse.fromJson(Map<String, dynamic> json) {
    final items = (json['data'] as List)
        .map((e) => Service.fromJson(e as Map<String, dynamic>))
        .toList();

    final paginationJson = json['pagination'] as Map<String, dynamic>;
    final pagination = PaginationInfo(
      page: paginationJson['page'] as int,
      limit: paginationJson['limit'] as int,
      total: paginationJson['total'] as int,
      pages: paginationJson['pages'] as int,
    );

    return ServiceResponse(
      data: items,
      pagination: pagination,
      message: json['message'] as String,
    );
  }
}

class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int pages;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });
}

class ServiceStats {
  final int total;
  final int completed;
  final int scheduled;
  final int upcoming;

  ServiceStats({
    required this.total,
    required this.completed,
    required this.scheduled,
    required this.upcoming,
  });

  factory ServiceStats.fromJson(Map<String, dynamic> json) {
    return ServiceStats(
      total: json['total'] as int,
      completed: json['completed'] as int,
      scheduled: json['scheduled'] as int,
      upcoming: json['upcoming'] as int,
    );
  }
}
