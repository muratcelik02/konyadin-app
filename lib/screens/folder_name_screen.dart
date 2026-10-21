import 'package:flutter/material.dart';
import '../controllers/collection_controller.dart';
import 'camera_screen.dart';

class FolderNameScreen extends StatefulWidget {
  final CollectionController controller;

  const FolderNameScreen({super.key, required this.controller});

  @override
  State<FolderNameScreen> createState() => _FolderNameScreenState();
}

class _FolderNameScreenState extends State<FolderNameScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.controller.currentDraft?.name ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onContinue() {
    final rawName = _nameController.text;
    final cleanName = rawName.trim();

    if (cleanName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen geçerli bir klasör adı giriniz.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    // Yeni klasör taslağı başlat
    widget.controller.startNewCollection(cleanName);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CameraScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Klasör Adı Oluşturma'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Klasörünüzü İsimlendirin',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bu isim sunucuda oluşturulacak bağımsız klasör ve metaveri dosyası için kullanılacaktır.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 32),

              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _onContinue(),
                  decoration: const InputDecoration(
                    labelText: 'Klasör Adı',
                    hintText: 'Örn: Şantiye Denetimi 2026',
                    prefixIcon: Icon(Icons.folder_outlined),
                  ),
                ),
              ),

              const Spacer(),

              ElevatedButton.icon(
                onPressed: _onContinue,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Devam Et'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Vazgeç ve Geri Dön'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
