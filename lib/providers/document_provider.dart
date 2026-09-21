import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/document_model.dart';
import '../services/document_service.dart';

final documentServiceProvider = Provider((ref) => DocumentService());

final customerDocumentsProvider =
    FutureProvider.autoDispose.family<List<CustomerDocument>, String>((ref, customerId) async {
  final service = ref.watch(documentServiceProvider);
  return service.listByCustomer(customerId);
});
