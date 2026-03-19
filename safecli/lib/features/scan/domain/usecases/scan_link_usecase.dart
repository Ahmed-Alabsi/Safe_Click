// lib/features/scan/domain/usecases/scan_link_usecase.dart

import '../entities/scan_entity.dart';
import '../repositories/scan_repository.dart';

class ScanLinkUseCase {
  final ScanRepository _repository;
  ScanLinkUseCase(this._repository);

  Future<ScanEntity?> call(String link, {String scanLevel = 'deep'}) => _repository.scanLink(link, scanLevel: scanLevel);
}
