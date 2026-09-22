import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import 'monthly_collections_detail_screen.dart';
import 'loan_portfolio_detail_screen.dart';
import 'interest_profit_detail_screen.dart';
import 'overdue_detail_screen.dart';
import 'disbursement_detail_screen.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.message}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
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
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        title: const Text('Financial Reports'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.heroCardDecoration,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'REPORTS & ANALYTICS',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Interactive Financial Insights',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Tap any report to view month-wise breakdown, customer names, profits, or export to Excel.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.analytics_rounded, size: 36, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 1. Monthly Collections
          _buildInteractiveReportCard(
            icon: Icons.payments_rounded,
            iconColor: const Color(0xFF2E7D32),
            iconBg: const Color(0xFFE8F5E9),
            title: 'Monthly Collections',
            subtitle: 'Month-wise collection breakdown, payment methods (Cash/UPI) & receipts',
            tag: 'LIVE BREAKDOWN',
            tagColor: const Color(0xFF2E7D32),
            excelKey: 'collections',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MonthlyCollectionsDetailScreen()),
              );
            },
            onDownloadExcel: () => _download(
              ApiConstants.reportsCollections,
              'collections-report.xlsx',
              'collections',
            ),
          ),

          // 2. Loan Portfolio & Names
          _buildInteractiveReportCard(
            icon: Icons.account_balance_rounded,
            iconColor: const Color(0xFF1565C0),
            iconBg: const Color(0xFFE3F2FD),
            title: 'Loan Portfolio & Customer Names',
            subtitle: 'Full list of loans with customer names, active/overdue status, and collection totals',
            tag: 'ALL LOANS',
            tagColor: const Color(0xFF1565C0),
            excelKey: 'portfolio',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoanPortfolioDetailScreen()),
              );
            },
            onDownloadExcel: () => _download(
              ApiConstants.reportsLoanPortfolio,
              'loan-portfolio-report.xlsx',
              'portfolio',
            ),
          ),

          // 3. Interest Profit Breakdown
          _buildInteractiveReportCard(
            icon: Icons.trending_up_rounded,
            iconColor: const Color(0xFF6A1B9A),
            iconBg: const Color(0xFFF3E5F5),
            title: 'Finance Interest & Profit',
            subtitle: 'Net finance profit earned, month-by-month profit margins & loan yield analysis',
            tag: 'PROFIT & ROI',
            tagColor: const Color(0xFF6A1B9A),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InterestProfitDetailScreen()),
              );
            },
          ),

          // 4. Overdue & Defaulters
          _buildInteractiveReportCard(
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFC62828),
            iconBg: const Color(0xFFFFEBEE),
            title: 'Overdue & Defaulters List',
            subtitle: 'Customer names with missed dues, days overdue, contact phone & total pending amounts',
            tag: 'DEFAULTERS',
            tagColor: const Color(0xFFC62828),
            excelKey: 'overdue',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OverdueDetailScreen()),
              );
            },
            onDownloadExcel: () => _download(
              ApiConstants.reportsOverdue,
              'overdue-report.xlsx',
              'overdue',
            ),
          ),

          // 5. Loan Disbursements
          _buildInteractiveReportCard(
            icon: Icons.send_rounded,
            iconColor: const Color(0xFFE65100),
            iconBg: const Color(0xFFFFF3E0),
            title: 'Loan Disbursements Summary',
            subtitle: 'Month-wise loans issued, capital distributed and breakdown by Daily/Weekly/Monthly',
            tag: 'DISBURSEMENTS',
            tagColor: const Color(0xFFE65100),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DisbursementDetailScreen()),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInteractiveReportCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String tag,
    required Color tagColor,
    required VoidCallback onTap,
    String? excelKey,
    VoidCallback? onDownloadExcel,
  }) {
    final isThisDownloading = _isDownloading && _downloadingKey == excelKey;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _isDownloading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: iconColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: tagColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: tagColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (onDownloadExcel != null)
                              InkWell(
                                onTap: _isDownloading ? null : onDownloadExcel,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: isThisDownloading
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(Icons.file_download_outlined, size: 14, color: AppTheme.textMuted),
                                            SizedBox(width: 4),
                                            Text(
                                              'Excel',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View Detailed Breakdown',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 14, color: AppTheme.primaryColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
