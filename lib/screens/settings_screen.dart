import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/api_client.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _urlController;
  late TextEditingController _tokenController;
  bool _isLoading = true;
  bool _isTesting = false;
  String? _testResult;
  bool? _isSuccess;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _tokenController = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final url = await AppConfig.getServerUrl();
    final token = await AppConfig.getAuthToken();
    setState(() {
      _urlController.text = url;
      _tokenController.text = token;
      _isLoading = false;
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
      _isSuccess = null;
    });

    // Geçici olarak kaydet
    await AppConfig.setServerUrl(_urlController.text);
    await AppConfig.setAuthToken(_tokenController.text);

    final client = ApiClient();
    final res = await client.checkHealth();

    setState(() {
      _isTesting = false;
      _isSuccess = res.isSuccess;
      _testResult = res.isSuccess
          ? 'Bağlantı başarılı! Sunucu ve depolama aktif.'
          : 'Bağlantı başarısız: ${res.errorMessage}';
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    await AppConfig.setServerUrl(_urlController.text);
    await AppConfig.setAuthToken(_tokenController.text);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ayarlar kaydedildi.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sunucu Ayarları'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Merkezi Sunucu Yapılandırması',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Uygulama, fotoğrafları ve notları bu adresteki API sunucusuna gönderecektir. Gerçek telefonunuzla kullanırken bilgisayarınızın yerel ağ IP adresini giriniz.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 24),

                    // Sunucu URL
                    const Text(
                      'Sunucu API Adresi (URL)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        hintText: 'http://192.168.1.100:8000',
                        prefixIcon: Icon(Icons.dns_outlined),
                      ),
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Lütfen sunucu adresini giriniz.';
                        }
                        if (!value.startsWith('http://') && !value.startsWith('https://')) {
                          return 'Adres http:// veya https:// ile başlamalıdır.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // API Erişim Anahtarı
                    const Text(
                      'API Erişim Anahtarı (Token)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _tokenController,
                      decoration: const InputDecoration(
                        hintText: 'Sunucu .env dosyasındaki API_AUTH_TOKEN',
                        prefixIcon: Icon(Icons.key_outlined),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Lütfen API anahtarını giriniz.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Test Butonu
                    OutlinedButton.icon(
                      onPressed: _isTesting ? null : _testConnection,
                      icon: _isTesting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.network_check),
                      label: Text(_isTesting ? 'Test Ediliyor...' : 'Bağlantıyı Test Et'),
                    ),

                    if (_testResult != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isSuccess == true
                              ? const Color(0xFF10B981).withOpacity(0.12)
                              : const Color(0xFFEF4444).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isSuccess == true
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                        child: Text(
                          _testResult!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _isSuccess == true
                                ? const Color(0xFF065F46)
                                : const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Kaydet Butonu
                    ElevatedButton(
                      onPressed: _saveSettings,
                      child: const Text('Ayarları Kaydet'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
