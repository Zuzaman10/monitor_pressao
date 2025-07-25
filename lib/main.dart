import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MonitorPressaoApp());
}

class MonitorPressaoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitor de Pressão',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MonitorPressaoHomePage(),
    );
  }
}

class MonitorPressaoHomePage extends StatefulWidget {
  @override
  _MonitorPressaoHomePageState createState() => _MonitorPressaoHomePageState();
}

class _MonitorPressaoHomePageState extends State<MonitorPressaoHomePage> {
  final _sistolicaController = TextEditingController();
  final _diastolicaController = TextEditingController();
  List<Map<String, dynamic>> _registros = [];

  @override
  void initState() {
    super.initState();
    _carregarRegistros();
  }

  Future<void> _carregarRegistros() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dados = prefs.getString('registros');
    if (dados != null) {
      setState(() {
        _registros = List<Map<String, dynamic>>.from(json.decode(dados));
      });
    }
  }

  Future<void> _salvarRegistros() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('registros', json.encode(_registros));
  }
void _editarRegistro(int index) {
  final item = _registros[index];
  final TextEditingController sistolicaController = TextEditingController(text: item['sistolica'].toString());
  final TextEditingController diastolicaController = TextEditingController(text: item['diastolica'].toString());

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Editar Registro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: sistolicaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Sistólica'),
            ),
            TextField(
              controller: diastolicaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Diastólica'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _registros[index]['sistolica'] = int.tryParse(sistolicaController.text) ?? item['sistolica'];
                _registros[index]['diastolica'] = int.tryParse(diastolicaController.text) ?? item['diastolica'];
                _salvarRegistros();
              });
              Navigator.of(context).pop();
            },
            child: Text('Salvar'),
          ),
        ],
      );
    },
  );
}

  void _adicionarRegistro() {
    final String sistolica = _sistolicaController.text;
    final String diastolica = _diastolicaController.text;

    if (sistolica.isEmpty || diastolica.isEmpty) return;

    final novoRegistro = {
      'sistolica': int.tryParse(sistolica),
      'diastolica': int.tryParse(diastolica),
      'data': DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
    };

    setState(() {
      _registros.insert(0, novoRegistro);
    });

    _salvarRegistros();
    _sistolicaController.clear();
    _diastolicaController.clear();
  }

  Future<void> _exportarExcel() async {
    final status = await Permission.storage.request();
    if (!status.isGranted) return;

    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];

    sheet.getRangeByName('A1').setText('Data');
    sheet.getRangeByName('B1').setText('Sistólica');
    sheet.getRangeByName('C1').setText('Diastólica');

    for (int i = 0; i < _registros.length; i++) {
      final registro = _registros[i];
      sheet.getRangeByName('A${i + 2}').setText(registro['data']);
      sheet.getRangeByName('B${i + 2}').setNumber((registro['sistolica'] ?? 0).toDouble());
      sheet.getRangeByName('C${i + 2}').setNumber((registro['diastolica'] ?? 0).toDouble());
    }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/pressao_registros.xlsx');
    await file.writeAsBytes(bytes, flush: true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Arquivo salvo em: ${file.path}')),
    );
  }

  Widget _buildGrafico() {
    if (_registros.length < 2) return Text('Adicione mais registros para ver o gráfico.');

    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: _registros.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), (e.value['sistolica'] ?? 0).toDouble());
            }).toList(),
            isCurved: true,
            color: Colors.red,
            barWidth: 2,
          ),
          LineChartBarData(
            spots: _registros.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), (e.value['diastolica'] ?? 0).toDouble());
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 2,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Monitor de Pressão'),
        actions: [
          IconButton(
            icon: Icon(Icons.save_alt),
            onPressed: _exportarExcel,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.asset('assets/images/heart.png', width: 80),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sistolicaController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Sistólica'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _diastolicaController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Diastólica'),
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _adicionarRegistro,
              child: Text('Registrar'),
            ),
            SizedBox(height: 20),
            SizedBox(height: 200, child: _buildGrafico()),
            SizedBox(height: 20),
                        Expanded(
              child: ListView.builder(
                itemCount: _registros.length,
                itemBuilder: (context, index) {
                  final item = _registros[index];
                  return Dismissible(
                    key: UniqueKey(),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Excluir Registro'),
                          content: Text('Tem certeza que deseja excluir este registro?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text('Excluir'),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) {
                      setState(() {
                        _registros.removeAt(index);
                        _salvarRegistros();
                      });
                    },
                    child: ListTile(
                      title: Text('${item['sistolica']}/${item['diastolica']} mmHg'),
                      subtitle: Text(item['data']),
                      onTap: () {
                        _editarRegistro(index);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
