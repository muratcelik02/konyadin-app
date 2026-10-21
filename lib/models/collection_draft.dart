import 'photo_item.dart';

class CollectionDraft {
  final String id;
  String name;
  List<PhotoItem> photos;
  String notes;
  String noteFormat; // 'md' veya 'txt'
  final DateTime createdAt;

  CollectionDraft({
    required this.id,
    required this.name,
    List<PhotoItem>? photos,
    this.notes = '',
    this.noteFormat = 'md',
    DateTime? createdAt,
  })  : photos = photos ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'photos': photos.map((p) => p.toJson()).toList(),
    'notes': notes,
    'noteFormat': noteFormat,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CollectionDraft.fromJson(Map<String, dynamic> json) => CollectionDraft(
    id: json['id'] as String,
    name: json['name'] as String,
    photos: (json['photos'] as List<dynamic>?)
            ?.map((p) => PhotoItem.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [],
    notes: json['notes'] as String? ?? '',
    noteFormat: json['noteFormat'] as String? ?? 'md',
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
  );
}
