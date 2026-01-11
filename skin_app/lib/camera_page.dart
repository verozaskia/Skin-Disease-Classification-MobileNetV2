import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  double? _confidenceValue;
  String _predictionText = "";
  bool _isLowConfidence = false;
  bool _isLoading = false;

  // ======================
  // CAMERA
  // ======================
  Future<void> takePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    await _processImage(image);
  }

  // ======================
  // GALLERY
  // ======================
  Future<void> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    await _processImage(image);
  }

  // ======================
  // PROCESS IMAGE + AI
  // ======================
  Future<void> _processImage(XFile image) async {
    setState(() {
      _imageFile = File(image.path);
      _predictionText = "";
      _confidenceValue = null;
      _isLowConfidence = false;
      _isLoading = true;
    });

    try {
      final response = await ApiService.predictImage(image);

      setState(() {
        _confidenceValue = response["confidence"];
        _isLowConfidence = response["isLowConfidence"];

        // ⬇⬇⬇ PENTING: sembunyikan nama kelas jika low confidence
        _predictionText = _isLowConfidence ? "" : response["prediction"];
      });
    } catch (e) {
      print("FLUTTER ERROR: $e");
      setState(() {
        _predictionText = "Error";
        _confidenceValue = null;
        _isLowConfidence = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ======================
  // RESET
  // ======================
  void resetScan() {
    setState(() {
      _imageFile = null;
      _confidenceValue = null;
      _predictionText = "";
      _isLowConfidence = false;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Skin Disease Classification"),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: resetScan),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ======================
            // IMAGE PREVIEW
            // ======================
            if (_imageFile != null)
              Image.file(
                _imageFile!,
                width: 250,
                height: 250,
                fit: BoxFit.cover,
              ),

            const SizedBox(height: 20),

            // ======================
            // BUTTONS
            // ======================
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: takePhoto,
                  child: const Text("Ambil Foto"),
                ),
                const SizedBox(width: 15),
                ElevatedButton(
                  onPressed: pickFromGallery,
                  child: const Text("Dari Galeri"),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // ======================
            // LOADING
            // ======================
            if (_isLoading) const CircularProgressIndicator(),

            // ======================
            // RESULT CARD
            // ======================
            if (!_isLoading && _confidenceValue != null)
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  child: Column(
                    children: [
                      // ======================
                      // PREDICTION (HANYA JIKA CONFIDENT)
                      // ======================
                      if (!_isLowConfidence) ...[
                        const Text(
                          "Prediction",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _predictionText,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Divider(height: 30),
                      ],

                      // ======================
                      // CONFIDENCE / WARNING
                      // ======================
                      if (_isLowConfidence)
                        const Text(
                          "⚠️ Prediksi Belum Meyakinkan\nAmbil Ulang Foto",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        )
                      else ...[
                        const Text(
                          "Confidence",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${_confidenceValue!.toStringAsFixed(2)} %",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
