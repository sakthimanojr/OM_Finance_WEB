import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/document_model.dart';
import '../../providers/document_provider.dart';

/// Shows a customer's uploaded KYC documents (Aadhaar, PAN, Agreement, Other)
/// with buttons to upload a new one of each type and delete existing ones.
/// Intended for the admin's customer detail screen.
class DocumentsSection extends ConsumerStatefulWidget {
  const DocumentsSection({super.key, required this.customerId});
  final String customerId;

  @override
  ConsumerState<DocumentsSection> createState() => _DocumentsSectionState();
}

class _DocumentsSectionState extends ConsumerState<DocumentsSection> {
  bool _isUploading = false;
  String? _uploadingType;

  static const _types = ['AADHAAR', 'PAN', 'AGREEMENT', 'OTHER'];

  Future<void> _pickAndUpload(String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
    );
    if (result == null || result.files.single.path == null) return;

    setState(() {
      _isUploading = true;
      _uploadingType = type;
    });
    try {
      await ref.read(documentServiceProvider).uploadDocument(
            customerId: widget.customerId,
            type: type,
            filePath: result.files.single.path!,
          );
      ref.invalidate(customerDocumentsProvider(widget.customerId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _delete(CustomerDocument doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text('This will permanently remove the ${doc.displayName} on file.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(documentServiceProvider).deleteDocument(doc.id);
      ref.invalidate(customerDocumentsProvider(widget.customerId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor));
      }
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'AADHAAR':
        return Icons.badge_outlined;
      case 'PAN':
        return Icons.credit_card_outlined;
      case 'AGREEMENT':
        return Icons.description_outlined;
      default:
        return Icons.attach_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(customerDocumentsProvider(widget.customerId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('KYC Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (_isUploading)
                  const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 12),
            docsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Text('Failed to load documents: $err', style: const TextStyle(color: AppTheme.errorColor)),
              data: (docs) {
                if (docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('No documents uploaded yet.', style: TextStyle(color: Colors.grey.shade600)),
                  );
                }
                return Column(
                  children: docs
                      .map(
                        (doc) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(_iconFor(doc.type), color: AppTheme.primaryColor),
                          title: Text(doc.displayName),
                          subtitle: Text('Uploaded ${Formatters.date(doc.uploadedAt)}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                            onPressed: () => _delete(doc),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Upload new document', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((type) {
                final isThisUploading = _isUploading && _uploadingType == type;
                return ActionChip(
                  avatar: isThisUploading
                      ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(_iconFor(type), size: 16, color: AppTheme.primaryColor),
                  label: Text(type == 'OTHER' ? 'Other' : type[0] + type.substring(1).toLowerCase()),
                  onPressed: _isUploading ? null : () => _pickAndUpload(type),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
