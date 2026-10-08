import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Web implementation that initializes databaseFactory with databaseFactoryFfiWeb
void initWebDatabase() {
  databaseFactory = databaseFactoryFfiWeb;
}
