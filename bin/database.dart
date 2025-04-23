import 'dart:io';

import 'package:path/path.dart';
import 'package:sqlite3/sqlite3.dart';

late final Database db;

void initDatabase() {
  final dbPath = join(Directory.current.path, 'user_data.db');
  db = sqlite3.open(dbPath);

  db.execute(''' 
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY,
      phone TEXT,
      full_name TEXT,
      language TEXT
    )
  ''');
}

void saveUser(int id, String fullName, String language, [String? phone]) {
  db.execute(
    '''
    INSERT OR REPLACE INTO users (id, full_name, language, phone)
    VALUES (?, ?, ?, ?)
  ''',
    [id, fullName, language, phone],
  );
}

void updateFullName(int id, String fullName) {
  db.execute(
    '''
    UPDATE users SET full_name = ? WHERE id = ? 
  ''',
    [fullName, id],
  );
}

void deleteUserData(int id) {
  db.execute('DELETE FROM users WHERE id = ?', [id]);
}

String? getUserLanguage(int id) {
  final result = db.select('SELECT language FROM users WHERE id = ?', [id]);
  if (result.isNotEmpty) {
    return result.first['language'] as String?;
  }
  return null;
}

Map<String, dynamic>? getUserProfile(int id) {
  final result = db.select('SELECT * FROM users WHERE id = ?', [id]);
  if (result.isNotEmpty) {
    return {
      'full_name': result.first['full_name'],
      'phone': result.first['phone'],
      'language': result.first['language'],
    };
  }
  return null;
}
