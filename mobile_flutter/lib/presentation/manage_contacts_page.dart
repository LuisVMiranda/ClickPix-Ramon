import 'dart:io';

import 'package:clickpix_ramon/core/i18n/ui_text.dart';
import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:clickpix_ramon/data/repositories/local_client_repository.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ManageContactsPage extends StatefulWidget {
  const ManageContactsPage({
    required this.database,
    super.key,
  });

  final AppDatabase database;

  @override
  State<ManageContactsPage> createState() => _ManageContactsPageState();
}

class _ManageContactsPageState extends State<ManageContactsPage> {
  late final LocalClientRepository _clientRepository;
  List<ClientSummary> _clients = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _clientRepository = LocalClientRepository(widget.database);
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() => _loading = true);
    final contacts = await _clientRepository.listClients();
    if (!mounted) {
      return;
    }
    setState(() {
      _clients = contacts;
      _loading = false;
    });
  }

  Future<void> _openContactEditor([ClientSummary? existing]) async {
    final result = await Navigator.of(context).push<_ContactFormResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _ContactEditorPage(existing: existing),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    if (existing == null) {
      await _clientRepository.createClient(
        id: 'client_${DateTime.now().microsecondsSinceEpoch}',
        name: result.name,
        whatsapp: result.whatsapp,
        email: result.email,
      );
      if (result.addToPhoneContacts) {
        await _saveInPhoneContacts(result);
      }
    } else {
      await _clientRepository.updateClient(
        id: existing.id,
        name: result.name,
        whatsapp: result.whatsapp,
        email: result.email,
      );
    }

    await _loadClients();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing == null
              ? tr(
                  context,
                  pt: 'Contato adicionado.',
                  es: 'Contacto agregado.',
                  en: 'Contact added.',
                )
              : tr(
                  context,
                  pt: 'Contato atualizado.',
                  es: 'Contacto actualizado.',
                  en: 'Contact updated.',
                ),
        ),
      ),
    );
  }

  Future<void> _saveInPhoneContacts(_ContactFormResult result) async {
    final permissionGranted =
        await FlutterContacts.requestPermission(readonly: false);
    if (!permissionGranted) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              pt: 'Permissão de contatos negada no dispositivo.',
              es: 'Permiso de contactos denegado en el dispositivo.',
              en: 'Device contacts permission denied.',
            ),
          ),
        ),
      );
      return;
    }

    final nameParts = result.name.trim().split(RegExp(r'\s+'));
    final firstName = nameParts.isEmpty ? result.name : nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';

    final contact = Contact()
      ..name.first = firstName
      ..name.last = lastName
      ..phones = [Phone(result.whatsapp)];
    if ((result.email ?? '').trim().isNotEmpty) {
      contact.emails = [Email(result.email!.trim())];
    }

    try {
      await contact.insert();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              pt: 'Contato também salvo no celular.',
              es: 'Contacto también guardado en el teléfono.',
              en: 'Contact also saved to phone.',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              pt: 'Não foi possível salvar o contato no telefone.',
              es: 'No se pudo guardar el contacto en el teléfono.',
              en: 'Could not save the contact to phone.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _deleteContact(ClientSummary contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          tr(
            context,
            pt: 'Remover contato?',
            es: '¿Eliminar contacto?',
            en: 'Delete contact?',
          ),
        ),
        content: Text(
          '${tr(context, pt: 'Contato', es: 'Contacto', en: 'Contact')}: ${contact.name}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              tr(
                context,
                pt: 'Cancelar',
                es: 'Cancelar',
                en: 'Cancel',
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              tr(
                context,
                pt: 'Remover',
                es: 'Eliminar',
                en: 'Delete',
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await _clientRepository.deleteClient(contact.id);
    await _loadClients();
  }

  Future<void> _deleteAllContacts() async {
    if (_clients.isEmpty) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          tr(
            context,
            pt: 'Remover todos os contatos?',
            es: '¿Eliminar todos los contactos?',
            en: 'Delete all contacts?',
          ),
        ),
        content: Text(
          tr(
            context,
            pt: 'Essa ação não pode ser desfeita.',
            es: 'Esta acción no se puede deshacer.',
            en: 'This action cannot be undone.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              tr(
                context,
                pt: 'Cancelar',
                es: 'Cancelar',
                en: 'Cancel',
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              tr(
                context,
                pt: 'Remover tudo',
                es: 'Eliminar todo',
                en: 'Delete all',
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    await _clientRepository.deleteAllClients();
    await _loadClients();
  }

  Future<File?> _buildSpreadsheetFile() async {
    if (_clients.isEmpty) {
      return null;
    }

    final excel = Excel.createExcel();
    const sheetName = 'Contatos';
    excel.rename('Sheet1', sheetName);

    excel.appendRow(sheetName, [
      TextCellValue('id'),
      TextCellValue('nome'),
      TextCellValue('whatsapp'),
      TextCellValue('email'),
    ]);

    for (final client in _clients) {
      excel.appendRow(sheetName, [
        TextCellValue(client.id),
        TextCellValue(client.name),
        TextCellValue(client.whatsapp),
        TextCellValue(client.email ?? ''),
      ]);
    }

    final bytes = excel.save(fileName: 'clickpix_contatos.xlsx');
    if (bytes == null || bytes.isEmpty) {
      return null;
    }

    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}${Platform.pathSeparator}clickpix_contatos_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _shareContactsSpreadsheet({required bool preferEmail}) async {
    if (_clients.isEmpty) {
      return;
    }

    final file = await _buildSpreadsheetFile();
    if (file == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              pt: 'Não foi possível gerar a planilha de contatos.',
              es: 'No se pudo generar la planilla de contactos.',
              en: 'Could not generate the contacts spreadsheet.',
            ),
          ),
        ),
      );
      return;
    }

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'ClickPix - lista de contatos',
      text: preferEmail
          ? tr(
              context,
              pt: 'Selecione seu app de e-mail para enviar a planilha em anexo.',
              es: 'Selecciona tu app de correo para enviar la planilla adjunta.',
              en: 'Choose your email app to send the attached spreadsheet.',
            )
          : tr(
              context,
              pt: 'Planilha de contatos exportada pelo ClickPix.',
              es: 'Planilla de contactos exportada por ClickPix.',
              en: 'Contacts spreadsheet exported by ClickPix.',
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr(
            context,
            pt: 'Gerir contatos',
            es: 'Gestionar contactos',
            en: 'Manage contacts',
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadClients,
            icon: const Icon(Icons.refresh),
            tooltip: tr(
              context,
              pt: 'Atualizar',
              es: 'Actualizar',
              en: 'Refresh',
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _openContactEditor(),
                  icon: const Icon(Icons.person_add),
                  label: Text(
                    tr(
                      context,
                      pt: 'Adicionar',
                      es: 'Agregar',
                      en: 'Add',
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _clients.isEmpty
                      ? null
                      : () => _shareContactsSpreadsheet(preferEmail: true),
                  icon: const Icon(Icons.email),
                  label: Text(
                    tr(
                      context,
                      pt: 'Exportar por e-mail',
                      es: 'Exportar por correo',
                      en: 'Export by email',
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _clients.isEmpty
                      ? null
                      : () => _shareContactsSpreadsheet(preferEmail: false),
                  icon: const Icon(Icons.share),
                  label: Text(
                    tr(
                      context,
                      pt: 'Compartilhar planilha',
                      es: 'Compartir planilla',
                      en: 'Share spreadsheet',
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _clients.isEmpty
                      ? null
                      : () => _shareContactsSpreadsheet(preferEmail: false),
                  icon: const Icon(Icons.table_chart_outlined),
                  label: Text(
                    tr(
                      context,
                      pt: 'Exportar Excel',
                      es: 'Exportar Excel',
                      en: 'Export Excel',
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _clients.isEmpty ? null : _deleteAllContacts,
                  icon: const Icon(Icons.delete_sweep),
                  label: Text(
                    tr(
                      context,
                      pt: 'Remover todos',
                      es: 'Eliminar todos',
                      en: 'Delete all',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              tr(
                context,
                pt: 'Total de contatos: ${_clients.length}',
                es: 'Total de contactos: ${_clients.length}',
                en: 'Total contacts: ${_clients.length}',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _clients.isEmpty
                      ? Center(
                          child: Text(
                            tr(
                              context,
                              pt: 'Nenhum contato cadastrado.',
                              es: 'No hay contactos registrados.',
                              en: 'No contacts registered yet.',
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _clients.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final contact = _clients[index];
                            final subtitle = [
                              if (contact.whatsapp.isNotEmpty)
                                'WhatsApp: ${contact.whatsapp}',
                              if ((contact.email ?? '').isNotEmpty)
                                'E-mail: ${contact.email}',
                            ].join(' | ');
                            return ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                              title: Text(contact.name),
                              subtitle:
                                  subtitle.isEmpty ? null : Text(subtitle),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        _openContactEditor(contact),
                                    icon: const Icon(Icons.edit),
                                    tooltip: tr(
                                      context,
                                      pt: 'Editar',
                                      es: 'Editar',
                                      en: 'Edit',
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteContact(contact),
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: tr(
                                      context,
                                      pt: 'Remover',
                                      es: 'Eliminar',
                                      en: 'Delete',
                                    ),
                                  ),
                                ],
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

class _ContactEditorPage extends StatefulWidget {
  const _ContactEditorPage({
    this.existing,
  });

  final ClientSummary? existing;

  @override
  State<_ContactEditorPage> createState() => _ContactEditorPageState();
}

class _ContactEditorPageState extends State<_ContactEditorPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _emailController;
  bool _addToPhoneContacts = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _whatsappController = TextEditingController(
      text: widget.existing?.whatsapp ?? '',
    );
    _emailController =
        TextEditingController(text: widget.existing?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final whatsapp = _whatsappController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty || whatsapp.isEmpty) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    final result = _ContactFormResult(
      name: name,
      whatsapp: whatsapp,
      email: email.isEmpty ? null : email,
      addToPhoneContacts: _addToPhoneContacts,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? tr(
                  context,
                  pt: 'Novo contato',
                  es: 'Nuevo contacto',
                  en: 'New contact',
                )
              : tr(
                  context,
                  pt: 'Editar contato',
                  es: 'Editar contacto',
                  en: 'Edit contact',
                ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: tr(
                    context,
                    pt: 'Nome',
                    es: 'Nombre',
                    en: 'Name',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _whatsappController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'WhatsApp',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: tr(
                    context,
                    pt: 'E-mail (opcional)',
                    es: 'Correo (opcional)',
                    en: 'Email (optional)',
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              if (widget.existing == null)
                CheckboxListTile(
                  value: _addToPhoneContacts,
                  onChanged: (value) {
                    setState(() => _addToPhoneContacts = value ?? false);
                  },
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    tr(
                      context,
                      pt: 'Adicionar também aos contatos do celular',
                      es: 'Agregar también a los contactos del teléfono',
                      en: 'Also add to phone contacts',
                    ),
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(
                    widget.existing == null
                        ? tr(
                            context,
                            pt: 'Adicionar contato',
                            es: 'Agregar contacto',
                            en: 'Add contact',
                          )
                        : tr(
                            context,
                            pt: 'Salvar alterações',
                            es: 'Guardar cambios',
                            en: 'Save changes',
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactFormResult {
  const _ContactFormResult({
    required this.name,
    required this.whatsapp,
    this.email,
    this.addToPhoneContacts = false,
  });

  final String name;
  final String whatsapp;
  final String? email;
  final bool addToPhoneContacts;
}
