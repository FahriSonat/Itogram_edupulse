import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Yerel veritabanını (ilk açılışta demo verisiyle) ve bağımlılıkları hazırla.
  await initDependencies();
  runApp(const EduPulseApp());
}
