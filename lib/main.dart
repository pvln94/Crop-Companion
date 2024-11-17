import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as devtools;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soil Type Detection',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
      routes: {
        '/moreDetails': (context) => const MoreDetailsScreen(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? filePath;
  String label = '';
  double confidence = 0.0;
  bool isPredicted = false; // Flag to check if the soil type is predicted

  // Initialize the TensorFlow Lite model
  Future<void> _tfLteInit() async {
    try {
      String? res = await Tflite.loadModel(
        model: "assets/soil_type_predictor_model.tflite",
        labels: "assets/labels.txt",
        numThreads: 1,
        isAsset: true,
        useGpuDelegate: false,
      );
      devtools.log('Model loaded successfully: $res');
    } catch (e) {
      devtools.log('Error loading model: $e');
    }
  }

  // Pick image from the gallery
  Future<void> pickImageGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      filePath = File(image.path);
    });

    _runModelOnImage(image.path);
  }

  // Pick image using the camera
  Future<void> pickImageCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    setState(() {
      filePath = File(image.path);
    });

    _runModelOnImage(image.path);
  }

  // Run the TensorFlow Lite model on the selected image
  Future<void> _runModelOnImage(String path) async {
    var recognitions = await Tflite.runModelOnImage(
      path: path,
      imageMean: 0.0,
      imageStd: 255.0,
      numResults: 2,
      threshold: 0.2,
      asynch: true,
    );

    if (recognitions == null) {
      devtools.log("No recognitions returned");
      return;
    }

    devtools.log('Recognitions: $recognitions');
    setState(() {
      confidence = (recognitions[0]['confidence'] * 100);
      label = recognitions[0]['label'].toString();
      isPredicted = true; // Set flag to true when prediction is done
    });
  }

  @override
  void dispose() {
    super.dispose();
    Tflite.close(); // Close the model when done
  }

  @override
  void initState() {
    super.initState();
    _tfLteInit(); // Initialize the TensorFlow Lite model
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Soil Type Detection",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurpleAccent,
        centerTitle: true,
        elevation: 10,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.deepPurpleAccent, Colors.blueAccent],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Card(
                  color: Colors.white.withOpacity(0.9),
                  shadowColor: Colors.black,
                  elevation: 15,
                  margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          height: 300,
                          width: 300,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(15),
                            image: filePath == null
                                ? const DecorationImage(
                              image: AssetImage('assets/upload.jpg'),
                              fit: BoxFit.cover,
                            )
                                : null,
                          ),
                          child: filePath != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.file(
                              filePath!,
                              fit: BoxFit.cover,
                            ),
                          )
                              : const Center(
                            child: Text(
                              'No Image Selected',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          label.isNotEmpty
                              ? label
                              : 'Select an image to predict soil type',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurpleAccent,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          confidence > 0
                              ? "Confidence: ${confidence.toStringAsFixed(2)}%"
                              : '',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        isPredicted
                            ? ElevatedButton(
                          onPressed: () {
                            // Show suggested crops based on predicted soil type
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SuggestedCropsScreen(predictedSoil: label),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('Suggested Crops'),
                        )
                            : Container(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: pickImageCamera,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Take a Photo"),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: pickImageGallery,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.photo),
                  label: const Text("Pick from Gallery"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}




class SuggestedCropsScreen extends StatefulWidget {
  final String predictedSoil;

  const SuggestedCropsScreen({super.key, required this.predictedSoil});

  @override
  _SuggestedCropsScreenState createState() => _SuggestedCropsScreenState();
}

class _SuggestedCropsScreenState extends State<SuggestedCropsScreen> {
  String? selectedMonth;  // Initially, no month is selected
  String cropSuggestions = '';  // Placeholder for crop suggestions

  // Function to get crop suggestions based on predicted soil type and selected month
  String suggestCrops(String soilType, String month) {
    int monthNumber = getMonthNumber(month);

    if (monthNumber == -1) {
      return 'Invalid month. Please enter a valid month name.';
    }

    switch (soilType) {
      case 'Black Soil':
        return getCropSuggestion(
          monthNumber,
          rabi: 'Wheat, Gram, Mustard, Linseed',
          kharif: 'Cotton, Jowar (Sorghum), Soybean, Groundnut, Maize',
          zaid: 'Watermelon, Cucumber, Moong Dal (Green Gram), Vegetables',
        );

      case 'Cinder Soil':
        return getCropSuggestion(
          monthNumber,
          rabi: 'Barley, Oats, Peas, Lentils',
          kharif: 'Millets, Rice, Maize, Sorghum',
          zaid: 'Tomatoes, Pumpkins, Melons, Green Vegetables',
        );

      case 'Laterite Soil':
        return getCropSuggestion(
          monthNumber,
          rabi: 'Tea, Coffee, Tobacco',
          kharif: 'Rice, Sugarcane, Cashew Nuts, Pineapple, Banana',
          zaid: 'Groundnut, Watermelon, Sweet Potato, Vegetables',
        );

      case 'Peat Soil':
        return getCropSuggestion(
          monthNumber,
          rabi: 'Potatoes, Carrots, Onions',
          kharif: 'Paddy (Rice), Jute, Sugarcane',
          zaid: 'Vegetables, Melons, Tuber Crops',
        );

      case 'Yellow Soil':
        return getCropSuggestion(
          monthNumber,
          rabi: 'Wheat, Barley, Chickpea',
          kharif: 'Cotton, Maize, Millets, Groundnut',
          zaid: 'Cucumber, Pumpkin, Gourds, Sunflowers',
        );

      default:
        return 'No suggestions available for this soil type.';
    }
  }

  // Function to convert month name to a month number
  int getMonthNumber(String month) {
    const months = {
      'January': 1,
      'February': 2,
      'March': 3,
      'April': 4,
      'May': 5,
      'June': 6,
      'July': 7,
      'August': 8,
      'September': 9,
      'October': 10,
      'November': 11,
      'December': 12,
    };
    return months[month] ?? -1;
  }

  // Function to get crop suggestions based on the season
  String getCropSuggestion(int monthNumber,
      {required String rabi, required String kharif, required String zaid}) {
    if (monthNumber >= 10 || monthNumber <= 3) {
      return 'Rabi Season (October to March): $rabi';
    } else if (monthNumber >= 6 && monthNumber <= 9) {
      return 'Kharif Season (June to September): $kharif';
    } else {
      return 'Zaid Season (March to June): $zaid';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggested Crops'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. Dropdown for month selection
            if (selectedMonth == null) ...[
              Center( // Center the content inside this widget
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Ensure the column takes only as much space as needed
                  children: [
                    const Text(
                      'Select Month:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    DropdownButton<String>(
                      hint: const Text('Choose a month'),
                      value: selectedMonth,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedMonth = newValue;
                          // Clear previous crop suggestions when month is changed
                          cropSuggestions = '';
                        });
                      },
                      items: const [
                        'January', 'February', 'March', 'April', 'May', 'June', 'July',
                        'August', 'September', 'October', 'November', 'December'
                      ]
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],


            // 2. Once month is selected, show crop suggestions
            if (selectedMonth != null) ...[
              const SizedBox(height: 20),
              Center( // Center the button inside the widget
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Get crop suggestions based on selected month and soil type
                      cropSuggestions = suggestCrops(
                        widget.predictedSoil,
                        selectedMonth!,
                      );
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text("Suggest Crops"),
                ),
              ),
            ],


            const SizedBox(height: 20),
            // 3. Display crop suggestions after clicking Suggest Crops button
            if (cropSuggestions.isNotEmpty) ...[
              Text(
                'Suggested crops for the predicted soil type (${widget.predictedSoil}) in $selectedMonth:',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              Text(
                cropSuggestions,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 20),
            // Option for more details
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MoreDetailsScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text("More Details"),
            ),
          ],
        ),
      ),
    );
  }
}




class MoreDetailsScreen extends StatefulWidget {
  const MoreDetailsScreen({super.key});

  @override
  _MoreDetailsScreenState createState() => _MoreDetailsScreenState();
}

class _MoreDetailsScreenState extends State<MoreDetailsScreen> {
  // Soil details map
  final Map<String, String> soilDetails = {
    "Black Soil": """
1) Black soil, also known as "Regular soil", is rich in minerals such as "Calcium", "Magnesium", and "Lime". It retains moisture effectively, making it suitable for a variety of crops. 

2)      Soil Characteristics:
                                        
- Nitrogen (N): Low to moderate (0.02%–0.1%)
- Phosphorus (P): Low to moderate (5–20 kg/ha)
- Potassium (K): High (250–800 kg/ha)

3)  Although Black soil retains moisture well and is rich in Potassium, it is often deficient in Nitrogen and Phosphorus.

4)      Suitable Crops:
- Rabi Season (October to March): 
              Wheat, Gram, Mustard, Linseed.

- Kharif Season (June to September): 
            Cotton, Jowar (Sorghum), Soybean, Groundnut, Maize.

- Zaid Season (March to June): 
            Watermelon, Cucumber, Moong Dal (Green Gram), Vegetables.
""",
    "Cinder Soil": """
1) Cinder soil is formed from "Volcanic Ash" and is known for its porous and well-drained nature. It typically has "Low Nutrient levels" but supports certain crops well.

2)          Soil Characteristics:
- Nitrogen (N): Very low (0.01%–0.03%)
- Phosphorus (P): Low to moderate (3–15 kg/ha)
- Potassium (K): Moderate to high (100–300 kg/ha)

3)          Suitable Crops:
- Rabi Season (October to March): 
            Barley, Oats, Peas, Lentils.

- Kharif Season (June to September): 
            Millets, Rice, Maize, Sorghum.

- Zaid Season (March to June): 
            Tomatoes, Pumpkins, Melons, Green Vegetables.
""",
    "Laterite Soil": """
1) Laterite soil is rich in "Iron" and "Aluminum", but it is "Acidic" and has "Low Fertility". However, it can improve with proper manuring.

2)        Soil Characteristics:
- Nitrogen (N): Low (0.01%–0.1%)
- Phosphorus (P): Very low to low (3–8 kg/ha)
- Potassium (K): Low (50–200 kg/ha)

3) Although Laterite soil is heavily leached and acidic, it is suitable for certain crops when supplemented with organic fertilizers.

4)        Suitable Crops:
- Rabi Season (October to March): 
            Tea, Coffee, Tobacco.

- Kharif Season (June to September): 
            Rice, Sugarcane, Cashew Nuts, Pineapple, Banana.

- Zaid Season (March to June): 
            Groundnut, Watermelon, Sweet Potato, Vegetables.
""",
    "Peat Soil": """
1) Peat soil is rich in organic content, acidic, and waterlogged. Its high nitrogen content makes it favorable for certain crops, though it may require supplements for other nutrients.

2)         Soil Characteristics:
- Nitrogen (N): High (1%–3%)
- Phosphorus (P): Moderate (15–30 kg/ha)
- Potassium (K): Moderate (100–300 kg/ha)

3) Peat soil’s high organic matter and Nitrogen content support healthy plant growth, but its Phosphorus and Potassium may need supplementation.

4)        Suitable Crops:
- Rabi Season (October to March): 
            Potatoes, Carrots, Onions.

- Kharif Season (June to September): 
            Paddy (Rice), Jute, Sugarcane.

- Zaid Season (March to June): 
            Vegetables, Melons, Tuber Crops.
""",
    "Yellow Soil": """
1) Yellow soil is typically poor in humus, nitrogen, and phosphorus, but it can support certain crops. It forms from weathered materials and is often acidic, contributing to moderate fertility.

2) Soil Characteristics:
- Nitrogen (N): Low to moderate (0.02%–0.1%)
- Phosphorus (P): Low to moderate (5–15 kg/ha)
- Potassium (K): Moderate to high (100–300 kg/ha)

3) Yellow soil’s moderate fertility can be enhanced by selecting suitable crops and ensuring proper care.

4) Suitable Crops:
- Rabi Season (October to March): 
            Wheat, Barley, Chickpea.

- Kharif Season (June to September): 
            Cotton, Maize, Millets, Groundnut.

- Zaid Season (March to June): 
            Cucumber, Pumpkin, Gourds, Sunflowers.
""",
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Soil Details"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: SingleChildScrollView( // Wrap the entire body in a scroll view
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Soil Buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: soilDetails.keys.map((soil) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10), // Add space between buttons
                    child: SizedBox(
                      width: double.infinity, // Make the button expand to full width
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to the new screen with soil details
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SoilDetailsScreen(soil: soil, details: soilDetails[soil]!),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20), // Adjust vertical padding for better alignment
                          backgroundColor: Colors.deepPurpleAccent,
                        ),
                        child: Center(
                          child: Text(
                            soil,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white), // Set the text color to white
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SoilDetailsScreen extends StatelessWidget {
  final String soil;
  final String details;

  const SoilDetailsScreen({required this.soil, required this.details, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$soil Details"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                soil,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
              const SizedBox(height: 10),
              Text(
                details,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}






