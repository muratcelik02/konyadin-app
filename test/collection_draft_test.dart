import 'package:flutter_test/flutter_test.dart';
import '../lib/models/collection_draft.dart';
import '../lib/models/photo_item.dart';

void main() {
  group('CollectionDraft Modeli ve İş Mantığı Testleri', () {
    test('Yeni taslak oluşturma ve varsayılan değerler', () {
      final draft = CollectionDraft(
        id: 'test-uuid-123',
        name: 'Şantiye İncelemesi',
      );

      expect(draft.id, 'test-uuid-123');
      expect(draft.name, 'Şantiye İncelemesi');
      expect(draft.photos, isEmpty);
      expect(draft.notes, '');
      expect(draft.noteFormat, 'md');
      expect(draft.createdAt, isNotNull);
    });

    test('Fotoğraf ekleme ve JSON serileştirme/deserileştirme', () {
      final draft = CollectionDraft(
        id: 'test-uuid-456',
        name: 'Proje Fotoğrafları',
        notes: 'Haftalık ilerleme notları',
        noteFormat: 'txt',
      );

      final photo1 = PhotoItem(
        id: 'photo-1',
        localPath: '/data/user/0/cache/photo_01.jpg',
        sequenceNumber: 1,
        originalName: 'IMG_001.jpg',
        fileSize: 2048500,
      );

      final photo2 = PhotoItem(
        id: 'photo-2',
        localPath: '/data/user/0/cache/photo_02.jpg',
        sequenceNumber: 2,
        originalName: 'IMG_002.jpg',
        fileSize: 1845000,
      );

      draft.photos.addAll([photo1, photo2]);

      final jsonMap = draft.toJson();
      final restored = CollectionDraft.fromJson(jsonMap);

      expect(restored.id, draft.id);
      expect(restored.name, draft.name);
      expect(restored.notes, draft.notes);
      expect(restored.noteFormat, 'txt');
      expect(restored.photos.length, 2);
      expect(restored.photos[0].sequenceNumber, 1);
      expect(restored.photos[1].sequenceNumber, 2);
      expect(restored.photos[0].originalName, 'IMG_001.jpg');
    });

    test('Fotoğraf silindiğinde sıra numaralarının yeniden düzenlenmesi', () {
      final draft = CollectionDraft(
        id: 'test-uuid-789',
        name: 'Sıra Düzenleme Testi',
      );

      for (int i = 1; i <= 4; i++) {
        draft.photos.add(
          PhotoItem(
            id: 'p-$i',
            localPath: '/tmp/$i.jpg',
            sequenceNumber: i,
            originalName: 'p_$i.jpg',
            fileSize: 1000,
          ),
        );
      }

      expect(draft.photos.length, 4);

      // 2. fotoğrafı (indeks 1) sil
      draft.photos.removeAt(1);

      // Kalanların sıra numaralarını güncelle
      for (int i = 0; i < draft.photos.length; i++) {
        draft.photos[i].sequenceNumber = i + 1;
      }

      expect(draft.photos.length, 3);
      expect(draft.photos[0].sequenceNumber, 1);
      expect(draft.photos[1].sequenceNumber, 2);
      expect(draft.photos[2].sequenceNumber, 3);
      expect(draft.photos[1].originalName, 'p_3.jpg'); // Eski 3. fotoğraf artık 2. sırada
    });
  });
}
