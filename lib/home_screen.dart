import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  String _result = "Upload a leaf image to analyze";
  Interpreter? _interpreter;
  List<String> _labels = [];
  final int _inputSize = 128; // Ensure it matches the model's input size

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/tomato_disease_model.tflite');

      // Load labels file
      String labelsData = await DefaultAssetBundle.of(context).loadString('assets/labels.txt');
      _labels = labelsData.split('\n').where((e) => e.trim().isNotEmpty).toList();

      setState(() {});
    } catch (e) {
      setState(() {
        _result = "Error loading model: $e";
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await _classifyImage(_image!);
    }
  }

  Future<void> _classifyImage(File imageFile) async {
    if (_interpreter == null) {
      setState(() {
        _result = "Model not loaded";
      });
      return;
    }

    try {
      var input = _preprocessImage(imageFile);

      if (!_isLeafImage(input)) {
        setState(() {
          _result = "This is not a leaf image. Please upload a leaf image.";
        });
        return;
      }

      // Prepare output buffer with explicit double type
      var output = List<List<double>>.generate(
        1,
            (_) => List<double>.filled(_labels.length, 0.0),
      );

      _interpreter!.run(input, output);

      // Get the highest probability index
      int highestIndex = output[0].indexWhere((e) => e == output[0].reduce((a, b) => a > b ? a : b));
      String predictedLabel = _labels[highestIndex];

      setState(() {
        _result = "Prediction: $predictedLabel";
      });
    } catch (e) {
      setState(() {
        _result = "Error processing image: $e";
      });
    }
  }

  bool _isLeafImage(List<List<List<List<double>>>> imageTensor) {
    int greenPixelCount = 0;
    int totalPixels = _inputSize * _inputSize;

    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        double r = imageTensor[0][y][x][0] * 255;
        double g = imageTensor[0][y][x][1] * 255;
        double b = imageTensor[0][y][x][2] * 255;

        if (g > r && g > b && g > 80) {
          greenPixelCount++;
        }
      }
    }

    return (greenPixelCount / totalPixels) > 0.1; // Adjust threshold if necessary
  }

  List<List<List<List<double>>>> _preprocessImage(File imageFile) {
    try {
      Uint8List imageBytes = imageFile.readAsBytesSync();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception("Failed to decode image");
      }

      img.Image resizedImage = img.copyResize(image, width: _inputSize, height: _inputSize);

      var input = List.generate(1, (_) => List.generate(_inputSize, (_) => List.generate(_inputSize, (_) => List.filled(3, 0.0))));

      for (int y = 0; y < _inputSize; y++) {
        for (int x = 0; x < _inputSize; x++) {
          img.Pixel pixel = resizedImage.getPixel(x, y);

          input[0][y][x][0] = pixel.r / 255.0;
          input[0][y][x][1] = pixel.g / 255.0;
          input[0][y][x][2] = pixel.b / 255.0;
        }
      }

      return input;
    } catch (e) {
      return [];
    }
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  // Handle menu item selection
  void _handleMenuSelection(String value) {
    if (value == 'about') {
      _navigateToAboutUs();
    } else if (value == 'contact') {
      _navigateToContactUs();
    }
  }

  // Navigate to About Us screen
  void _navigateToAboutUs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AboutUsScreen(),
      ),
    );
  }

  // Navigate to Contact Us screen
  void _navigateToContactUs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactUsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tomato Disease Detection'),
        backgroundColor: Colors.green,
        actions: [
          // Three-dot menu button
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'about',
                  child: Text('About Us'),
                ),
                PopupMenuItem(
                  value: 'contact',
                  child: Text('Contact Us'),
                ),
              ];
            },
            icon: Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: Container(
        color: Colors.green[50],
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.file(
                _image!,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
                : Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.image, size: 100, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _result,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Camera"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Gallery"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// About Us Screen
class AboutUsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("About Us"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tomato Disease Detection App",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 8), // Reduced space
            Text(
              "DEVELOPED BY KBWELL",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                fontStyle: FontStyle.italic,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              "This app helps farmers and gardeners detect diseases in tomato leaves using AI. Simply upload an image of a tomato leaf, and the app will analyze it to identify potential diseases.",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 24),
            Text(
              "Features:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            SizedBox(height: 8),
            Text(
              "- Disease detection using AI\n- Easy-to-use interface\n- Camera and gallery integration\n- Real-time results",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}

// Contact Us Screen
class ContactUsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Contact Us"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Contact Us",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            SizedBox(height: 16),
            Text(
              "If you have any questions or feedback, feel free to reach out to us:",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 24),
            Text(
              "Email: kbwell@gmail.com",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            Text(
              "Phone: +251 901975431",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}