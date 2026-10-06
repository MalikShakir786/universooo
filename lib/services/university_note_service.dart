import 'dart:convert';
import 'dart:io';
import '../services/excel_database_service.dart';

class UniversityNoteModel {
  final String universityName;
  final String details;
  final String country;

  UniversityNoteModel({required this.universityName, required this.details, this.country = ''});

  Map<String, dynamic> toJson() => {
        'universityName': universityName,
        'details': details,
        'country': country,
      };

  factory UniversityNoteModel.fromJson(Map<String, dynamic> json) =>
      UniversityNoteModel(
        universityName: json['universityName'] ?? '',
        details: json['details'] ?? '',
        country: json['country'] ?? '',
      );
}

class UniversityNoteService {
  static Future<File> _getFile() async {
    final dbFile = await ExcelDatabaseService.instance.getDatabaseFile();
    return File('${dbFile.parent.path}/university_notes.json');
  }

  static Future<List<UniversityNoteModel>> loadNotes() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];
      final jsonStr = await file.readAsString();
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => UniversityNoteModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveNotes(List<UniversityNoteModel> notes) async {
    try {
      final file = await _getFile();
      if (!await file.parent.exists()) await file.parent.create(recursive: true);
      final jsonStr = jsonEncode(notes.map((e) => e.toJson()).toList());
      await file.writeAsString(jsonStr);
    } catch (e) {
      print(e);
    }
  }
}
