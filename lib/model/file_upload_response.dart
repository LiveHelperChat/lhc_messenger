class FileUploadResponse {
  final int id;
  final String name;
  final String uploadName;
  final String type;
  final String filePath;
  final int size;
  final String extension;
  final int date;
  final int userId;
  final int chatId;
  final int onlineUserId;
  final int persistent;
  final String securityHash;

  FileUploadResponse({
    required this.id,
    required this.name,
    required this.uploadName,
    required this.type,
    required this.filePath,
    required this.size,
    required this.extension,
    required this.date,
    required this.userId,
    required this.chatId,
    required this.onlineUserId,
    required this.persistent,
    required this.securityHash,
  });

  // Factory method to create an instance from JSON
  factory FileUploadResponse.fromJson(Map<String, dynamic> json) {
    return FileUploadResponse(
      id: json['id'],
      name: json['name'],
      uploadName: json['upload_name'],
      type: json['type'],
      filePath: json['file_path'],
      size: json['size'],
      extension: json['extension'],
      date: json['date'],
      userId: json['user_id'],
      chatId: json['chat_id'],
      onlineUserId: json['online_user_id'],
      persistent: json['persistent'],
      securityHash: json['security_hash'],
    );
  }

  // Method to convert the instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'upload_name': uploadName,
      'type': type,
      'file_path': filePath,
      'size': size,
      'extension': extension,
      'date': date,
      'user_id': userId,
      'chat_id': chatId,
      'online_user_id': onlineUserId,
      'persistent': persistent,
      'security_hash': securityHash,
    };
  }

  // Override toString
  @override
  String toString() {
    return 'FileUploadResponse(id: $id, name: $name, uploadName: $uploadName, type: $type, filePath: $filePath, size: $size, extension: $extension, date: $date, userId: $userId, chatId: $chatId, onlineUserId: $onlineUserId, persistent: $persistent, securityHash: $securityHash)';
  }
}
