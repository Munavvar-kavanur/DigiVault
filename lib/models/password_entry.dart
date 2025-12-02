class PasswordEntry {
  final String id;
  String title;
  String username;
  String password;
  String? website;
  String? category;
  String? notes;
  DateTime? lastModified;

  PasswordEntry({
    required this.id,
    required this.title,
    required this.username,
    required this.password,
    this.website,
    this.category,
    this.notes,
    this.lastModified,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'username': username,
      'password': password,
      'website': website,
      'category': category,
      'notes': notes,
      'lastModified': lastModified?.toIso8601String(),
    };
  }

  factory PasswordEntry.fromJson(Map<String, dynamic> json) {
    return PasswordEntry(
      id: json['id'],
      title: json['title'],
      username: json['username'],
      password: json['password'],
      website: json['website'],
      category: json['category'],
      notes: json['notes'],
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'])
          : null,
    );
  }
}
