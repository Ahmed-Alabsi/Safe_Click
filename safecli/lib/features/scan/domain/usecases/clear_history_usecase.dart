// lib/features/scan/domain/usecases/clear_history_usecase.dart

import '../repositories/scan_repository.dart';

class ClearHistoryUseCase {
  final ScanRepository _repository;
  ClearHistoryUseCase(this._repository);

  /// Soft delete all scans for current user
  Future<bool> call(String? userId) => _repository.clearUserHistory(userId);
}