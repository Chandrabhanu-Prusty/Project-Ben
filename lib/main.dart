import 'package:flutter/material.dart';
import 'app.dart';
import 'data/local/app_database.dart';
import 'data/repositories/auth_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase Auth if credentials provided
  await AuthRepository.initialize();

  // Run initial physical cleanup of 36-hour expired records
  try {
    await AppDatabase.instance.cleanupExpiredRecords();
  } catch (_) {}

  runApp(const BenApp());
}
