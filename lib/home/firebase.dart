import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:smarthome/home/home.dart';
import 'package:smarthome/home/notif.dart';

class FirebaseService {
  static final DatabaseReference _database =
      FirebaseDatabase.instance.ref(); // Updated method to get the reference.

  static bool _previousFlameDetected = false; // Track the previous flame state.

  /// Stream to watch the environment data.
  static Stream<EnvironmentData> watchEnvironmentData() {
    return _database.child('EnergyMonitor').onValue.map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) {
        return EnvironmentData.defaultData();
      }
      try {
        final currentData = EnvironmentData(
          temperature: _parseDoubleValue(data['temperature']),
          humidity: _parseDoubleValue(data['humidity']),
          flameDetected: _parseBoolValue(data['flame_detected']),
        );

        // Check if flame_detected is true and notify if it wasn't true before.
        if (currentData.flameDetected && !_previousFlameDetected) {
          NotificationService.sendFlameAlert();
        }

        // Update the previous flame state.
        _previousFlameDetected = currentData.flameDetected;

        return currentData;
      } catch (e) {
        debugPrint('Error parsing environment data: $e');
        return EnvironmentData.defaultData();
      }
    });
  }

  /// Stream to watch the energy data.
  static Stream<EnergyData> watchEnergyData() {
    return _database.child('EnergyMonitor').onValue.map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) {
        return EnergyData.defaultData();
      }
      try {
        return EnergyData.calculate(
          current: _parseDoubleValue(data['Current']),
          power: _parseDoubleValue(data['Power']),
          totalEnergy: _parseDoubleValue(data['TotalEnergy']),
        );
      } catch (e) {
        debugPrint('Error parsing energy data: $e');
        return EnergyData.defaultData();
      }
    });
  }

  /// Utility method to safely parse double values
  static double _parseDoubleValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    try {
      return double.parse(value.toString());
    } catch (e) {
      debugPrint('Could not parse value to double: $value');
      return 0.0;
    }
  }

  /// Utility method to safely parse boolean values
  static bool _parseBoolValue(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    return value.toString().toLowerCase() == 'true';
  }

  /// Method to toggle the device state (e.g., LED control).
  static Future<void> toggleDeviceState(bool state) async {
    try {
      await _database
          .child('EnergyMonitor/bouton')
          .set(state)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        debugPrint('Firebase toggle timeout');
        throw TimeoutException('Device state toggle timed out');
      });
      debugPrint('Device state toggled to: $state');
    } catch (e) {
      debugPrint('Error toggling device state: $e');
      // Optionally, add user-facing error handling or retry mechanism
    }
  }
}
