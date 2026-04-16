import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/text_resume.dart';
import '../config/api_config.dart';

class TextResumeApiService {
  static const Duration _timeout = Duration(seconds: 30);

  static Future<String> get baseUrl async =>
      '${await ApiConfig.getBaseUrl()}/api/text-resumes';

  // Récupérer tous les textes résumés
  Future<List<TextResume>> getAllTextResumes({
    String? category,
    String? mois,
    String? annee,
    String? typeCulte,
    String? sortBy,
    String? order,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (category != null && category != 'All') {
        queryParams['category'] = category;
      }
      if (mois != null && mois != 'All') {
        queryParams['mois'] = mois;
      }
      if (annee != null && annee != 'All') {
        queryParams['annee'] = annee;
      }
      if (typeCulte != null && typeCulte != 'All') {
        queryParams['typeCulte'] = typeCulte;
      }
      if (sortBy != null) {
        queryParams['sortBy'] = sortBy;
      }
      if (order != null) {
        queryParams['order'] = order;
      }

      final uri = Uri.parse(await baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => TextResume.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load text resumes: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur getAllTextResumes: $e');
      rethrow;
    }
  }

  // Récupérer un texte résumé par ID
  Future<TextResume?> getTextResumeById(String id) async {
    try {
      final uri = Uri.parse('${await baseUrl}/$id');
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return TextResume.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load text resume: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur getTextResumeById: $e');
      rethrow;
    }
  }
}

