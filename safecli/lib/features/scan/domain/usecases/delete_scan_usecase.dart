// lib/features/scan/domain/usecases/delete_scan_usecase.dart

import '../repositories/scan_repository.dart';

class DeleteScanUseCase {
  final ScanRepository _repository;
  DeleteScanUseCase(this._repository);

  Future<bool> call(String id) => _repository.deleteScan(id);
}
