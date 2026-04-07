import 'package:flutter/material.dart';

enum ServiceStatus { completed, upcoming, scheduled }

class ServiceModel {
  final int id;
  final String title;
  final String date;
  final ServiceStatus status;
  final Color dotColor;
  final Color badgeColor;
  final Color badgeBg;
  final String badge;
  final String? description;

  ServiceModel({
    required this.id,
    required this.title,
    required this.date,
    required this.status,
    required this.dotColor,
    required this.badgeColor,
    required this.badgeBg,
    required this.badge,
    this.description,
  });

  // Copy with method for updating status
  ServiceModel copyWith({
    String? title,
    String? date,
    ServiceStatus? status,
    Color? dotColor,
    Color? badgeColor,
    Color? badgeBg,
    String? badge,
    String? description,
  }) {
    return ServiceModel(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      status: status ?? this.status,
      dotColor: dotColor ?? this.dotColor,
      badgeColor: badgeColor ?? this.badgeColor,
      badgeBg: badgeBg ?? this.badgeBg,
      badge: badge ?? this.badge,
      description: description ?? this.description,
    );
  }
}
