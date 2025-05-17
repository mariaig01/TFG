import 'package:flutter/material.dart';
import 'dart:convert'; // Asegúrate de importar esto para json.decode
import 'dart:io';
import '../env.dart';
import '../services/http_auth_service.dart';

class AsistenteBellezaViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;
  List<String> coloresRecomendados = [];
  String? peinados;
  String? maquillaje;
  String? tonoPiel;
  String? subEstacion;

  Future<void> analizarFoto(File imagen) async {
    isLoading = true;
    errorMessage = null;
    coloresRecomendados = [];
    tonoPiel = null;
    peinados = null;
    maquillaje = null;
    notifyListeners();

    final uri = Uri.parse('$baseURL2/recomendaciones/colorimetria');

    try {
      final response = await httpMultipartPostConAuth(
        url: uri,
        filePath: imagen.path,
        field: 'imagen',
        fields: {},
      );

      if (response != null && response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        tonoPiel = jsonResponse['tono_piel'];
        subEstacion = jsonResponse['subestacion'];
        coloresRecomendados = List<String>.from(
          jsonResponse['colores_recomendados'] ?? [],
        );
      } else {
        errorMessage =
            'Error: ${response?.body ?? 'Sin respuesta del servidor'}';
      }
    } catch (e) {
      errorMessage = 'Error al analizar la imagen: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
