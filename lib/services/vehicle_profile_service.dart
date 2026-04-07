import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_auth_service.dart';
import 'vehicle_api.dart';

class VehicleProfileData {
  final String model;
  final String year;
  final String plate;
  final int totalKm;

  const VehicleProfileData({
    required this.model,
    required this.year,
    required this.plate,
    required this.totalKm,
  });
}

class MileageSummary {
  final int? currentTotalKm;
  final int monthlyDistanceKm;
  final bool hasCurrentMonthEntry;

  const MileageSummary({
    required this.currentTotalKm,
    required this.monthlyDistanceKm,
    required this.hasCurrentMonthEntry,
  });
}

class KmHistoryEntry {
  final DateTime recordedAt;
  final int totalKm;

  const KmHistoryEntry({
    required this.recordedAt,
    required this.totalKm,
  });

  factory KmHistoryEntry.fromJson(Map<String, dynamic> json) {
    final dateRaw = (json['recordedAt'] ?? json['date'] ?? '').toString();
    final parsed = DateTime.tryParse(dateRaw)?.toUtc() ?? DateTime.now().toUtc();
    final kmRaw = json['totalKm'];
    final totalKm = kmRaw is num ? kmRaw.toInt() : 0;

    return KmHistoryEntry(
      recordedAt: parsed,
      totalKm: totalKm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recordedAt': recordedAt.toUtc().toIso8601String(),
      'totalKm': totalKm,
    };
  }
}

class VehicleProfileService {
  static const _profileKeyPrefix = 'carsync.vehicle.profile';
  static const _profilesKeyPrefix = 'carsync.vehicle.profiles';
  static const _activeProfileKeyPrefix = 'carsync.vehicle.active_profile';
  static const _monthlyKmKeyPrefix = 'carsync.vehicle.monthly_km';
  static const _kmEntriesKeyPrefix = 'carsync.vehicle.km_entries';
  static const _guestScope = 'guest';
  static final Map<String, List<VehicleProfileData>> _memoryProfilesByScope =
      <String, List<VehicleProfileData>>{};
  static final Map<String, String> _memoryActiveProfileByScope =
      <String, String>{};
  static final Map<String, Map<String, int>> _memoryHistoryByVehicleKey =
      <String, Map<String, int>>{};
    static final Map<String, int> _memoryRemoteTotalKmByVehicleKey =
      <String, int>{};
  static final Map<String, List<KmHistoryEntry>> _memoryKmEntriesByVehicleKey =
      <String, List<KmHistoryEntry>>{};

  static Future<List<KmHistoryEntry>> listKmHistory({
    String? plate,
    int limit = 24,
  }) async {
    final scope = await _currentScope();
    final active = await getProfile();
    final selectedPlate = plate ?? active?.plate;
    if (selectedPlate == null || selectedPlate.trim().isEmpty) {
      return const <KmHistoryEntry>[];
    }

    final memoryKey = _vehicleHistoryMemoryKey(scope, selectedPlate);

    try {
      final prefs = await SharedPreferences.getInstance();
      var entries = await _loadKmEntriesForVehicle(prefs, scope, selectedPlate);

      if (entries.isEmpty) {
        entries = await _buildEntriesFromMonthlySnapshot(
          prefs,
          scope,
          selectedPlate,
        );

        if (entries.isNotEmpty) {
          _memoryKmEntriesByVehicleKey[memoryKey] =
              List<KmHistoryEntry>.from(entries);
          await prefs.setString(
            _kmEntriesKeyForVehicle(scope, selectedPlate),
            jsonEncode(entries.map((entry) => entry.toJson()).toList()),
          );
        }
      }

      final sortedDesc = List<KmHistoryEntry>.from(entries)
        ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

      if (limit > 0 && sortedDesc.length > limit) {
        return sortedDesc.sublist(0, limit);
      }
      return sortedDesc;
    } on MissingPluginException {
      final entries =
          List<KmHistoryEntry>.from(_memoryKmEntriesByVehicleKey[memoryKey] ?? const <KmHistoryEntry>[])
            ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      if (limit > 0 && entries.length > limit) {
        return entries.sublist(0, limit);
      }
      return entries;
    } on PlatformException {
      final entries =
          List<KmHistoryEntry>.from(_memoryKmEntriesByVehicleKey[memoryKey] ?? const <KmHistoryEntry>[])
            ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      if (limit > 0 && entries.length > limit) {
        return entries.sublist(0, limit);
      }
      return entries;
    } catch (_) {
      final entries =
          List<KmHistoryEntry>.from(_memoryKmEntriesByVehicleKey[memoryKey] ?? const <KmHistoryEntry>[])
            ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      if (limit > 0 && entries.length > limit) {
        return entries.sublist(0, limit);
      }
      return entries;
    }
  }

  static Future<List<VehicleProfileData>> listProfiles() async {
    final scope = await _currentScope();

    try {
      final prefs = await SharedPreferences.getInstance();
      var profiles = _loadProfilesFromPrefs(prefs, scope);

      // Migrate legacy single-profile storage into the new list format.
      if (profiles.isEmpty) {
        final legacyRaw = prefs.getString(_profileKeyForScope(scope));
        if (legacyRaw != null && legacyRaw.isNotEmpty) {
          final decoded = jsonDecode(legacyRaw);
          if (decoded is Map<String, dynamic>) {
            final migrated = VehicleProfileData(
              model: (decoded['model'] ?? '').toString(),
              year: (decoded['year'] ?? '').toString(),
              plate: (decoded['plate'] ?? '').toString(),
              totalKm: ((decoded['totalKm'] ?? 0) as num).toInt(),
            );

            if (migrated.model.trim().isNotEmpty &&
                migrated.plate.trim().isNotEmpty) {
              profiles = [migrated];
              await _persistProfilesToPrefs(prefs, scope, profiles);
              final normalizedPlate = _normalizePlate(migrated.plate);
              await prefs.setString(
                _activeProfileKeyForScope(scope),
                normalizedPlate,
              );

              await _migrateLegacyMonthlyHistoryIfNeeded(
                prefs,
                scope,
                migrated.plate,
              );
            }
          }
        }
      }

      if (profiles.isNotEmpty) {
        var active = prefs.getString(_activeProfileKeyForScope(scope));
        if (active == null || active.isEmpty) {
          active = _normalizePlate(profiles.first.plate);
          await prefs.setString(_activeProfileKeyForScope(scope), active);
        }

        _memoryActiveProfileByScope[scope] = active;
      }

      // Backend sync: if API is available and has vehicles, use backend as source of truth.
      try {
        final remoteVehicles = await VehicleApi.listVehicles();
        if (remoteVehicles.isNotEmpty) {
          for (final vehicle in remoteVehicles) {
            _memoryRemoteTotalKmByVehicleKey[
                    _vehicleHistoryMemoryKey(scope, vehicle.plate)] =
                vehicle.totalKm;
          }

          final localByPlate = <String, VehicleProfileData>{
            for (final profile in profiles)
              _normalizePlate(profile.plate): profile,
          };

          profiles = remoteVehicles
              .map(
                (vehicle) {
                  final normalizedPlate = _normalizePlate(vehicle.plate);
                  final localProfile = localByPlate[normalizedPlate];
                  final mergedTotalKm = localProfile != null
                      ? (vehicle.totalKm >= localProfile.totalKm
                          ? vehicle.totalKm
                          : localProfile.totalKm)
                      : vehicle.totalKm;

                  return VehicleProfileData(
                    model: vehicle.model,
                    year: vehicle.year,
                    plate: vehicle.plate,
                    totalKm: mergedTotalKm,
                  );
                },
              )
              .toList();

          await _persistProfilesToPrefs(prefs, scope, profiles);

          var active = prefs.getString(_activeProfileKeyForScope(scope));
          final hasActiveInRemote = active != null &&
              active.isNotEmpty &&
              profiles.any(
                (profile) => _normalizePlate(profile.plate) == active,
              );

          if (!hasActiveInRemote) {
            active = _normalizePlate(profiles.first.plate);
            await prefs.setString(_activeProfileKeyForScope(scope), active);
          }

          _memoryActiveProfileByScope[scope] = active;
        }
      } catch (_) {
        // Keep local fallback when backend is unreachable.
      }

      _memoryProfilesByScope[scope] = List<VehicleProfileData>.from(profiles);
      return profiles;
    } on MissingPluginException {
      return List<VehicleProfileData>.from(
        _memoryProfilesByScope[scope] ?? const <VehicleProfileData>[],
      );
    } on PlatformException {
      return List<VehicleProfileData>.from(
        _memoryProfilesByScope[scope] ?? const <VehicleProfileData>[],
      );
    } catch (_) {
      return List<VehicleProfileData>.from(
        _memoryProfilesByScope[scope] ?? const <VehicleProfileData>[],
      );
    }
  }

  static Future<VehicleProfileData?> getProfile() async {
    final scope = await _currentScope();
    final profiles = await listProfiles();
    if (profiles.isEmpty) {
      return null;
    }

    final activeNormalized =
        (_memoryActiveProfileByScope[scope] ?? '').trim().toUpperCase();
    final active = profiles.firstWhere(
      (profile) => _normalizePlate(profile.plate) == activeNormalized,
      orElse: () => profiles.first,
    );

    _memoryActiveProfileByScope[scope] = _normalizePlate(active.plate);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _activeProfileKeyForScope(scope),
        _normalizePlate(active.plate),
      );
    } on MissingPluginException {
      // Keep in-memory active profile only.
    } on PlatformException {
      // Keep in-memory active profile only.
    } catch (_) {
      // Best-effort persistence.
    }

    return active;
  }

  static Future<bool> setActiveProfileByPlate(String plate) async {
    final scope = await _currentScope();
    final normalized = _normalizePlate(plate);
    if (normalized.isEmpty) {
      return false;
    }

    final profiles = await listProfiles();
    final exists = profiles.any(
      (profile) => _normalizePlate(profile.plate) == normalized,
    );
    if (!exists) {
      return false;
    }

    _memoryActiveProfileByScope[scope] = normalized;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeProfileKeyForScope(scope), normalized);
    } on MissingPluginException {
      // Keep in-memory active profile only.
    } on PlatformException {
      // Keep in-memory active profile only.
    } catch (_) {
      // Best-effort persistence.
    }

    return true;
  }

  static Future<bool> deleteProfileByPlate(String plate) async {
    final scope = await _currentScope();
    final normalizedPlate = _normalizePlate(plate);
    if (normalizedPlate.isEmpty) {
      return false;
    }

    final profiles = await listProfiles();
    final target = profiles.where(
      (profile) => _normalizePlate(profile.plate) == normalizedPlate,
    );
    if (target.isEmpty) {
      return false;
    }

    try {
      await VehicleApi.deleteVehicleByPlate(plate);
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (!message.contains('veículo não encontrado') &&
          !message.contains('vehicle not found')) {
        rethrow;
      }
    }

    final updatedProfiles = profiles
        .where((profile) => _normalizePlate(profile.plate) != normalizedPlate)
        .toList();

    _memoryProfilesByScope[scope] = List<VehicleProfileData>.from(updatedProfiles);

    final memoryKey = _vehicleHistoryMemoryKey(scope, plate);
    _memoryHistoryByVehicleKey.remove(memoryKey);
    _memoryKmEntriesByVehicleKey.remove(memoryKey);
    _memoryRemoteTotalKmByVehicleKey.remove(memoryKey);

    final currentActive = _memoryActiveProfileByScope[scope] ?? '';
    final shouldSwitchActive =
        currentActive.isEmpty || currentActive == normalizedPlate;

    String? nextActive;
    if (updatedProfiles.isNotEmpty) {
      nextActive = shouldSwitchActive
          ? _normalizePlate(updatedProfiles.first.plate)
          : currentActive;
      _memoryActiveProfileByScope[scope] = nextActive;
    } else {
      _memoryActiveProfileByScope.remove(scope);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await _persistProfilesToPrefs(prefs, scope, updatedProfiles);

      await prefs.remove(_monthlyKmKeyForVehicle(scope, plate));
      await prefs.remove(_kmEntriesKeyForVehicle(scope, plate));

      if (nextActive != null && nextActive.isNotEmpty) {
        await prefs.setString(_activeProfileKeyForScope(scope), nextActive);
      } else {
        await prefs.remove(_activeProfileKeyForScope(scope));
      }
    } on MissingPluginException {
      // Keep in-memory changes only when plugin registration is stale.
    } on PlatformException {
      // Keep in-memory changes only when plugin registration is stale.
    } catch (_) {
      // Best-effort persistence.
    }

    return true;
  }

  static Future<void> saveProfile({
    required String model,
    required String year,
    required String plate,
    required int totalKm,
    DateTime? date,
  }) async {
    final scope = await _currentScope();
    final safeTotalKm = totalKm < 0 ? 0 : totalKm;
    final recordedAt = (date ?? DateTime.now()).toUtc();

    // Persist to backend first to enforce 1 user -> N vehicles and global plate uniqueness.
    final created = await VehicleApi.createVehicle(
      model: model,
      year: year,
      plate: plate,
      totalKm: safeTotalKm,
    );

    final normalizedPlate = _normalizePlate(created.plate);
    _memoryRemoteTotalKmByVehicleKey[
        _vehicleHistoryMemoryKey(scope, created.plate)] =
      created.totalKm;
    final profileToSave = VehicleProfileData(
      model: created.model,
      year: created.year,
      plate: created.plate,
      totalKm: created.totalKm,
    );

    final profiles = await listProfiles();
    final existingIndex = profiles.indexWhere(
      (item) => _normalizePlate(item.plate) == normalizedPlate,
    );
    if (existingIndex >= 0) {
      profiles[existingIndex] = profileToSave;
    } else {
      profiles.add(profileToSave);
    }

    _memoryProfilesByScope[scope] = List<VehicleProfileData>.from(profiles);
    _memoryActiveProfileByScope[scope] = normalizedPlate;

    final monthKey = _monthKey(date ?? DateTime.now());
    final memoryHistoryKey = _vehicleHistoryMemoryKey(scope, plate);
    final preloadedHistory = Map<String, int>.from(
      _memoryHistoryByVehicleKey[memoryHistoryKey] ?? const <String, int>{},
    );
    preloadedHistory[monthKey] = safeTotalKm;
    _memoryHistoryByVehicleKey[memoryHistoryKey] = preloadedHistory;

    try {
      final prefs = await SharedPreferences.getInstance();

      await _persistProfilesToPrefs(prefs, scope, profiles);
      await prefs.setString(_activeProfileKeyForScope(scope), normalizedPlate);

      final history = await _loadMonthlyHistoryForVehicle(prefs, scope, plate);
      history[monthKey] = safeTotalKm;
      _memoryHistoryByVehicleKey[memoryHistoryKey] =
          Map<String, int>.from(history);
      await prefs.setString(
        _monthlyKmKeyForVehicle(scope, plate),
        jsonEncode(history),
      );

      await _appendKmHistoryEntry(
        scope: scope,
        plate: created.plate,
        totalKm: safeTotalKm,
        recordedAt: recordedAt,
        prefs: prefs,
      );
    } on MissingPluginException {
      await _appendKmHistoryEntry(
        scope: scope,
        plate: created.plate,
        totalKm: safeTotalKm,
        recordedAt: recordedAt,
      );
      // Keep flow working even if plugin registry is stale.
    } on PlatformException {
      await _appendKmHistoryEntry(
        scope: scope,
        plate: created.plate,
        totalKm: safeTotalKm,
        recordedAt: recordedAt,
      );
      // Keep flow working even if plugin registry is stale.
    } catch (_) {
      await _appendKmHistoryEntry(
        scope: scope,
        plate: created.plate,
        totalKm: safeTotalKm,
        recordedAt: recordedAt,
      );
      // Best-effort local persistence.
    }
  }

  static Future<void> saveMonthlyKm({
    required int totalKm,
    DateTime? date,
  }) async {
    final scope = await _currentScope();
    final safeTotalKm = totalKm < 0 ? 0 : totalKm;
    final recordedAt = (date ?? DateTime.now()).toUtc();
    final monthKey = _monthKey(recordedAt);
    final activeProfile = await getProfile();
    if (activeProfile == null) {
      return;
    }

    final activePlate = activeProfile.plate;
    final baselineTotalKm = activeProfile.totalKm;
    final memoryHistoryKey = _vehicleHistoryMemoryKey(scope, activePlate);
    final preloadedHistory = Map<String, int>.from(
      _memoryHistoryByVehicleKey[memoryHistoryKey] ?? const <String, int>{},
    );
    preloadedHistory.putIfAbsent(monthKey, () => baselineTotalKm);
    _memoryHistoryByVehicleKey[memoryHistoryKey] = preloadedHistory;

    final profiles = await listProfiles();
    final normalizedActivePlate = _normalizePlate(activePlate);
    final updatedProfiles = profiles.map((profile) {
      if (_normalizePlate(profile.plate) != normalizedActivePlate) {
        return profile;
      }

      return VehicleProfileData(
        model: profile.model,
        year: profile.year,
        plate: profile.plate,
        totalKm: safeTotalKm,
      );
    }).toList();

    _memoryProfilesByScope[scope] =
        List<VehicleProfileData>.from(updatedProfiles);
    _memoryActiveProfileByScope[scope] = normalizedActivePlate;

    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await _loadMonthlyHistoryForVehicle(
        prefs,
        scope,
        activePlate,
      );
      history.putIfAbsent(monthKey, () => baselineTotalKm);
      _memoryHistoryByVehicleKey[memoryHistoryKey] =
          Map<String, int>.from(history);
      await prefs.setString(
        _monthlyKmKeyForVehicle(scope, activePlate),
        jsonEncode(history),
      );

      await _appendKmHistoryEntry(
        scope: scope,
        plate: activePlate,
        totalKm: safeTotalKm,
        recordedAt: recordedAt,
        prefs: prefs,
      );

      await _persistProfilesToPrefs(prefs, scope, updatedProfiles);
      await prefs.setString(
        _activeProfileKeyForScope(scope),
        normalizedActivePlate,
      );
    } on MissingPluginException {
      await _appendKmHistoryEntry(
        scope: scope,
        plate: activePlate,
        totalKm: safeTotalKm,
        recordedAt: recordedAt,
      );
      // Keep flow working even if plugin registry is stale.
    } on PlatformException {
      await _appendKmHistoryEntry(
        scope: scope,
        plate: activePlate,
        totalKm: safeTotalKm,
        recordedAt: recordedAt,
      );
      // Keep flow working even if plugin registry is stale.
    } catch (_) {
      await _appendKmHistoryEntry(
        scope: scope,
        plate: activePlate,
        totalKm: safeTotalKm,
        recordedAt: recordedAt,
      );
      // Best-effort local persistence.
    }
  }

  static Future<MileageSummary> getMileageSummary({
    DateTime? referenceDate,
  }) async {
    final scope = await _currentScope();
    final profile = await getProfile();
    if (profile == null) {
      return const MileageSummary(
        currentTotalKm: null,
        monthlyDistanceKm: 0,
        hasCurrentMonthEntry: false,
      );
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final now = referenceDate ?? DateTime.now();
      final currentMonthKey = _monthKey(now);

      var history =
          await _loadMonthlyHistoryForVehicle(prefs, scope, profile.plate);

      // Migrate legacy month history when there is only one vehicle.
      if (history.isEmpty) {
        final allProfiles = await listProfiles();
        if (allProfiles.length <= 1) {
          final legacyRaw = prefs.getString(_monthlyKmKeyForScope(scope));
          if (legacyRaw != null && legacyRaw.isNotEmpty) {
            final decodedLegacy = jsonDecode(legacyRaw);
            if (decodedLegacy is Map<String, dynamic>) {
              final legacyHistory = <String, int>{};
              decodedLegacy.forEach((key, value) {
                if (value is num) {
                  legacyHistory[key] = value.toInt();
                }
              });
              history = legacyHistory;
              await prefs.setString(
                _monthlyKmKeyForVehicle(scope, profile.plate),
                jsonEncode(history),
              );
            }
          }
        }
      }

      _memoryHistoryByVehicleKey[
              _vehicleHistoryMemoryKey(scope, profile.plate)] =
          Map<String, int>.from(history);
      final memoryKey = _vehicleHistoryMemoryKey(scope, profile.plate);
      final remoteTotalKm = _memoryRemoteTotalKmByVehicleKey[memoryKey];
      final originalBaseline = history[currentMonthKey];
      final currentTotalKm = profile.totalKm;
      final effectiveBaseline =
          _effectiveMonthlyBaseline(originalBaseline, currentTotalKm, remoteTotalKm);

      if (effectiveBaseline != originalBaseline) {
        if (effectiveBaseline == null) {
          history.remove(currentMonthKey);
        } else {
          history[currentMonthKey] = effectiveBaseline;
        }
        _memoryHistoryByVehicleKey[memoryKey] = Map<String, int>.from(history);
        await prefs.setString(
          _monthlyKmKeyForVehicle(scope, profile.plate),
          jsonEncode(history),
        );
      }

      final monthlyDistanceKm = effectiveBaseline != null
          ? (currentTotalKm - effectiveBaseline).clamp(0, 1000000)
          : 0;

      return MileageSummary(
        currentTotalKm: currentTotalKm,
        monthlyDistanceKm: monthlyDistanceKm,
        hasCurrentMonthEntry: effectiveBaseline != null,
      );
    } on MissingPluginException {
      return _memoryMileageSummary(scope, profile);
    } on PlatformException {
      return _memoryMileageSummary(scope, profile);
    } catch (_) {
      return _memoryMileageSummary(scope, profile);
    }
  }

  static String formatKm(int value) {
    final safe = value < 0 ? 0 : value;
    final formatted = safe
        .toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    return '$formatted km';
  }

  static Future<Map<String, int>> _loadMonthlyHistoryForVehicle(
    SharedPreferences prefs,
    String scope,
    String plate,
  ) async {
    final raw = prefs.getString(_monthlyKmKeyForVehicle(scope, plate));
    if (raw == null || raw.isEmpty) {
      return Map<String, int>.from(
        _memoryHistoryByVehicleKey[_vehicleHistoryMemoryKey(scope, plate)] ??
            const <String, int>{},
      );
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return Map<String, int>.from(
        _memoryHistoryByVehicleKey[_vehicleHistoryMemoryKey(scope, plate)] ??
            const <String, int>{},
      );
    }

    final result = <String, int>{};
    decoded.forEach((key, value) {
      if (value is num) {
        result[key] = value.toInt();
      }
    });

    return result;
  }

  static Future<List<KmHistoryEntry>> _loadKmEntriesForVehicle(
    SharedPreferences prefs,
    String scope,
    String plate,
  ) async {
    final raw = prefs.getString(_kmEntriesKeyForVehicle(scope, plate));
    if (raw == null || raw.isEmpty) {
      return List<KmHistoryEntry>.from(
        _memoryKmEntriesByVehicleKey[_vehicleHistoryMemoryKey(scope, plate)] ??
            const <KmHistoryEntry>[],
      );
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return List<KmHistoryEntry>.from(
        _memoryKmEntriesByVehicleKey[_vehicleHistoryMemoryKey(scope, plate)] ??
            const <KmHistoryEntry>[],
      );
    }

    final entries = decoded
        .whereType<Map<String, dynamic>>()
        .map(KmHistoryEntry.fromJson)
        .toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    return entries;
  }

  static Future<List<KmHistoryEntry>> _buildEntriesFromMonthlySnapshot(
    SharedPreferences prefs,
    String scope,
    String plate,
  ) async {
    final monthly = await _loadMonthlyHistoryForVehicle(prefs, scope, plate);
    if (monthly.isEmpty) {
      return const <KmHistoryEntry>[];
    }

    final entries = <KmHistoryEntry>[];
    for (final item in monthly.entries) {
      final date = _monthDate(item.key);
      if (date == null) {
        continue;
      }

      entries.add(
        KmHistoryEntry(
          recordedAt: date.toUtc(),
          totalKm: item.value,
        ),
      );
    }

    entries.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return entries;
  }

  static Future<void> _appendKmHistoryEntry({
    required String scope,
    required String plate,
    required int totalKm,
    required DateTime recordedAt,
    SharedPreferences? prefs,
  }) async {
    final memoryKey = _vehicleHistoryMemoryKey(scope, plate);
    final safeTotalKm = totalKm < 0 ? 0 : totalKm;

    final existing = prefs != null
        ? await _loadKmEntriesForVehicle(prefs, scope, plate)
        : List<KmHistoryEntry>.from(
            _memoryKmEntriesByVehicleKey[memoryKey] ?? const <KmHistoryEntry>[],
          );

    final normalizedTime = recordedAt.toUtc();
    if (existing.isNotEmpty) {
      final last = existing.last;
      final isSameKm = last.totalKm == safeTotalKm;
      final secondsDiff = normalizedTime
          .difference(last.recordedAt)
          .inSeconds
          .abs();
      if (isSameKm && secondsDiff <= 30) {
        return;
      }
    }

    existing.add(
      KmHistoryEntry(recordedAt: normalizedTime, totalKm: safeTotalKm),
    );
    existing.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    _memoryKmEntriesByVehicleKey[memoryKey] =
        List<KmHistoryEntry>.from(existing);

    if (prefs != null) {
      await prefs.setString(
        _kmEntriesKeyForVehicle(scope, plate),
        jsonEncode(existing.map((entry) => entry.toJson()).toList()),
      );
    }
  }

  static MileageSummary _memoryMileageSummary(
    String scope,
    VehicleProfileData profile,
  ) {
    final memoryKey = _vehicleHistoryMemoryKey(scope, profile.plate);
    final history = _memoryHistoryByVehicleKey[memoryKey] ??
        const <String, int>{};
    final now = DateTime.now();
    final currentMonthKey = _monthKey(now);
    final remoteTotalKm = _memoryRemoteTotalKmByVehicleKey[memoryKey];
    final currentMonthBaseline = _effectiveMonthlyBaseline(
      history[currentMonthKey],
      profile.totalKm,
      remoteTotalKm,
    );
    final currentTotalKm = profile.totalKm;
    final monthlyDistanceKm = currentMonthBaseline != null
        ? (currentTotalKm - currentMonthBaseline).clamp(0, 1000000)
        : 0;

    return MileageSummary(
      currentTotalKm: currentTotalKm,
      monthlyDistanceKm: monthlyDistanceKm,
      hasCurrentMonthEntry: currentMonthBaseline != null,
    );
  }

  static List<VehicleProfileData> _loadProfilesFromPrefs(
    SharedPreferences prefs,
    String scope,
  ) {
    final raw = prefs.getString(_profilesKeyForScope(scope));
    if (raw == null || raw.isEmpty) {
      return List<VehicleProfileData>.from(
        _memoryProfilesByScope[scope] ?? const <VehicleProfileData>[],
      );
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return List<VehicleProfileData>.from(
        _memoryProfilesByScope[scope] ?? const <VehicleProfileData>[],
      );
    }

    final profiles = <VehicleProfileData>[];
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final model = (item['model'] ?? '').toString();
      final year = (item['year'] ?? '').toString();
      final plate = (item['plate'] ?? '').toString();
      final totalKm = ((item['totalKm'] ?? 0) as num).toInt();

      if (model.trim().isEmpty || plate.trim().isEmpty) {
        continue;
      }

      profiles.add(
        VehicleProfileData(
          model: model,
          year: year,
          plate: plate,
          totalKm: totalKm,
        ),
      );
    }

    return profiles;
  }

  static Future<void> _persistProfilesToPrefs(
    SharedPreferences prefs,
    String scope,
    List<VehicleProfileData> profiles,
  ) async {
    final encoded = profiles
        .map(
          (profile) => {
            'model': profile.model,
            'year': profile.year,
            'plate': profile.plate,
            'totalKm': profile.totalKm,
          },
        )
        .toList();

    await prefs.setString(_profilesKeyForScope(scope), jsonEncode(encoded));
  }

  static Future<void> _migrateLegacyMonthlyHistoryIfNeeded(
    SharedPreferences prefs,
    String scope,
    String plate,
  ) async {
    final newKey = _monthlyKmKeyForVehicle(scope, plate);
    final hasNew = prefs.getString(newKey);
    if (hasNew != null && hasNew.isNotEmpty) {
      return;
    }

    final legacy = prefs.getString(_monthlyKmKeyForScope(scope));
    if (legacy == null || legacy.isEmpty) {
      return;
    }

    await prefs.setString(newKey, legacy);
  }

  static Future<String> _currentScope() async {
    final email = await LocalAuthService.getCurrentUserEmail();
    if (email == null || email.isEmpty) {
      return _guestScope;
    }
    return _sanitizeScope(email);
  }

  static String _profileKeyForScope(String scope) {
    return '$_profileKeyPrefix.$scope';
  }

  static String _profilesKeyForScope(String scope) {
    return '$_profilesKeyPrefix.$scope';
  }

  static String _activeProfileKeyForScope(String scope) {
    return '$_activeProfileKeyPrefix.$scope';
  }

  static String _monthlyKmKeyForScope(String scope) {
    return '$_monthlyKmKeyPrefix.$scope';
  }

  static String _monthlyKmKeyForVehicle(String scope, String plate) {
    return '$_monthlyKmKeyPrefix.$scope.${_plateStorageKey(plate)}';
  }

  static String _kmEntriesKeyForVehicle(String scope, String plate) {
    return '$_kmEntriesKeyPrefix.$scope.${_plateStorageKey(plate)}';
  }

  static String _vehicleHistoryMemoryKey(String scope, String plate) {
    return '$scope|${_plateStorageKey(plate)}';
  }

  static String _plateStorageKey(String plate) {
    return _sanitizeScope(_normalizePlate(plate));
  }

  static String _normalizePlate(String plate) {
    return plate.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  static String _sanitizeScope(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
  }

  static String _monthKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$year-$month';
  }

  static DateTime? _monthDate(String monthKey) {
    final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(monthKey);
    if (match == null) {
      return null;
    }

    final year = int.tryParse(match.group(1) ?? '');
    final month = int.tryParse(match.group(2) ?? '');
    if (year == null || month == null || month < 1 || month > 12) {
      return null;
    }

    return DateTime(year, month, 1);
  }

  static int? _effectiveMonthlyBaseline(
    int? storedBaseline,
    int currentTotalKm,
    int? remoteTotalKm,
  ) {
    if (storedBaseline == null) {
      return null;
    }

    // Legacy data could persist the latest odometer as monthly baseline,
    // or even keep a value higher than the current total.
    if (storedBaseline > currentTotalKm) {
      if (remoteTotalKm != null && remoteTotalKm <= currentTotalKm) {
        return remoteTotalKm;
      }
      return currentTotalKm;
    }

    return storedBaseline;
  }
}
