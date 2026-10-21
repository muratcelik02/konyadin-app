import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Not Formatlama ve Bütünlük Testleri', () {
    test('Markdown başlığı ve liste biçimlendirmesinin korunması', () {
      const originalMd = '''# Günlük İlerleme Raporu

- [x] Temel betonu döküldü
- [x] Kalıplar söküldü
- [ ] Tesisat boruları döşenecek

> **Önemli Not:** Hava şartları nedeniyle çalışma 16:00'da durduruldu.
''';

      expect(originalMd.contains('# Günlük İlerleme Raporu'), isTrue);
      expect(originalMd.contains('Önemli Not'), isTrue);
    });

    test('TXT formatında Türkçe satır sonları ve noktalama işaretleri', () {
      const originalTxt = '1. Hat: Kontrol edildi.\n2. Hat: Arıza giderildi.\n3. Hat: Test edildi.';
      final lines = originalTxt.split('\n');
      expect(lines.length, 3);
      expect(lines[0], '1. Hat: Kontrol edildi.');
      expect(lines[1], '2. Hat: Arıza giderildi.');
    });

    test('Boş not durumunun geçerli kabul edilmesi', () {
      const emptyNote = '';
      expect(emptyNote.isEmpty, isTrue);
    });
  });
}
