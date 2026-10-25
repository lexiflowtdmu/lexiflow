import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexiflow/core/theme/theme_extension.dart';
import '../bloc/ocr_bloc.dart';
import '../bloc/search_bloc.dart';
import 'vocab_detail_screen.dart';
import '../../core/utils/page_transitions.dart';

class OcrTranslatorScreen extends StatefulWidget {
  const OcrTranslatorScreen({super.key});

  @override
  State<OcrTranslatorScreen> createState() => _OcrTranslatorScreenState();
}

class _OcrTranslatorScreenState extends State<OcrTranslatorScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    context.read<OcrBloc>().add(OcrResetRequested());
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không khởi động được máy ảnh: $e')),
      );
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _captureAndProcess() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final XFile image = await _cameraController!.takePicture();
      if (mounted) {
        context.read<OcrBloc>().add(OcrImageProcessed(image.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chụp ảnh: $e')),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        context.read<OcrBloc>().add(OcrImageProcessed(image.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chọn ảnh từ thư viện: $e')),
      );
    }
  }

  void _showWordDefinitionBottomSheet(BuildContext context, String word) {
    // Search the tapped word
    context.read<SearchBloc>().add(SearchWordSubmitted(word));


    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.6,
          child: BlocBuilder<SearchBloc, SearchState>(
            builder: (context, state) {
              if (state is SearchLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is SearchFailure) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sentiment_dissatisfied_rounded, size: 48, color: context.primaryColor),
                    const SizedBox(height: 12),
                    Text(
                      'Không tìm thấy từ vựng',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: context.textColor),
                    ),
                    const SizedBox(height: 8),
                    Text('Từ "$word" không được hỗ trợ giải nghĩa lúc này.', style: GoogleFonts.outfit(color: context.subTextColor)),
                  ],
                );
              }
              if (state is SearchSuccess) {
                final dWord = state.word;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dWord.word,
                          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: context.primaryColor),
                        ),
                        IconButton(
                          icon: Icon(Icons.open_in_new_rounded, color: context.primaryColor),
                          onPressed: () {
                            Navigator.pop(context); // Close sheet
                            Navigator.push(
                              context,
                              SlidePageRoute(
                                page: VocabDetailScreen(searchWord: dWord.word),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    if (dWord.phonetic.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(dWord.phonetic, style: GoogleFonts.outfit(color: context.subTextColor, fontStyle: FontStyle.italic)),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Dịch nghĩa:',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.textColor),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.softBgColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        dWord.vietnameseTranslation,
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: context.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        itemCount: dWord.definitions.length > 2 ? 2 : dWord.definitions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final def = dWord.definitions[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '[${def.partOfSpeech.toUpperCase()}] ${def.definition}',
                                style: GoogleFonts.outfit(fontSize: 14, color: context.textColor, fontWeight: FontWeight.w600),
                              ),
                              if (def.example.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Ví dụ: "${def.example}"',
                                  style: GoogleFonts.outfit(fontSize: 13, color: context.subTextColor, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              }
              return const Center(child: Text('Đang tra từ...'));
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Dịch Qua Camera'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<OcrBloc, OcrState>(
        builder: (context, state) {
          if (state is OcrInitial) {
            if (!_isCameraInitialized) {
              return const Center(child: CircularProgressIndicator());
            }

            // Camera preview with scanner crop design layout
            return Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_cameraController!),
                // Custom overlay mask
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.5),
                    BlendMode.srcOut,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: Colors.black,
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          height: 160,
                          width: MediaQuery.of(context).size.width * 0.8,
                          decoration: BoxDecoration(
                            color: Colors.red, // Source out mask target
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Border frame around scanner box
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 160,
                    width: MediaQuery.of(context).size.width * 0.8,
                    decoration: BoxDecoration(
                      border: Border.all(color: context.primaryColor, width: 3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                // Text instructions
                Positioned(
                  top: 40,
                  left: 20,
                  right: 20,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Đặt văn bản tiếng Anh vào trong khung quét',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                // Actions layout
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery Picker Button
                      GestureDetector(
                        onTap: _pickImageFromGallery,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.photo_library_rounded, size: 28, color: Colors.white),
                        ),
                      ),

                      // Shutter Capture Button
                      GestureDetector(
                        onTap: _captureAndProcess,
                        child: Container(
                          height: 76,
                          width: 76,
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white30,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.camera_rounded, size: 36, color: context.primaryColor),
                          ),
                        ),
                      ),

                      // Placeholder for alignment symmetry
                      const SizedBox(width: 56),
                    ],
                  ),
                ),
              ],
            );
          }

          if (state is OcrLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Đang xử lý ảnh & nhận diện từ...',
                    style: TextStyle(color: Colors.white),
                  )
                ],
              ),
            );
          }

          if (state is OcrFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded, color: context.errorRed, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.read<OcrBloc>().add(OcrResetRequested()),
                      child: const Text('Thử Lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is OcrSuccess) {
            return Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Kết quả quét văn bản:',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chạm vào từ bất kỳ để tra từ điển tức thì',
                    style: GoogleFonts.outfit(fontSize: 13, color: context.subTextColor),
                  ),
                  const SizedBox(height: 20),
                  // Word cloud chips
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 10.0,
                        children: state.words.map((word) {
                          return InkWell(
                            onTap: () => _showWordDefinitionBottomSheet(context, word),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: context.primaryColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                word,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.primaryColor,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context.read<OcrBloc>().add(OcrResetRequested()),
                    child: const Text('Quét Ảnh Khác'),
                  ),
                ],
              ),
            );
          }

          return const Center(child: Text('Đang tải OCR...'));
        },
      ),
    );
  }
}

