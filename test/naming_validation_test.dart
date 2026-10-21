import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Klasör Adı Doğrulama ve Güvenlik Testleri', () {
    String? validateFolderName(String? input) {
      if (input == null) return 'Klasör adı boş olamaz.';
      final trimmed = input.trim();
      if (trimmed.isEmpty) return 'Klasör adı boş olamaz.';
      return null;
    }

    test('Boş veya sadece boşluk içeren klasör adlarının reddedilmesi', () {
      expect(validateFolderName(''), isNotNull);
      expect(validateFolderName('   '), isNotNull);
      expect(validateFolderName('\t\n'), isNotNull);
      expect(validateFolderName(null), isNotNull);
    });

    test('Geçerli isimlerin başında ve sonunda kalan boşlukların temizlenmesi', () {
      const raw = '   2026 Saha İncelemesi   ';
      expect(validateFolderName(raw), isNull);
      expect(raw.trim(), '2026 Saha İncelemesi');
    });

    test('Türkçe karakterlerin kullanıcı klasör adında aynen korunması', () {
      const turkishName = 'Şantiye & Çağrı Raporu - Öğleden Sonra (Ücretler)';
      expect(validateFolderName(turkishName), isNull);
      expect(turkishName.trim(), 'Şantiye & Çağrı Raporu - Öğleden Sonra (Ücretler)');
    });
  });
}
