import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'dart:convert';

class DataService {
  final ValueNotifier<List> tableStateNotifier = ValueNotifier([]);
  final ValueNotifier<List<String>> columnNames = ValueNotifier([]);
  final ValueNotifier<List<String>> propertyNames = ValueNotifier([]);
  final ValueNotifier<int> size = ValueNotifier(5);

  void carregar(index) {
    var res = null;
    if (index == 1) {
      res = carregarCervejas(size.value);
    } else if (index == 0) {
      res = carregarCafes(size.value);
    } else if (index == 2) {
      res = carregarNacoes(size.value);
    }
  }

  Future<void> carregarCervejas(int size) async {
    var beersUri = Uri(
        scheme: 'https',
        host: 'random-data-api.com',
        path: 'api/beer/random_beer',
        queryParameters: {'size': size.toString()});

    var jsonString = await http.read(beersUri);

    var beersJson = jsonDecode(jsonString);

    tableStateNotifier.value = beersJson;
    columnNames.value = ["Nome", "Estilo", "IBU"];
    propertyNames.value = ["name", "style", "ibu"];
  }

  Future<void> carregarCafes(int size) async {
    var cafesUri = Uri(
        scheme: 'https',
        host: 'random-data-api.com',
        path: 'api/coffee/random_coffee',
        queryParameters: {'size': size.toString()});

    var jsonString = await http.read(cafesUri);

    var cafesJson = jsonDecode(jsonString);

    tableStateNotifier.value = cafesJson;
    columnNames.value = ["Nome", "Origem", "Intensificador"];
    propertyNames.value = ["blend_name", "origin", "intensifier"];
  }

  Future<void> carregarNacoes(int size) async {
    var nacoesUri = Uri(
        scheme: 'https',
        host: 'random-data-api.com',
        path: 'api/nation/random_nation',
        queryParameters: {'size': size.toString()});

    var jsonString = await http.read(nacoesUri);

    var nacoesJson = jsonDecode(jsonString);

    tableStateNotifier.value = nacoesJson;
    columnNames.value = ["Nacionalidade", "Língua", "Capital"];
    propertyNames.value = ["nationality", "language", "capital"];
  }
}

final dataService = DataService();

void main() {
  MyApp app = const MyApp();

  dataService.carregarCervejas(5); // Carrega as cervejas iniciais

  runApp(app);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Dicas"),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Theme(
                data: Theme.of(context).copyWith(
                  canvasColor:
                      Colors.deepPurple, // Cor de fundo do menu suspenso
                ),
                child: DropdownButton<int>(
                  value: dataService.size.value,
                  items: const [
                    DropdownMenuItem(
                      value: 5,
                      child: Text(
                        '5',
                        style: TextStyle(color: Colors.white), // Cor do número
                      ),
                    ),
                    DropdownMenuItem(
                      value: 10,
                      child: Text(
                        '10',
                        style: TextStyle(color: Colors.white), // Cor do número
                      ),
                    ),
                    DropdownMenuItem(
                      value: 15,
                      child: Text(
                        '15',
                        style: TextStyle(color: Colors.white), // Cor do número
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    dataService.size.value = value!;
                    if (dataService.tableStateNotifier.value.isNotEmpty) {
                      dataService.carregarCervejas(value);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        body: ValueListenableBuilder(
          valueListenable: dataService.tableStateNotifier,
          builder: (_, value, __) {
            return DataTableWidget(
              jsonObjects: value,
              columnNames: dataService.columnNames.value,
              propertyNames: dataService.propertyNames.value,
            );
          },
        ),
        bottomNavigationBar: NewNavBar(
          itemSelectedCallback: dataService.carregar,
          items: const [
            BottomNavigationBarItem(
              label: "Cafés",
              icon: Icon(Icons.coffee_outlined),
            ),
            BottomNavigationBarItem(
              label: "Cervejas",
              icon: Icon(Icons.local_drink_outlined),
            ),
            BottomNavigationBarItem(
              label: "Nações",
              icon: Icon(Icons.flag_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class NewNavBar extends HookWidget {
  final _itemSelectedCallback;
  final List<BottomNavigationBarItem> items;

  const NewNavBar({super.key, itemSelectedCallback, required this.items})
      : _itemSelectedCallback = itemSelectedCallback ?? (int);

  @override
  Widget build(BuildContext context) {
    var state = useState(1);

    return BottomNavigationBar(
      onTap: (index) {
        state.value = index;
        _itemSelectedCallback(index as int);
      },
      currentIndex: state.value,
      items: items,
    );
  }
}

class DataTableWidget extends StatelessWidget {
  final List jsonObjects;
  final List<String> columnNames;
  final List<String> propertyNames;

  const DataTableWidget({
    super.key,
    this.jsonObjects = const [],
    this.columnNames = const [],
    this.propertyNames = const [],
  });

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: columnNames
          .map(
            (name) => DataColumn(
              label: Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
          )
          .toList(),
      rows: jsonObjects
          .map(
            (obj) => DataRow(
              cells: propertyNames
                  .map(
                    (propName) => DataCell(
                      Text(getPropertyValue(obj, propName) ?? ''),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );
  }

  dynamic getPropertyValue(Map<String, dynamic> object, String propertyName) {
    var properties = propertyName.split('.');
    dynamic value = object;

    for (var prop in properties) {
      if (value is Map<String, dynamic> && value.containsKey(prop)) {
        value = value[prop];
      } else {
        return null;
      }
    }

    return value;
  }
}
