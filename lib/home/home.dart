import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smarthome/home/colors.dart';
import 'package:smarthome/home/firebase.dart';
import 'package:smarthome/home/notif.dart';

// Constants

// Models
class DeviceModel {
  final String name;
  final String iconPath;
  bool isOn;

  DeviceModel({required this.name, required this.iconPath, this.isOn = false});
}

class EnvironmentData {
  final double temperature;
  final double humidity;
  final bool flameDetected;

  EnvironmentData({
    required this.temperature,
    required this.humidity,
    required this.flameDetected,
  });

  static EnvironmentData defaultData() => EnvironmentData(
        temperature: 0.0,
        humidity: 0.0,
        flameDetected: false,
      );
}

class EnergyData {
  final double current;
  final double power;
  final double totalEnergy;
  final double todayConsumption;
  final double cost;

  // Energy price in Tunisia (as of 2024, approximate rates)
  static const double _energyPricePerKWh = 0.135; // Tunisian Dinars per kWh

  EnergyData({
    required this.current,
    required this.power,
    required this.totalEnergy,
    required this.todayConsumption,
    required this.cost,
  });

  // Factory method to calculate cost based on total energy
  factory EnergyData.calculate({
    required double current,
    required double power,
    required double totalEnergy,
  }) {
    // Calculate today's consumption (simplified example)
    double todayConsumption =
        totalEnergy * 0.2; // Assume 20% of total is today's

    // Calculate cost in Tunisian Dinars
    double cost = totalEnergy * _energyPricePerKWh;

    return EnergyData(
      current: current,
      power: power,
      totalEnergy: totalEnergy,
      todayConsumption: todayConsumption,
      cost: cost,
    );
  }

  static EnergyData defaultData() => EnergyData.calculate(
        current: 0.0,
        power: 0.0,
        totalEnergy: 0.0,
      );
}

// Notification Service

// Main App and Home Page
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<DeviceModel> _devices = [
    DeviceModel(name: "Smart Light", iconPath: "assets/images/icons/idea.svg"),
    DeviceModel(name: "Smart Camera", iconPath: "assets/images/icons/cam.svg"),
    DeviceModel(name: "Smart Fan", iconPath: "assets/images/icons/fan.svg"),
    DeviceModel(name: "Smart AC", iconPath: "assets/images/icons/air.svg"),
  ];

  late Stream<EnvironmentData> _environmentStream;
  late Stream<EnergyData> _energyStream;
  String _userName = 'User'; // Default fallback name

  @override
  void initState() {
    super.initState();
    NotificationService.initNotifications();
    _environmentStream = FirebaseService.watchEnvironmentData();
    _energyStream = FirebaseService.watchEnergyData();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    try {
      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Fetch user document from Firestore
        var userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        // Update the username if found
        if (userDoc.exists) {
          setState(() {
            _userName = userDoc.data()?['fullName'] ?? 'User';
          });
        }
      }
    } catch (e) {
      print('Error fetching user name: $e');
      // Keep the default 'User' name if there's an error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          key: const ValueKey('homeScrollView'), // Unique key
          slivers: [
            _buildAppBar(),
            _buildWelcomeSection(),
            _buildEnvironmentCard(),
            _buildEnergyMonitorCard(),
            _buildDevicesTitle(),
            _buildDevicesGrid(),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildAppBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset("assets/images/logo.png", height: 40),
            CircleAvatar(
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildWelcomeSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bienvenue chez vous",
              style: TextStyle(fontSize: 18, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              _userName, // Use the fetched or default username
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildEnvironmentCard() {
    return SliverToBoxAdapter(
      child: StreamBuilder<EnvironmentData>(
        stream: _environmentStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? EnvironmentData.defaultData();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Card(
              color: AppColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Good Morning, $_userName",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 24,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Environment",
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 32,
                              ),
                        ),
                        Icon(
                          Icons.air,
                          color: AppColors.primary,
                          size: 48,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildEnvironmentItem(
                          icon: Icons.thermostat,
                          value: "${data.temperature.toStringAsFixed(1)}°C",
                          label: "Temperature",
                          color: AppColors.primary,
                        ),
                        _buildEnvironmentItem(
                          icon: Icons.water_drop,
                          value: "${data.humidity.toStringAsFixed(1)}%",
                          label: "Humidity",
                          color: AppColors.accentColor,
                        ),
                        _buildEnvironmentItem(
                          icon: data.flameDetected
                              ? Icons.warning_rounded
                              : Icons.check_circle,
                          value: data.flameDetected ? "Alert" : "Normal",
                          label: "Flame Status",
                          color: data.flameDetected ? Colors.red : Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnvironmentItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textPrimary.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildEnergyMonitorCard() {
    return SliverToBoxAdapter(
      child: StreamBuilder<EnergyData>(
        stream: _energyStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? EnergyData.defaultData();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Card(
              color: AppColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Consommation Électrique",
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Rapport de consommation et de facturation",
                      style: TextStyle(
                        color: AppColors.textPrimary.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${data.totalEnergy.toStringAsFixed(0)} kWh",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.electric_bolt,
                              color: Colors.yellow,
                              size: 32,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "Consommation Totale",
                              style: TextStyle(
                                color: AppColors.textPrimary.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildEnergyConsumptionChart(data),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildEnergyItem(
                          "Aujourd'hui",
                          "${data.todayConsumption.toStringAsFixed(0)} kWh",
                          true,
                        ),
                        _buildEnergyItem(
                          "Coût",
                          "${data.cost.toStringAsFixed(2)} DT",
                          false,
                        ),
                        _buildEnergyItem(
                          "Puissance",
                          "${data.power.toStringAsFixed(1)} W",
                          false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnergyConsumptionChart(EnergyData data) {
    return SizedBox(
      height: 150,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _generateChartSpots(data),
              isCurved: true,
              color: Colors.yellow,
              barWidth: 4,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.yellow.withOpacity(0.5),
                    Colors.yellow.withOpacity(0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _generateChartSpots(EnergyData data) {
    // This is a simplified example. In a real app, you'd fetch historical data
    return [
      FlSpot(0, data.todayConsumption * 0.1),
      FlSpot(1, data.todayConsumption * 0.3),
      FlSpot(2, data.todayConsumption * 0.5),
      FlSpot(3, data.todayConsumption * 0.7),
      FlSpot(4, data.todayConsumption),
    ];
  }

  // Modify the existing energy item method to support glassmorphism theme
  Widget _buildEnergyItem(String label, String value, bool isToday) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isToday ? 20 : 16,
            color: isToday ? Colors.yellow : Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildDevicesTitle() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Appareils Intelligents",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: AppColors.primary,
              ),
            ),
            Text(
              "Turn on all",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverGrid _buildDevicesGrid() {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85, // Adjusted to prevent overflow
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildDeviceCard(_devices[index], index),
        childCount: _devices.length,
      ),
    );
  }

  Widget _buildDeviceCard(DeviceModel device, int index) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: device.isOn ? Colors.white : Colors.grey.shade200,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  device.iconPath,
                  width: 45,
                  height: 45,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 8),
                Text(
                  device.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: device.isOn ? AppColors.primary : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  device.isOn ? "On" : "Off",
                  style: TextStyle(
                    color: device.isOn ? AppColors.primary : Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Switch(
                  value: device.isOn,
                  onChanged: (bool value) {
                    setState(() {
                      device.isOn = value;
                      FirebaseService.toggleDeviceState(value);
                    });
                  },
                  activeColor: AppColors.primary,
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
