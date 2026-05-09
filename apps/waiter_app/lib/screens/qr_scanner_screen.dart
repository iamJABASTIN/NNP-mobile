import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/app_theme.dart';
import '../models/table_info.dart';
import '../services/menu_service.dart';
import '../widgets/brutal_button.dart';
import '../widgets/brutal_text_field.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _cameraController = MobileScannerController();
  bool _isProcessing = false;
  List<TableInfo> _tables = [];

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    try {
      _tables = await MenuService.fetchTables();
    } catch (e) {
      // Handle error gracefully, or let the bottom sheet handle if table not found
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        _processScannedCode(code);
      }
    }
  }

  Future<void> _processScannedCode(String code) async {
    // Expected format: https://nnp-one.vercel.app/table/{uuid}
    final uri = Uri.tryParse(code);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      if (uri.pathSegments.first == 'table' && uri.pathSegments.length > 1) {
        final tableId = uri.pathSegments[1];
        setState(() => _isProcessing = true);
        _cameraController.stop();

        final table = _tables.cast<TableInfo?>().firstWhere(
              (t) => t?.id == tableId,
              orElse: () => null,
            );

        if (table != null) {
          _showCustomerDetailsSheet(table);
        } else {
          // Table not found in our list
          _showErrorAndResume('Invalid table QR code');
        }
        return;
      }
    }
    
    // If we reach here, it's not a valid table QR
    setState(() => _isProcessing = true);
    _cameraController.stop();
    _showErrorAndResume('Unrecognized QR Code');
  }

  void _showErrorAndResume(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isProcessing = false);
        _cameraController.start();
      }
    });
  }

  void _showCustomerDetailsSheet(TableInfo table) {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _CustomerDetailsSheet(table: table),
    ).then((result) {
      if (result != null) {
        navigator.pop(result);
      } else {
        // User cancelled, resume scanning
        setState(() => _isProcessing = false);
        _cameraController.start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SCAN TABLE QR'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: _onDetect,
          ),
          
          // Brutalist Viewfinder Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryYellow, width: 4),
              ),
              child: Stack(
                children: [
                  Positioned(top: 0, left: 0, child: _CornerMarker()),
                  Positioned(top: 0, right: 0, child: RotatedBox(quarterTurns: 1, child: _CornerMarker())),
                  Positioned(bottom: 0, right: 0, child: RotatedBox(quarterTurns: 2, child: _CornerMarker())),
                  Positioned(bottom: 0, left: 0, child: RotatedBox(quarterTurns: 3, child: _CornerMarker())),
                ],
              ),
            ),
          ),
          
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'ALIGN QR CODE WITHIN FRAME',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                backgroundColor: AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.black, width: 4),
          left: BorderSide(color: AppColors.black, width: 4),
        ),
      ),
    );
  }
}

class _CustomerDetailsSheet extends StatefulWidget {
  final TableInfo table;
  const _CustomerDetailsSheet({required this.table});

  @override
  State<_CustomerDetailsSheet> createState() => _CustomerDetailsSheetState();
}

class _CustomerDetailsSheetState extends State<_CustomerDetailsSheet> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty) return;
    
    Navigator.pop(context, {
      'tableId': widget.table.id,
      'tableName': widget.table.tableNumber,
      'customerName': _nameCtrl.text.trim(),
      'customerPhone': _phoneCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.black, width: 3)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TABLE ${widget.table.tableNumber}', style: BrutalText.heading),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context, null),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('CUSTOMER DETAILS', style: BrutalText.label),
            const SizedBox(height: 8),
            BrutalTextField(
              hintText: 'Customer Name (Mandatory)',
              controller: _nameCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            BrutalTextField(
              hintText: 'Phone Number (Optional)',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            BrutalButton(
              label: 'START ORDER',
              icon: Icons.bolt,
              backgroundColor: AppColors.primaryYellow,
              textColor: AppColors.black,
              onPressed: _nameCtrl.text.trim().isNotEmpty ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}
