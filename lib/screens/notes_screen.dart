import 'package:flutter/material.dart';
import '../controllers/collection_controller.dart';
import 'upload_screen.dart';

class NotesScreen extends StatefulWidget {
  final CollectionController controller;

  const NotesScreen({super.key, required this.controller});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late TextEditingController _notesTextController;
  late String _selectedFormat; // 'md' veya 'txt'

  @override
  void initState() {
    super.initState();
    _notesTextController = TextEditingController(
      text: widget.controller.currentDraft?.notes ?? '',
    );
    _selectedFormat = widget.controller.currentDraft?.noteFormat ?? 'md';
  }

  @override
  void dispose() {
    _notesTextController.dispose();
    super.dispose();
  }

  void _syncNotesToDraft() {
    widget.controller.updateNotes(
      _notesTextController.text,
      _selectedFormat,
    );
  }

  void _onProceedToUpload() {
    _syncNotesToDraft();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UploadScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final folderName = widget.controller.currentDraft?.name ?? 'Klasör';
    final photoCount = widget.controller.photoCount;

    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) {
          _syncNotesToDraft();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Klasör Notları'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _syncNotesToDraft();
              Navigator.of(context).pop();
            },
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Özet bilgi kutusu
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.folder_open, color: Color(0xFF1E5BB0)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    folderName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    '$photoCount fotoğraf hazırlandı',
                                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Format Seçimi
                      const Text(
                        'Not Dosyası Formatı',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment<String>(
                            value: 'md',
                            label: Text('Markdown (.md)'),
                            icon: Icon(Icons.code),
                          ),
                          ButtonSegment<String>(
                            value: 'txt',
                            label: Text('Düz Metin (.txt)'),
                            icon: Icon(Icons.text_snippet),
                          ),
                        ],
                        selected: {_selectedFormat},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _selectedFormat = newSelection.first;
                          });
                          _syncNotesToDraft();
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFormat == 'md'
                            ? 'Sunucuda UTF-8 kodlu "notes.md" olarak kaydedilecektir.'
                            : 'Sunucuda UTF-8 kodlu "notes.txt" olarak kaydedilecektir.',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 24),

                      // Not Alanı
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Notlarınız (İsteğe Bağlı)',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          Text(
                            'Boş bırakılabilir',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _notesTextController,
                        maxLines: 12,
                        minLines: 6,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: _selectedFormat == 'md'
                              ? '# Başlık\n- Madde 1\n- Madde 2\n\nBuraya detaylı notlarınızı yazabilirsiniz...'
                              : 'Buraya fotoğraflarla ilgili notlarınızı yazabilirsiniz...',
                          alignLabelWithHint: true,
                        ),
                        onChanged: (_) => _syncNotesToDraft(),
                      ),
                    ],
                  ),
                ),
              ),

              // Alt Aksiyon Butonları
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _onProceedToUpload,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Kaydet ve Sunucuya Yükle'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        _syncNotesToDraft();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Geri Dön'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
