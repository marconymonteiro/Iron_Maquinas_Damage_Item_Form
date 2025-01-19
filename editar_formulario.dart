import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_extend/share_extend.dart'; // Pacote de compartilhamento
import 'pdf_generator.dart'; // Certifique-se de que esta classe esteja implementada
//import 'inspection_form.dart'; // Certifique-se de importar o arquivo com a classe de formulário original
import 'package:image/image.dart' as img;

class EditarFormulario extends StatefulWidget {
  final String formId; // ID do formulário a ser editado
  const EditarFormulario({required this.formId, Key? key}) : super(key: key);

  @override
  _EditarFormularioState createState() => _EditarFormularioState();
}

class _EditarFormularioState extends State<EditarFormulario> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {
    'name': TextEditingController(),
    'cargo': TextEditingController(),
    'serialNumber': TextEditingController(),
    'invoiceNumber': TextEditingController(),
    'damageDescription': TextEditingController(),
    'codigo': TextEditingController(), // Novo controlador para o campo "Código"
    'equipment': TextEditingController(), // Novo controlador para o campo "Equipamento"
    'freight': TextEditingController(), // Novo controlador para o campo "transportadora"
    'plate': TextEditingController(), // Novo controlador para o campo "placas"
    'driverID': TextEditingController(), // Novo controlador para o campo "CPF"
    'model': TextEditingController(), // Novo controlador para o campo "modelo"
    'sanyRef': TextEditingController(), // Novo controlador para o campo "Referência Sany"
    'invoiceQtty': TextEditingController(), // Novo controlador para o campo "Quantidade de Volumes"
    'invoiceItems': TextEditingController(), // Novo controlador para o campo "Quantidade Partes e Peças"
  };

  // String _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
  DateTime? _selectedDate; // PARA NOVO PICKDATETIME

  String _hasDamage = 'Selecione';
  final List<File> _photosCarga = [];
  final List<File> _photosDamage = [];

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

// PARTE DO NOVO PICKDATETIME

Future<void> _pickDateTime() async {
  final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: _selectedDate ?? DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2101),
      locale: const Locale('pt', 'BR'), // Idioma definido aqui
  );

  if (pickedDate != null) {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()),
    );

    if (pickedTime != null) {
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }
}

// FIM DO PICK DATE TIME

  Future<void> _loadForm() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      for (var entry in _controllers.entries) {
        entry.value.text = prefs.getString('${widget.formId}-${entry.key}') ?? '';
      }
      _hasDamage = prefs.getString('${widget.formId}-hasDamage') ?? 'Selecione';
      _photosCarga.addAll((prefs.getStringList('${widget.formId}-photosCarga') ?? []).map((path) => File(path)));
      _photosDamage.addAll((prefs.getStringList('${widget.formId}-photosDamage') ?? []).map((path) => File(path)));
   
        _selectedDate = prefs.getString('${widget.formId}-selectedDate') != null
      ? DateTime.parse(prefs.getString('${widget.formId}-selectedDate')!)
      : null;   
   
    });
  }

// NOVA SESSÃO DE CÓDIGO

Widget _buildPhotoPreview(List<File> photos, List<File> photoList) {
  return photos.isNotEmpty
      ? Wrap(
          spacing: 8,
          children: photos.map((photo) {
            return Stack(
              alignment: Alignment.topRight,
              children: [
                GestureDetector(
                  onTap: () => _showFullImage(photo),
                  child: Image.file(photo, height: 100, width: 100, fit: BoxFit.cover),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => _confirmDeletePhoto(photo, photoList),
                ),
              ],
            );
          }).toList(),
        )
      : const SizedBox();
}

Future<void> _confirmDeletePhoto(File photo, List<File> photoList) async {
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Excluir Imagem'),
        content: const Text('Tem certeza que deseja excluir a imagem?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sim'),
          ),
        ],
      );
    },
  );

  if (shouldDelete == true) {
    setState(() {
      photoList.remove(photo);
    });
  }
}
  void _showFullImage(File photo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(photo),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();

    try {
      for (var entry in _controllers.entries) {
        await prefs.setString('${widget.formId}-${entry.key}', entry.value.text);
      }
      await prefs.setString('${widget.formId}-hasDamage', _hasDamage);
      await prefs.setStringList('${widget.formId}-photosCarga', _photosCarga.map((e) => e.path).toList());
      await prefs.setStringList('${widget.formId}-photosDamage', _photosDamage.map((e) => e.path).toList());

      await prefs.setString('${widget.formId}-selectedDate', _selectedDate?.toIso8601String() ?? ''); //Add selectedDate

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formulário editado com sucesso!')),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar o formulário.')),
      );
    }
  }

Future<Uint8List> _compressImage(File image) async {
    final bytes = await image.readAsBytes();
    final decodedImage = img.decodeImage(bytes);
    final compressedImage = img.encodeJpg(decodedImage!, quality: 50);
    return Uint8List.fromList(compressedImage);
  }

  Future<void> _pickImage(List<File> photoList) async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      final tempFile = File(photo.path);
      final compressedBytes = await _compressImage(tempFile);

      // Salvar a imagem compactada em um arquivo temporário
      final compressedFile = await File(tempFile.path)
          .writeAsBytes(compressedBytes);

      setState(() {
        photoList.add(compressedFile);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final pdfFile = await PdfGenerator().generatePdf(
      name: _controllers['name']!.text,
      cargo: _controllers['cargo']!.text,
      serialNumber: _controllers['serialNumber']!.text,
      invoiceNumber: _controllers['invoiceNumber']!.text,
      codigo: _controllers['codigo']!.text,
      equipment: _controllers['equipment']!.text,
      freight: _controllers['freight']!.text,
      plate: _controllers['plate']!.text,
      driverID: _controllers['driverID']!.text,
      model: _controllers['model']!.text,
      sanyRef: _controllers['sanyRef']!.text,
      invoiceQtty: _controllers['invoiceQtty']!.text,
      invoiceItems: _controllers['invoiceItems']!.text,

      reportDate: _selectedDate != null
          ? DateFormat('dd/MM/yyyy', 'pt_BR').format(_selectedDate!)
          : 'Data não selecionada',
      hasDamage: _hasDamage == 'Sim',
      damageDescription: _controllers['damageDescription']!.text,
      photosCarga: _photosCarga,
      photosDamage: _photosDamage,
    );

    await ShareExtend.share(pdfFile.path, 'application/pdf');
  }

  Future<void> _deleteForm() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmação'),
          content: const Text('Tem certeza que deseja excluir o formulário? Essa ação não poderá ser desfeita.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Excluir',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${widget.formId}-name');
      await prefs.remove('${widget.formId}-cargo');
      await prefs.remove('${widget.formId}-serialNumber');
      await prefs.remove('${widget.formId}-invoiceNumber');
      await prefs.remove('${widget.formId}-hasDamage');
      await prefs.remove('${widget.formId}-damageDescription');
      await prefs.remove('${widget.formId}-photosCarga');
      await prefs.remove('${widget.formId}-photosDamage');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formulário excluído com sucesso!')),
      );

      Navigator.of(context).pop();
    }
  }

  String _getLabel(String key) {
    switch (key) {
      case 'name':
        return 'Nome';
      case 'cargo':
        return 'Carga';
      case 'serialNumber':
        return 'Número de Série';
      case 'invoiceNumber':
        return 'Número da Nota Fiscal';
      case 'damageDescription':
        return 'Descrição do Dano';
      case 'codigo':
        return 'Código';
      case 'equipment':
        return 'Equipamento';
      case 'freight':
        return 'Transportadora';
      case 'plate':
        return 'Placas';
      case 'driverID':
        return 'CPF';
      case 'model':
        return 'Modelo';
      case 'sanyRef':
        return 'Referência SANY';
      case 'invoiceQtty':
        return 'Quantidade Total de Volumes da NF';
      case 'invoiceItems':
        return 'Quantidade Volume Partes e Peças da NFF';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Formulário de Inspeção')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Data e Hora: ${_selectedDate != null ? DateFormat('dd/MM/yyyy HH:mm').format(_selectedDate!) : 'Selecione a data e hora'}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _pickDateTime,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controllers['codigo'],
                  decoration: const InputDecoration(labelText: 'Código'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controllers['equipment'],
                  decoration: const InputDecoration(labelText: 'Equipamento'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controllers['freight'],
                  decoration: const InputDecoration(labelText: 'Transportadora'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controllers['plate'],
                  decoration: const InputDecoration(labelText: 'Placas'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controllers['name'],
                  decoration: const InputDecoration(labelText: 'Nome do Motorista'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controllers['driverID'],
                  decoration: const InputDecoration(labelText: 'CPF'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controllers['model'],
                  decoration: const InputDecoration(labelText: 'Modelo'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controllers['cargo'],
                  decoration: const InputDecoration(labelText: 'Máquina'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controllers['serialNumber'],
                  decoration: const InputDecoration(labelText: 'Número de Série'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controllers['invoiceNumber'],
                  decoration: const InputDecoration(labelText: 'Número da Nota Fiscal'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controllers['sanyRef'],
                  decoration: const InputDecoration(labelText: 'Referência SANY'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controllers['invoiceQtty'],
                  decoration: const InputDecoration(labelText: 'Quantidade Total de Volumes da NF'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controllers['invoiceItems'],
                  decoration: const InputDecoration(labelText: 'Quantidade Volume Partes e Peças da NF'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _pickImage(_photosCarga),
                  child: const Text('Adicionar Foto Carga'),
                ),
                _buildPhotoPreview(_photosCarga, _photosCarga),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _hasDamage,
                  items: ['Selecione', 'Sim', 'Não']
                      .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) => setState(() => _hasDamage = value!),
                  decoration: const InputDecoration(labelText: 'Há dano?'),
                  validator: (value) => value == 'Selecione' ? 'Selecione uma opção' : null,
                ),
                if (_hasDamage == 'Sim') ...[
                  TextFormField(
                    controller: _controllers['damageDescription'],
                    decoration: const InputDecoration(labelText: 'Descrição do Dano'),
                    validator: (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _pickImage(_photosDamage),
                    child: const Text('Adicionar Foto Dano'),
                  ),
                  _buildPhotoPreview(_photosDamage, _photosDamage),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saveForm,
                  child: const Text('Salvar Alterações'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Gerar PDF'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _deleteForm,
                  child: const Text('Excluir Formulário'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
