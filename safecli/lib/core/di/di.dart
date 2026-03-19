import 'package:get_it/get_it.dart';
import 'package:safeclik/core/network/api_client.dart';
import 'package:safeclik/core/network/auth_api.dart';
import 'package:safeclik/core/network/scan_api.dart';
import 'package:safeclik/core/network/report_api.dart';
import 'package:safeclik/core/network/settings_api.dart';
import 'package:safeclik/core/network/feedback_api.dart';
import 'package:safeclik/core/utils/local_storage_service.dart';
import 'package:safeclik/core/utils/notification_service.dart';
import 'package:safeclik/core/utils/scan_cache_service.dart';

import 'package:safeclik/features/scan/data/datasources/remote_scan_datasource.dart';
import 'package:safeclik/features/scan/data/repositories/scan_repository_impl.dart';
import 'package:safeclik/features/scan/domain/repositories/scan_repository.dart';
import 'package:safeclik/features/scan/domain/usecases/clear_history_usecase.dart';
import 'package:safeclik/features/scan/domain/usecases/delete_scan_usecase.dart';
import 'package:safeclik/features/scan/domain/usecases/get_scan_history_usecase.dart';
import 'package:safeclik/features/scan/domain/usecases/save_history_usecase.dart';
import 'package:safeclik/features/scan/domain/usecases/scan_link_usecase.dart';

final sl = GetIt.instance;

Future<void> initDI() async {
  // ── Core Services ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<ApiClient>(() => ApiClient());
  sl.registerLazySingleton<AuthApi>(() => AuthApi(sl()));
  sl.registerLazySingleton<ScanApi>(() => ScanApi(sl()));
  sl.registerLazySingleton<ReportApi>(() => ReportApi(sl()));
  sl.registerLazySingleton<SettingsApi>(() => SettingsApi(sl()));
  sl.registerLazySingleton<LocalStorageService>(() => LocalStorageService());
  sl.registerLazySingleton<NotificationService>(() => NotificationService());

  // ── Local SQLite Cache (Phase 2) ─────────────────────────────────────────
  // ScanCacheService provides O(1) SHA-256-keyed URL result lookups.
  sl.registerLazySingleton<ScanCacheService>(() => ScanCacheService());

  // ── Scan Feature — Data Sources ───────────────────────────────────────────
  // NOTE: VirusTotalService and ScanService have been removed.
  // Flutter NEVER calls external threat APIs directly (Phase 1 security fix).
  sl.registerLazySingleton<RemoteScanDataSource>(
      () => RemoteScanDataSource(sl()));

  // ── Scan Feature — Repository ─────────────────────────────────────────────
  // Register the concrete class AND the abstract interface pointing to same instance.
  // This allows both sl<ScanRepository>() and sl<ScanRepositoryImpl>() to work.
  final scanRepo = ScanRepositoryImpl(
    remote: sl(),
    cache: sl(),
  );
  sl.registerLazySingleton<ScanRepository>(() => scanRepo);
  sl.registerLazySingleton<ScanRepositoryImpl>(() => scanRepo);

  // ── Scan Feature — Use Cases ─────────────────────────────────────────────
  sl.registerLazySingleton<ScanLinkUseCase>(() => ScanLinkUseCase(sl()));
  sl.registerLazySingleton<GetScanHistoryUseCase>(
      () => GetScanHistoryUseCase(sl()));
  sl.registerLazySingleton<DeleteScanUseCase>(() => DeleteScanUseCase(sl()));
  sl.registerLazySingleton<ClearHistoryUseCase>(
      () => ClearHistoryUseCase(sl()));
  sl.registerLazySingleton<SaveHistoryUseCase>(() => SaveHistoryUseCase(sl()));

  // ── Feedback Feature ──────────────────────────────────────────────────────
  sl.registerLazySingleton<FeedbackApi>(() => FeedbackApi(sl()));
}
