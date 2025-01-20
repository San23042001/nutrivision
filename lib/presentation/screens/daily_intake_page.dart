import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nutrivision/logger.dart';
import 'package:nutrivision/presentation/widgets/date_selector.dart';
import 'package:nutrivision/presentation/widgets/detailed_nutrients_card.dart';
import 'package:nutrivision/presentation/widgets/food_history_card.dart';
import 'package:nutrivision/presentation/widgets/header_card.dart';
import 'package:nutrivision/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/macronutrien_summary_card.dart';

class DailyIntakePage extends StatefulWidget {
  final Map<String, double> dailyIntake;
  const DailyIntakePage({super.key, required this.dailyIntake});

  @override
  State<DailyIntakePage> createState() => _DailyIntakePageState();
}

class _DailyIntakePageState extends State<DailyIntakePage> {
  late Map<String, double> _dailyIntake;
  DateTime _selectedDate = DateTime.now();
  final Logic logic = Logic();
  final int _currentIndex = 2;

  @override
  void initState() {
    super.initState();
    _dailyIntake = widget.dailyIntake;
    _initializeData();
    logic.dailyIntakeNotifier.addListener(_onDailyIntakeChanged);
  }

  void _onDailyIntakeChanged() {
    if (mounted) {
      setState(() {
        _dailyIntake = Map.from(logic.dailyIntakeNotifier.value);
      });
    }
  }

  @override
  void dispose() {
    logic.dailyIntakeNotifier.removeListener(_onDailyIntakeChanged);
    super.dispose();
  }

  Future<void> _initializeData() async {
    logInfo("Initializing DailyIntakePage data...",
        "Initializing DailyIntakePage data...");

    // Debug check storage
    await logic.debugCheckStorage();

    // Load food history first
    logInfo("Loading food history...", "Loading food history...");

    await logic.loadFoodHistory();

    // Then load daily intake for selected date
    logInfo("Loading daily intake for selected date...",
        "Loading daily intake for selected date...");

    await _loadDailyIntake(DateTime.now());

    if (mounted) {
      setState(() {
        logInfo("State updated after initialization",
            "State updated after initialization");
        logInfo("Current daily intake:", "$_dailyIntake");
        logInfo("Current food history:", "${logic.foodHistory}");
      });
    }
  }

  Future<void> _loadDailyIntake(DateTime date) async {
    logInfo("Loading daily intake for date:", date.toString());

    final String storageKey = logic.getStorageKey(date);
    logInfo("Storage key:", storageKey);

    final prefs = await SharedPreferences.getInstance();
    final String? storedData = prefs.getString(storageKey);
    logInfo("Stored data from SharedPreferences", "$storedData");

    if (storedData != null) {
      logInfo("Found stored data, processing...",
          "Found stored data, processing...");

      final Map<String, dynamic> decoded = jsonDecode(storedData);
      final Map<String, double> dailyIntake = {};

      decoded.forEach((key, value) {
        logInfo("Converting $key:", "$value (${value.runtimeType}) to double");

        dailyIntake[key] = (value as num).toDouble();
      });

      if (mounted) {
        setState(() {
          _selectedDate = date;
          _dailyIntake = dailyIntake;
          logic.dailyIntake = dailyIntake;
          logInfo("State updated with dailyIntake:", "$_dailyIntake");
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _selectedDate = date;
          _dailyIntake = {};
          logic.dailyIntake = {};
          logInfo("Reset to empty dailyIntake", "Reset to empty dailyIntake");
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 80,
            top: MediaQuery.of(context).padding.top + 10,
          ),
          child: Column(
            children: [
              HeaderCard(context, _selectedDate),
              DateSelector(
                context,
                _selectedDate,
                (DateTime newDate) {
                  setState(() {
                    _selectedDate = newDate;
                    _loadDailyIntake(newDate);
                  });
                },
              ),
              MacronutrientSummaryCard(context, _dailyIntake),
              FoodHistoryCard(
                  context: context,
                  currentIndex: _currentIndex,
                  logic: logic,
                  selectedDate: _selectedDate),
              DetailedNutrientsCard(context, _dailyIntake),
            ],
          ),
        ),
      ),
    );
  }
}
