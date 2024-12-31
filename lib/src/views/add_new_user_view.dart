import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AddNewUserView extends StatefulWidget {
  const AddNewUserView({super.key});

  @override
  State<AddNewUserView> createState() => _AddNewUserViewState();
}

class _AddNewUserViewState extends State<AddNewUserView>
    with WidgetsBindingObserver {
  Barcode? _barcode;
  final MobileScannerController controller = MobileScannerController(
      // required options for the scanner
      );
  void _handleBarcode(BarcodeCapture barcodes) {
    if (mounted) {
      setState(() {
        _barcode = barcodes.barcodes.firstOrNull;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the controller is not ready, do not try to start or stop it.
    // Permission dialogs can trigger lifecycle changes before the controller is ready.
    if (!controller.value.hasCameraPermission) {
      return;
    }

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        // Restart the scanner when the app is resumed.
        // Don't forget to resume listening to the barcode events.
        _subscription = controller.barcodes.listen(_handleBarcode);

        unawaited(controller.start());
      case AppLifecycleState.inactive:
        // Stop the scanner when the app is paused.
        // Also stop the barcode events subscription.
        unawaited(_subscription?.cancel());
        _subscription = null;
        unawaited(controller.stop());
    }
  }

  @override
  void initState() {
    super.initState();
    // Start listening to lifecycle changes.
    WidgetsBinding.instance.addObserver(this);

    // Start listening to the barcode events.
    _subscription = controller.barcodes.listen(_handleBarcode);

    // Finally, start the scanner itself.
    unawaited(controller.start());
  }

  @override
  Future<void> dispose() async {
    // Stop listening to lifecycle changes.
    WidgetsBinding.instance.removeObserver(this);
    // Stop listening to the barcode events.
    unawaited(_subscription?.cancel());
    _subscription = null;
    // Dispose the widget itself.
    super.dispose();
    // Finally, dispose of the controller.
    await controller.dispose();
  }

  Widget _buildBarcode(Barcode? value) {
    if (value == null) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text:
                  "One of Connect's most important goals is data confidentiality. The Signal Protocol is therefore used to encrypt the data. The security of the Signal Protocol is based on the fact that the Signal identity is verified in a secure way (you stand next to the person and compare the public key). ",
              style: TextStyle(color: Colors.white),
            ),
            TextSpan(
              text:
                  "To enforce this, the only way to add a new user is to scan their QR code.",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold), // Bold style
            ),
          ],
        ),
        overflow: TextOverflow.fade,
        textAlign: TextAlign.center,
      );
    }

    return Text(
      value.displayValue ?? 'No display value.',
      overflow: TextOverflow.fade,
      style: const TextStyle(color: Colors.white),
    );
  }

  StreamSubscription<Object?>? _subscription;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add new user'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _handleBarcode,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.bottomCenter,
                height: 200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: Center(child: _buildBarcode(_barcode))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
