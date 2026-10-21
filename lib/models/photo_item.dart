class PhotoItem {
  final String id;
  final String localPath;
  int sequenceNumber;
  final String originalName;
  final int fileSize;
  bool isUploaded;
  String? uploadedSha256;

  PhotoItem({
    required this.id,
    required this.localPath,
    required this.sequenceNumber,
    required this.originalName,
    required this.fileSize,
    this.isUploaded = false,
    this.uploadedSha256,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'localPath': localPath,
    'sequenceNumber': sequenceNumber,
    'originalName': originalName,
    'fileSize': fileSize,
    'isUploaded': isUploaded,
    'uploadedSha256': uploadedSha256,
  };

  factory PhotoItem.fromJson(Map<String, dynamic> json) => PhotoItem(
    id: json['id'] as String,
    localPath: json['localPath'] as String,
    sequenceNumber: json['sequenceNumber'] as int,
    originalName: json['originalName'] as String,
    fileSize: json['fileSize'] as int,
    isUploaded: json['isUploaded'] as bool? ?? false,
    uploadedSha256: json['uploadedSha256'] as String?,
  );
}
