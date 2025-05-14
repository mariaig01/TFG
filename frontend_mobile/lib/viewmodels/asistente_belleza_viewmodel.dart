import 'package:flutter/material.dart';
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

  Future<void> analizarFoto(File imagen) async {
    isLoading = true;
    errorMessage = null;
    successMessage = null;
    coloresRecomendados = [];
    notifyListeners();

    final uri = Uri.parse(
      '$baseURL/api/analisis-color',
    ); // Modifica si usas otro endpoint

    try {
      final response = await httpMultipartPostConAuth(
        url: uri,
        filePath: imagen.path,
        field: 'imagen',
        fields: {},
      );

      if (response != null && response.statusCode == 200) {
        // Simulación del análisis (sustituye por JSON real si aplica)
        coloresRecomendados = ['Verde esmeralda', 'Rosa pastel', 'Gris perla'];
        successMessage = 'Análisis completado con éxito';
      } else {
        errorMessage =
            'Error: ${response?.body ?? 'sin respuesta del servidor'}';
      }
    } catch (e) {
      errorMessage = 'Error al analizar la imagen: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
