import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../viewmodels/search_prendas_viewmodel.dart';
import 'package:provider/provider.dart';
import '../widgets/armario_nav_bar.dart';
import 'miarmario_screen.dart';
import 'feed_screen.dart';
import 'graficos_costos_screen.dart';
import 'asistente_belleza_screen.dart';

class SearchPrendasScreen extends StatefulWidget {
  const SearchPrendasScreen({super.key});
  @override
  SearchPrendasScreenState createState() => SearchPrendasScreenState();
}

class SearchPrendasScreenState extends State<SearchPrendasScreen> {
  final Color pinkColor = const Color(0xFFFFB5B2);
  final SearchPrendasViewModel viewModel = SearchPrendasViewModel();
  final TextEditingController _controller = TextEditingController();
  String? selectedStore;
  RangeValues selectedPriceRange = const RangeValues(0, 150);

  @override
  void dispose() {
    viewModel.dispose();
    _controller.dispose();
    super.dispose();
  }

  void applyFilters() {
    viewModel.applyFilters(
      store: selectedStore,
      minPrice: selectedPriceRange.start,
      maxPrice: selectedPriceRange.end,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
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
            'Buscador de prendas',
            style: TextStyle(color: Color(0xFFFFB5B2)),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: pinkColor),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: viewModel.setQuery,
                        onSubmitted: (_) => viewModel.search(),
                        decoration: const InputDecoration(
                          hintText: 'Search',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.search, color: pinkColor),
                      onPressed: viewModel.search,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('Precio'),
                        onSelected: (_) async {
                          final selected = await showDialog<RangeValues>(
                            context: context,
                            builder: (_) {
                              RangeValues tempRange = selectedPriceRange;
                              return AlertDialog(
                                title: const Text(
                                  'Selecciona el rango de precios',
                                ),
                                content: StatefulBuilder(
                                  builder: (context, setState) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${tempRange.start.toInt()}€ - ${tempRange.end.toInt()}€',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        RangeSlider(
                                          values: tempRange,
                                          min: 0,
                                          max: 400,
                                          divisions: 15,
                                          labels: RangeLabels(
                                            '${tempRange.start.toInt()}€',
                                            '${tempRange.end.toInt()}€',
                                          ),
                                          onChanged: (values) {
                                            setState(() => tempRange = values);
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, null),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, tempRange),
                                    child: const Text('Aplicar'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (selected != null) {
                            setState(() => selectedPriceRange = selected);
                            applyFilters();
                          }
                        },
                        backgroundColor: Colors.white,
                        shape: StadiumBorder(
                          side: BorderSide(color: pinkColor),
                        ),
                        labelStyle: TextStyle(color: pinkColor),
                      ),
                      const SizedBox(width: 10),
                      FilterChip(
                        label: const Text('Tienda'),
                        onSelected: (_) async {
                          final store = await showDialog<String>(
                            context: context,
                            builder:
                                (_) => SimpleDialog(
                                  title: const Text('Selecciona una tienda'),
                                  children:
                                      viewModel.allStores.map((s) {
                                          return SimpleDialogOption(
                                            child: Text(s),
                                            onPressed:
                                                () => Navigator.pop(context, s),
                                          );
                                        }).toList()
                                        ..add(
                                          SimpleDialogOption(
                                            child: const Text('Todas'),
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  null,
                                                ),
                                          ),
                                        ),
                                ),
                          );
                          if (store != null || store == null) {
                            setState(() => selectedStore = store);
                            applyFilters();
                          }
                        },
                        backgroundColor: Colors.white,
                        shape: StadiumBorder(
                          side: BorderSide(color: pinkColor),
                        ),
                        labelStyle: TextStyle(color: pinkColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Consumer<SearchPrendasViewModel>(
                    builder: (_, vm, __) {
                      final hasStore = vm.selectedStore != null;
                      final hasPrice =
                          vm.minPrice != null &&
                          vm.maxPrice != null &&
                          (vm.minPrice! > 0 || vm.maxPrice! < 400);

                      if (!hasStore && !hasPrice)
                        return const SizedBox.shrink();

                      return Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (hasStore)
                            Chip(
                              label: Text('Tienda: ${vm.selectedStore}'),
                              deleteIcon: const Icon(Icons.close),
                              onDeleted: () {
                                setState(() {
                                  selectedStore = null;
                                  viewModel.selectedStore = null;
                                });
                                applyFilters();
                              },
                            ),
                          if (hasPrice)
                            Chip(
                              label: Text(
                                'Precio: ${vm.minPrice?.toInt()}€ - ${vm.maxPrice?.toInt()}€',
                              ),
                              deleteIcon: const Icon(Icons.close),
                              onDeleted: () {
                                setState(() {
                                  selectedPriceRange = const RangeValues(
                                    0,
                                    400,
                                  );
                                  viewModel.minPrice = null;
                                  viewModel.maxPrice = null;
                                });
                                applyFilters();
                              },
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: viewModel.resultsNotifier,
                  builder: (context, results, _) {
                    if (results.isEmpty) {
                      return const Center(child: Text('No results'));
                    }
                    return ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final item = results[index];
                        return GestureDetector(
                          onTap: () => launchUrl(Uri.parse(item['link']!)),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: pinkColor),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: pinkColor),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child:
                                      item['imagen'] != null &&
                                              item['imagen']!.isNotEmpty
                                          ? Image.network(
                                            item['imagen']!,
                                            fit: BoxFit.cover,
                                          )
                                          : const Icon(
                                            Icons.image,
                                            color: Colors.grey,
                                          ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['store'] ?? 'No Store',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: pinkColor,
                                        ),
                                      ),
                                      Text(item['product'] ?? 'No Product'),
                                    ],
                                  ),
                                ),
                                Text(
                                  item['price'] ?? '',
                                  style: TextStyle(color: pinkColor),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: ArmarioNavBar(
          currentIndex: 4,
          onTap: (index) {
            if (index == 0) {
              // IA
            } else if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GraficosCostosScreen()),
              );
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
              // comparador
            }
          },
        ),
      ),
    );
  }
}
