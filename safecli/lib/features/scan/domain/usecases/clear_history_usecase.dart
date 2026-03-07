// lib/features/scan/domain/usecases/clear_history_usecase.dart

import '../repositories/scan_repository.dart';

class ClearHistoryUseCase {
  final ScanRepository _repository;
  ClearHistoryUseCase(this._repository);

  Future<bool> call() => _repository.clearHistory();
}
