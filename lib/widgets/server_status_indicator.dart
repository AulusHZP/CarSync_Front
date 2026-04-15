import 'package:flutter/material.dart';
import '../services/api_config.dart';
import '../services/debug_service.dart';
import '../core/app_colors.dart';

/// Widget para exibir e diagnosticar status de conexão com o servidor
class ServerStatusIndicator extends StatefulWidget {
  final Size size;
  final bool showDetails;

  const ServerStatusIndicator({
    super.key,
    this.size = const Size(24, 24),
    this.showDetails = false,
  });

  @override
  State<ServerStatusIndicator> createState() => _ServerStatusIndicatorState();
}

class _ServerStatusIndicatorState extends State<ServerStatusIndicator> {
  late Future<ConnectionStatus> _connectionFuture;

  @override
  void initState() {
    super.initState();
    _connectionFuture = DebugService.testApiConnection();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ConnectionStatus>(
      future: _connectionFuture,
      builder: (context, snapshot) {
        final status = snapshot.data ?? ConnectionStatus.unknown;
        final color = _getColorForStatus(status);
        final tooltip = _getTooltipForStatus(status);

        return Tooltip(
          message: tooltip,
          child: GestureDetector(
            onLongPress: _showDiagnosticDialog,
            child: Container(
              width: widget.size.width,
              height: widget.size.height,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
                border: Border.all(color: color, width: 2),
              ),
              child: Center(
                child: Icon(
                  _getIconForStatus(status),
                  color: color,
                  size: widget.size.width * 0.6,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getColorForStatus(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.timeout:
      case ConnectionStatus.connectionError:
        return Colors.red;
      case ConnectionStatus.invalidResponse:
        return Colors.orange;
      case ConnectionStatus.unknown:
        return Colors.grey;
    }
  }

  IconData _getIconForStatus(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Icons.cloud_done;
      case ConnectionStatus.timeout:
      case ConnectionStatus.connectionError:
        return Icons.cloud_off;
      case ConnectionStatus.invalidResponse:
        return Icons.cloud_queue;
      case ConnectionStatus.unknown:
        return Icons.cloud_outline;
    }
  }

  String _getTooltipForStatus(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return 'Conectado ao servidor';
      case ConnectionStatus.timeout:
        return 'Timeout: Servidor demorando para responder';
      case ConnectionStatus.connectionError:
        return 'Erro de conexão com servidor';
      case ConnectionStatus.invalidResponse:
        return 'Resposta inválida do servidor';
      case ConnectionStatus.unknown:
        return 'Status desconhecido';
    }
  }

  Future<void> _showDiagnosticDialog() async {
    final report = await DebugService.getConnectionReport();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Diagnóstico de Conexão'),
        content: SingleChildScrollView(
          child: SelectableText(report),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _refresh();
            },
            child: const Text('Recarregar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _refresh() {
    setState(() {
      _connectionFuture = DebugService.testApiConnection();
    });
  }
}

/// Widget para exibir um banner com aviso de conexão
class ServerConnectionWarning extends StatelessWidget {
  const ServerConnectionWarning({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ConnectionStatus>(
      future: DebugService.testApiConnection(),
      builder: (context, snapshot) {
        final status = snapshot.data;

        // Mostrar aviso apenas se houver problema
        if (status == null ||
            status == ConnectionStatus.connected ||
            status == ConnectionStatus.unknown) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.orange[100],
          child: Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.orange[800],
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getWarningMessage(status),
                  style: TextStyle(
                    color: Colors.orange[900],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getWarningMessage(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.timeout:
        return 'Servidor demorando para responder. Verifique sua conexão.';
      case ConnectionStatus.connectionError:
        return 'Erro ao conectar com servidor. Verifique sua internet.';
      case ConnectionStatus.invalidResponse:
        return 'Resposta inválida do servidor.';
      default:
        return 'Problema de conexão com servidor.';
    }
  }
}
