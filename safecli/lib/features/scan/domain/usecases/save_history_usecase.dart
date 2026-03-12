// lib/features/scan/domain/usecases/save_history_usecase.dart

import '../entities/scan_entity.dart';
import '../repositories/scan_repository.dart';

/// Persists the in-memory scan history through the repository.
/// This replaces the direct LocalStorageService call that was in ScanNotifier.
class SaveHistoryUseCase {
  final ScanRepository _repository;
  SaveHistoryUseCase(this._repository);

  Future<void> call(List<ScanEntity> history, String? userId) =>
      _repository.saveHistory(history, userId);
}
