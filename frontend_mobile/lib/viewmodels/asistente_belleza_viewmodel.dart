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
  String? tonoPiel;
  String? subEstacion;

  String? formaRostro;
  List<String> recomendacionesCortes = [];
  List<String> recomendacionesPeinados = [];
  List<String> recomendacionesMaquillaje = [];
  List<String> recomendacionesMaquillajeOjos = [];

  Future<void> analizarFoto(File imagen) async {
    isLoading = true;
    errorMessage = null;
    coloresRecomendados = [];
    tonoPiel = null;
    formaRostro = null;
    recomendacionesPeinados = [];
    recomendacionesCortes = [];
    recomendacionesMaquillaje = [];
    recomendacionesMaquillajeOjos = [];
    notifyListeners();

    final uriColor = Uri.parse('$baseURL2/recomendaciones/colorimetria');
    final uriForma = Uri.parse('$baseURL2/recomendaciones/forma-cara');

    try {
      // Petición para colorimetría
      final responseColor = await httpMultipartPostConAuth(
        url: uriColor,
        filePath: imagen.path,
        field: 'imagen',
        fields: {},
      );

      if (responseColor != null && responseColor.statusCode == 200) {
        final jsonColor = json.decode(responseColor.body);
        tonoPiel = jsonColor['tono_piel'];
        subEstacion = jsonColor['subestacion'];
        coloresRecomendados = List<String>.from(
          jsonColor['colores_recomendados'] ?? [],
        );
        recomendacionesMaquillaje = List<String>.from(
          jsonColor['maquillaje'] ?? [],
        );
        recomendacionesMaquillajeOjos = List<String>.from(
          jsonColor['maquillaje_ojos'] ?? [],
        );
      }

      // Petición para forma del rostro
      final responseForma = await httpMultipartPostConAuth(
        url: uriForma,
        filePath: imagen.path,
        field: 'imagen',
        fields: {},
      );

      if (responseForma != null && responseForma.statusCode == 200) {
        final jsonForma = json.decode(responseForma.body);
        formaRostro = jsonForma['forma'];
        final sugerencias = jsonForma['sugerencias'] ?? {};
        recomendacionesCortes = List<String>.from(sugerencias['cortes'] ?? []);
        recomendacionesPeinados = List<String>.from(
          sugerencias['peinados'] ?? [],
        );
      }
    } catch (e) {
      errorMessage = 'Error al analizar la imagen: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
