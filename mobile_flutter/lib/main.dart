import 'package:flutter/material.dart';

void main() {
  runApp(const ClickPixApp());
}

class ClickPixApp extends StatelessWidget {
  const ClickPixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClickPix Ramon',
      home: const QuickFlowPage(),
    );
  }
}

class QuickFlowPage extends StatefulWidget {
  const QuickFlowPage({super.key});

  @override
  State<QuickFlowPage> createState() => _QuickFlowPageState();
}

class _QuickFlowPageState extends State<QuickFlowPage> {
  int step = 0;
  static const labels = ['Galeria', 'Pedido', 'Pagamento', 'Entrega'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Atendimento Rápido')),
      body: Center(child: Text('Etapa atual: ${labels[step]}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => step = (step + 1) % labels.length),
        label: const Text('Continuar'),
      ),
    );
  }
}
