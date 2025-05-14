import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../viewmodels/graficos_costos_viewmodel.dart';
import '../widgets/armario_nav_bar.dart';
import 'miarmario_screen.dart';
import 'feed_screen.dart';
import 'search_prendas_screen.dart';
import 'asistente_belleza_screen.dart';

class GraficosCostosScreen extends StatelessWidget {
  const GraficosCostosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GraficosCostosViewModel()..fetchDatos(),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF0F0),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFF0F0),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFFFB5B2)),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const FeedScreen()),
              );
            },
          ),
          title: const Text(
            "Gasto en moda",
            style: TextStyle(color: Color(0xFFFFB5B2)),
          ),
          centerTitle: true,
        ),

        body: Consumer<GraficosCostosViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Costo total del armario',
                      style: TextStyle(fontSize: 18, color: Color(0xFFFFB5B2)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${vm.totalGasto.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFB5B2),
                      ),
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      'Gasto por tipo de prenda',
                      style: TextStyle(fontSize: 18, color: Color(0xFFFFB5B2)),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 240,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 0, // ❌ sin hueco en el centro
                          sections:
                              vm.gastosPorTipo.entries.map((entry) {
                                final index = vm.gastosPorTipo.keys
                                    .toList()
                                    .indexOf(entry.key);
                                final color =
                                    Colors.primaries[index %
                                        Colors
                                            .primaries
                                            .length]; // ✅ colores variados
                                return PieChartSectionData(
                                  value: entry.value,
                                  title: '${entry.value.toStringAsFixed(0)}€',
                                  titleStyle: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                  color: color,
                                  radius: 80,
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      alignment: WrapAlignment.center,
                      children:
                          vm.gastosPorTipo.keys.map((tipo) {
                            final index = vm.gastosPorTipo.keys
                                .toList()
                                .indexOf(tipo);
                            final color =
                                Colors.primaries[index %
                                    Colors.primaries.length];
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 12, height: 12, color: color),
                                const SizedBox(width: 4),
                                Text(
                                  tipo,
                                  style: const TextStyle(
                                    color: Color(0xFFFFB5B2),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                    ),

                    const SizedBox(height: 32),
                    const Text(
                      'Evolución del gasto',
                      style: TextStyle(fontSize: 18, color: Color(0xFFFFB5B2)),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 250,
                      child: LineChart(
                        LineChartData(
                          minY: 0,
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  final int index = value.toInt();
                                  if (index < vm.evolucionDiaria.length) {
                                    final fecha =
                                        vm.evolucionDiaria[index]['dia'];
                                    return Text(
                                      fecha.substring(5), // MM-DD
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFFFFB5B2),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                interval: 1000,
                                getTitlesWidget:
                                    (value, _) => Text(
                                      '${value ~/ 1000}K',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFFFFB5B2),
                                      ),
                                    ),
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              isCurved: true,
                              barWidth: 3,
                              color: const Color(0xFFFFB5B2),
                              belowBarData: BarAreaData(show: false),
                              dotData: FlDotData(show: true),
                              spots: List.generate(vm.evolucionDiaria.length, (
                                i,
                              ) {
                                final punto = vm.evolucionDiaria[i];
                                return FlSpot(i.toDouble(), punto['total']);
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: ArmarioNavBar(
          currentIndex: 1,
          onTap: (index) {
            if (index == 0) {
              // IA
            } else if (index == 1) {
              // Ya estás en gráficos
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MiArmarioScreen()),
              );
            } else if (index == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AsistenteBellezaScreen()),
              );
            } else if (index == 4) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SearchPrendasScreen()),
              );
            }
          },
        ),
      ),
    );
  }
}
