import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isDownloading = false;
  String? _downloadingKey;

  Future<void> _download(String path, String filename, String key) async {
    setState(() {
      _isDownloading = true;
      _downloadingKey = key;
    });
    try {
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/$filename';
      await ApiClient.instance.client.download(path, savePath);
      await OpenFilex.open(savePath);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Download failed: ${e.message}'), backgroundColor: AppTheme.errorColor));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadingKey = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _reportTile(
            icon: Icons.receipt_long_outlined,
            title: 'Collections Report',
            subtitle: 'All successful payments received',
            key: 'collections',
            onTap: () => _download(ApiConstants.reportsCollections, 'collections-report.xlsx', 'collections'),
          ),
          _reportTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Loan Portfolio Report',
            subtitle: 'All loans with status and collection summary',
            key: 'portfolio',
            onTap: () => _download(ApiConstants.reportsLoanPortfolio, 'loan-portfolio-report.xlsx', 'portfolio'),
          ),
          _reportTile(
            icon: Icons.warning_amber_outlined,
            title: 'Overdue Report',
            subtitle: 'All missed/pending dues past their due date',
            key: 'overdue',
            onTap: () => _download(ApiConstants.reportsOverdue, 'overdue-report.xlsx', 'overdue'),
          ),
        ],
      ),
    );
  }

  Widget _reportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String key,
    required VoidCallback onTap,
  }) {
    final isThisDownloading = _isDownloading && _downloadingKey == key;
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: isThisDownloading
            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.download_outlined),
        onTap: _isDownloading ? null : onTap,
      ),
    );
  }
}
