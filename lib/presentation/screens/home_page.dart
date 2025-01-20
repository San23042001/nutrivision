import 'dart:io';
import 'dart:ui';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nutrivision/app.dart';
import 'package:nutrivision/data/nutrient_insights.dart';
import 'package:nutrivision/presentation/screens/ask_AI_page.dart';
import 'package:nutrivision/presentation/screens/daily_intake_page.dart';
import 'package:nutrivision/presentation/widgets/ask_ai_widget.dart';
import 'package:nutrivision/presentation/widgets/nutrient_balance_card.dart';
import 'package:nutrivision/presentation/widgets/nutrient_info_shimmer.dart';
import 'package:nutrivision/presentation/widgets/nutrient_tile.dart';
import 'package:nutrivision/presentation/widgets/portion_buttons.dart';
import 'package:nutrivision/utils/utils.dart';
import 'package:page_transition/page_transition.dart';
import 'package:rive/rive.dart' as rive;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _selectedFile;
  final ImagePicker imagePicker = ImagePicker();
  final Logic _logic = Logic();
  int _currentIndex = 0;
  final _duration = const Duration(milliseconds: 300);

  Widget _buildImageCaptureButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.qr_code_scanner_outlined, color: Colors.white),
          label: const Text("Scan Now",
              style: TextStyle(
                  fontFamily: 'Poppins', fontWeight: FontWeight.w400)),
          style: ElevatedButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () => _handleImageCapture(ImageSource.camera),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          icon: Icon(Icons.photo_library,
              color: Theme.of(context).colorScheme.onSurface),
          label: const Text("Gallery",
              style: TextStyle(
                  fontFamily: 'Poppins', fontWeight: FontWeight.w400)),
          style: ElevatedButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: Theme.of(context).colorScheme.cardBackground,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          onPressed: () => _handleImageCapture(ImageSource.gallery),
        ),
      ],
    );
  }

  void _handleImageCapture(ImageSource source) async {
    // First, capture front image
    await _logic.captureImage(
      source: source,
      isFrontImage: true,
      setState: setState,
    );

    if (_logic.frontImage != null) {
      // Show dialog for nutrition label
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(
              'Now capture nutrition label',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: 'Poppins'),
            ),
            content: Text(
              'Please capture or select the nutrition facts label of the product',
              style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontFamily: 'Poppins'),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _logic.captureImage(
                    source: source,
                    isFrontImage: false,
                    setState: setState,
                  );
                  if (_logic.canAnalyze()) {
                    _analyzeImages();
                  }
                },
                child: const Text('Continue',
                    style: TextStyle(fontFamily: 'Poppins')),
              ),
            ],
          ),
        );
      }
    }
  }

  void _analyzeImages() {
    if (_logic.canAnalyze()) {
      _logic.analyzeImages(setState: setState);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          "Scan Product",
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500),
        ),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeftWithFade,
                    child: DailyIntakePage(
                      dailyIntake: _logic.dailyIntake,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.bar_chart_rounded))
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 100),
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.transparent),
                ),
                child: DottedBorder(
                  borderPadding: const EdgeInsets.all(-20),
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(20),
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  strokeWidth: 1,
                  dashPattern: const [6, 4],
                  child: Column(
                    children: [
                      if (_logic.frontImage != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child:
                                  Image(image: FileImage(_logic.frontImage!)),
                            ),
                            if (_logic.getIsLoading())
                              const Positioned.fill(
                                left: 5,
                                right: 5,
                                top: 5,
                                bottom: 5,
                                child: rive.RiveAnimation.asset(
                                  'assets/riveAssets/qr_code_scanner.riv',
                                  fit: BoxFit.fill,
                                  artboard: 'scan_board',
                                  animations: ['anim1'],
                                  stateMachines: ['State Machine 1'],
                                ),
                              ),
                          ],
                        )
                      else
                        Icon(
                          Icons.document_scanner,
                          size: 70,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                        ),
                      const SizedBox(height: 20),
                      Text(
                        "To get started, scan product front or choose from gallery!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 20),
                      _buildImageCaptureButtons(),
                    ],
                  ),
                ),
              ),
              if (_logic.getIsLoading()) const NutrientInfoShimmer(),

              //Good/Moderate nutrients
              if (_logic.getGoodNutrients().isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          _logic.productName,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                              fontSize: 24),
                          textAlign: TextAlign.start,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Optimal Nutrients",
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .titleLarge!
                                    .color,
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _logic
                              .getGoodNutrients()
                              .map((nutrient) => NutrientTile(
                                    nutrient: nutrient['name'],
                                    healthSign: nutrient['health_impact'],
                                    quantity: nutrient['quantity'],
                                    insight: nutrientInsights[nutrient['name']],
                                    dailyValue: nutrient['daily_value'],
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),

              //Bad nutrients
              if (_logic.getBadNutrients().isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 24,
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFFFF5252), // Red accent bar
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Watch Out",
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .titleLarge!
                                    .color,
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _logic
                              .getBadNutrients()
                              .map((nutrient) => NutrientTile(
                                    nutrient: nutrient['name'],
                                    healthSign: nutrient['health_impact'],
                                    quantity: nutrient['quantity'],
                                    insight: nutrientInsights[nutrient['name']],
                                    dailyValue: nutrient['daily_value'],
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_logic.getBadNutrients().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(
                              255, 94, 255, 82), // Red accent bar
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Recommendations",
                        style: TextStyle(
                          color: Theme.of(context).textTheme.titleLarge!.color,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              if (_logic.nutritionAnalysis != null &&
                  _logic.nutritionAnalysis['primary_concerns'] != null)
                ..._logic.nutritionAnalysis['primary_concerns'].map(
                  (concern) => NutrientBalanceCard(
                    issue: concern['issue'] ?? '',
                    explanation: concern['explanation'] ?? '',
                    recommendations: (concern['recommendations'] as List?)
                            ?.map((rec) => {
                                  'food': rec['food'] ?? '',
                                  'quantity': rec['quantity'] ?? '',
                                  'reasoning': rec['reasoning'] ?? '',
                                })
                            .toList() ??
                        [],
                  ),
                ),

              if (_logic.getServingSize() > 0)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            "Serving Size: ${_logic.getServingSize().round()} g",
                            style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .color,
                                fontSize: 16,
                                fontFamily: 'Poppins'),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit,
                                color: Theme.of(context)
                                    .textTheme
                                    .titleSmall!
                                    .color,
                                size: 20),
                            onPressed: () {
                              // Show edit dialog
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .cardBackground,
                                  title: Text('Edit Serving Size',
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .textTheme
                                              .titleLarge!
                                              .color,
                                          fontFamily: 'Poppins')),
                                  content: TextField(
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .titleLarge!
                                            .color),
                                    decoration: InputDecoration(
                                      hintText: 'Enter serving size in grams',
                                      hintStyle: TextStyle(
                                          color: Theme.of(context)
                                              .textTheme
                                              .titleLarge!
                                              .color,
                                          fontFamily: 'Poppins'),
                                    ),
                                    onChanged: (value) {
                                      _logic.updateServingSize(
                                          double.tryParse(value) ?? 0.0);
                                    },
                                  ),
                                  actions: [
                                    TextButton(
                                      child: Text('OK',
                                          style: TextStyle(
                                              fontFamily: 'Poppins',
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium!
                                                  .color)),
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "How much did you consume?",
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyMedium!.color,
                              fontSize: 16,
                              fontFamily: 'Poppins'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            PortionButton(
                              context: context,
                              portion: 0.25,
                              label: "¼",
                              logic: _logic,
                              setState: setState,
                            ),
                            const SizedBox(
                              width: 2,
                            ),
                            PortionButton(
                              context: context,
                              portion: 0.5,
                              label: "½",
                              logic: _logic,
                              setState: setState,
                            ),
                            const SizedBox(
                              width: 2,
                            ),
                            PortionButton(
                              context: context,
                              portion: 0.75,
                              label: "¾",
                              logic: _logic,
                              setState: setState,
                            ),
                            const SizedBox(
                              width: 2,
                            ),
                            PortionButton(
                              context: context,
                              portion: 1.0,
                              label: "1",
                              logic: _logic,
                              setState: setState,
                            ),
                            const SizedBox(
                              width: 2,
                            ),
                            CustomPortionButton(
                              logic: _logic,
                              setState: setState,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Builder(
                        builder: (context) {
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onSurface,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              minimumSize: const Size(
                                  200, 50), // Set minimum width and height
                            ),
                            onPressed: () {
                              _logic.addToDailyIntake(
                                  context, (index) {}, 'label');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                      'Added to today\'s intake!'), // Updated message
                                  action: SnackBarAction(
                                    label:
                                        'VIEW', // Changed from 'SHOW' to 'VIEW'
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        PageTransition(
                                          type: PageTransitionType
                                              .rightToLeftWithFade,
                                          child: DailyIntakePage(
                                            dailyIntake: _logic.dailyIntake,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline,
                                      size: 20,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Add to today's intake",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Poppins',
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  "${_logic.sliderValue.toStringAsFixed(0)} grams, ${(_logic.getCalories() * (_logic.sliderValue / _logic.getServingSize())).toStringAsFixed(0)} calories",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              if (_logic.getServingSize() == 0 &&
                  _logic.parsedNutrients.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Serving size not found, please enter it manually',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      TextField(
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            _logic.updateSliderValue(
                                double.tryParse(value) ?? 0.0, setState);
                          });
                        },
                        decoration: const InputDecoration(
                            hintText: "Enter serving size in grams or ml",
                            hintStyle: TextStyle(color: Colors.white54)),
                        style: const TextStyle(color: Colors.white),
                      ),
                      if (_logic.getServingSize() > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Slider(
                              value: _logic.sliderValue,
                              min: 0,
                              max: _logic.getServingSize(),
                              onChanged: (newValue) {
                                _logic.updateSliderValue(newValue, setState);
                              }),
                        ),
                      if (_logic.getServingSize() > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            "Serving Size: ${_logic.getServingSize().round()} g",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Poppins'),
                          ),
                        ),
                      if (_logic.getServingSize() > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Builder(
                            builder: (context) {
                              return ElevatedButton(
                                  style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all(
                                          Colors.white10)),
                                  onPressed: () {
                                    _logic.addToDailyIntake(context, (index) {
                                      setState(() {
                                        _currentIndex = index;
                                      });
                                    }, 'label');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                            'Added to today\'s intake!',
                                            style: TextStyle(
                                                fontFamily: 'Poppins')),
                                        action: SnackBarAction(
                                          label: 'SHOW',
                                          onPressed: () {},
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text("Add to today's intake",
                                      style: TextStyle(fontFamily: 'Poppins')));
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              if (_logic.getServingSize() > 0)
                InkWell(
                  onTap: () {
                    print("Tap detected!");
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => AskAiPage(
                          mealName: _logic.productName,
                          foodImage: _logic.frontImage!,
                          logic: _logic,
                        ),
                      ),
                    );
                  },
                  child: const AskAiWidget(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
