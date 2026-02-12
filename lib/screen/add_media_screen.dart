import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/media_model.dart';
import '../services/media_provider.dart';
import '../services/minio_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

class AddMediaScreen extends StatefulWidget {
  const AddMediaScreen({super.key});

  @override
  State<AddMediaScreen> createState() => _AddMediaScreenState();
}

class _AddMediaScreenState extends State<AddMediaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  final MinioService _minioService = MinioService();

  Future<void> _pickVideo() async {
    // Request permissions
    if (Platform.isAndroid || Platform.isIOS) {
      if (await Permission.videos.request().isGranted ||
          await Permission.storage.request().isGranted) {
        _executePicker();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permission is required to pick files'),
            ),
          );
        }
      }
    } else {
      _executePicker();
    }
  }

  Future<void> _executePicker() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mp3', 'mov', 'wav', 'm4a', 'mkv'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        if (_titleController.text.isEmpty) {
          // Auto-fill title with filename
          _titleController.text = p.basenameWithoutExtension(
            _selectedFile!.path,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Media', style: GoogleFonts.outfit()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Media Details',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // File Picker Section
                  GestureDetector(
                    onTap: _pickVideo,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _selectedFile != null
                              ? Colors.redAccent
                              : Colors.grey[700]!,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedFile != null
                                ? Icons.video_file
                                : Icons.cloud_upload_outlined,
                            size: 50,
                            color: _selectedFile != null
                                ? Colors.redAccent
                                : Colors.grey,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _selectedFile != null
                                ? p.basename(_selectedFile!.path)
                                : 'Tap to pick media from phone',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: _selectedFile != null
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  _buildTextField(
                    controller: _titleController,
                    label: 'Title',
                    hint: 'Enter song or movie title',
                    icon: Icons.title,
                    validator: (v) =>
                        v!.isEmpty ? 'Please enter a title' : null,
                  ),
                  const SizedBox(height: 20),

                  if (_selectedFile == null)
                    _buildTextField(
                      controller: _urlController,
                      label: 'Or Video URL',
                      hint: 'https://example.com/video.mp4',
                      icon: Icons.link,
                      validator: (v) => (_selectedFile == null && v!.isEmpty)
                          ? 'Please enter a URL or pick a file'
                          : null,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'File selected. It will be uploaded to MinIO.',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () =>
                                setState(() => _selectedFile = null),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Short description...',
                    icon: Icons.description,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(height: 50),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      child: _isUploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Save & Upload',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 100,
                          width: 100,
                          child: CircularProgressIndicator(
                            value: _uploadProgress,
                            color: Colors.redAccent,
                            strokeWidth: 8,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                        Text(
                          "${(_uploadProgress * 100).toInt()}%",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Uploading To Server...',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.redAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUploading = true);

      try {
        String finalUrl = _urlController.text;

        // If a file was picked, upload it first
        if (_selectedFile != null) {
          finalUrl = await _minioService.uploadVideo(
            _selectedFile!,
            onProgress: (p) {
              if (mounted) setState(() => _uploadProgress = p);
            },
          );
        }

        String detectedCategory = 'Media';
        final pathToCheck = _selectedFile?.path ?? finalUrl;
        final extension = p.extension(pathToCheck).toLowerCase();

        if (extension == '.mp3' || extension == '.wav' || extension == '.m4a') {
          detectedCategory = 'Songs';
        } else if (extension == '.mp4' ||
            extension == '.mov' ||
            extension == '.mkv') {
          detectedCategory = 'Movies';
        }

        final media = MediaModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          url: finalUrl,
          description: _descriptionController.text,
          category: detectedCategory,
        );

        if (mounted) {
          Provider.of<MediaProvider>(context, listen: false).addMedia(media);
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }
}
