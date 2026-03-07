// lib/features/scan/domain/usecases/get_scan_history_usecase.dart

import '../entities/scan_entity.dart';
import '../repositories/scan_repository.dart';

class GetScanHistoryUseCase {
  final ScanRepository _repository;
  GetScanHistoryUseCase(this._repository);

  Future<List<ScanEntity>> call() => _repository.getScanHistory();
}
