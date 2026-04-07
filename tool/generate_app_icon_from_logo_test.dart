import 'dart:io';
import 'dart:ui' as ui;

import 'package:carsync_app/widgets/carsync_logo_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Exports launcher icon from in-app logo widget', (tester) async {
    const canvasSize = 1024.0;
    const logoSize = 760.0;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: RepaintBoundary(
              key: ValueKey('icon-export-boundary'),
              child: SizedBox(
                width: canvasSize,
                height: canvasSize,
                child: Center(
                  child: CarSyncLogoMark(size: logoSize),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final boundaryFinder = find.byKey(const ValueKey('icon-export-boundary'));
    final boundary =
        tester.renderObject(boundaryFinder) as RenderRepaintBoundary;

    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      fail('Failed to render icon bytes from logo widget.');
    }

    final bytes = byteData.buffer.asUint8List();
    final file = File('assets/branding/carsync_app_icon.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);

    expect(await file.exists(), isTrue);
  });
}