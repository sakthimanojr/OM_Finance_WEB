import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../services/report_json_service.dart';
import 'customer_detail_screen.dart';

class OverdueDetailScreen extends StatefulWidget {
  const OverdueDetailScreen({super.key});

  @override
  State<OverdueDetailScreen> createState() => _OverdueDetailScreenState();
}

class _OverdueDetailScreenState extends State<OverdueDetailScreen> {
  final ReportJsonService _service = ReportJsonService();
  bool _isLoading = true;
  String? _error;
  num _grandTotal = 0;
  int _totalCustomers = 0;
  List<dynamic> _customers = [];
  String _searchQuery = '';
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _service.overdueDetail();
      setState(() {
        _grandTotal = res['grandTotal'] ?? 0;
        _totalCustomers = res['totalCustomers'] ?? 0;
        _customers = (res['customers'] as List<dynamic>?) ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadExcel() async {
    setState(() => _isDownloading = true);
    try {
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/overdue-report.xlsx';
      await ApiClient.instance.client.download(ApiConstants.reportsOverdue, savePath);
      await OpenFilex.open(savePath);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: ${e.message}'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        title: const Text('Overdue & Defaulters'),
        actions: [
          IconButton(
            tooltip: 'Export Excel',
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.file_download_outlined),
            onPressed: _isDownloading ? null : _downloadExcel,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
              const SizedBox(height: 12),
              Text('Failed to load overdue report', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _customers.where((c) {
      if (_searchQuery.isEmpty) return true;
      final name = (c['customerName'] ?? '').toString().toLowerCase();
      final phone = (c['customerPhone'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || phone.contains(_searchQuery);
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFB71C1C), Color(0xFFD32F2F), Color(0xFFE53935)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL OVERDUE AMOUNT',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$_totalCustomers Customer${_totalCustomers == 1 ? '' : 's'}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          Formatters.currency(_grandTotal),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Unpaid dues past their scheduled payment date',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search customer name or phone...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.errorColor),
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  ),
                ],
              ),
            ),
          ),
          if (filtered.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 48, color: AppTheme.successColor),
                    SizedBox(height: 12),
                    Text('No overdue accounts! Great job.', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildCustomerCard(filtered[index]),
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(dynamic c) {
    final customerId = c['customerId'] ?? '';
    final name = c['customerName'] ?? 'Unknown';
    final phone = c['customerPhone'] ?? '';
    final totalOverdue = (c['totalOverdueAmount'] as num?) ?? 0;
    final missedCount = c['missedDuesCount'] ?? 0;
    final maxDays = c['maxDaysOverdue'] ?? 0;
    final dues = (c['dues'] as List<dynamic>?) ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: AppTheme.errorColor.withValues(alpha: 0.12),
            child: const Icon(Icons.warning_rounded, color: AppTheme.errorColor),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 2,
                  softWrap: true,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$maxDays Days Late',
                  style: const TextStyle(color: AppTheme.errorColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                if (phone.isNotEmpty) ...[
                  Text(phone, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _callPhone(phone),
                    child: const Icon(Icons.phone, size: 14, color: AppTheme.primaryColor),
                  ),
                ],
                const Spacer(),
                Text(
                  Formatters.currency(totalOverdue),
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.errorColor, fontSize: 14),
                ),
              ],
            ),
          ),
          children: [
            const Divider(height: 1),
            Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$missedCount Missed Due${missedCount == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  if (customerId.isNotEmpty)
                    TextButton(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CustomerDetailScreen(customerId: customerId)),
                        );
                      },
                      child: const Text('View Profile →', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),
            ...dues.map((due) => _buildDueRow(due)),
          ],
        ),
      ),
    );
  }

  Widget _buildDueRow(dynamic due) {
    final loanNumber = due['loanNumber'] ?? '-';
    final loanType = due['loanType'] ?? '-';
    final dueNumber = due['dueNumber'] ?? '-';
    final amount = (due['amount'] as num?) ?? 0;
    final daysOverdue = due['daysOverdue'] ?? 0;
    final dueDateStr = due['dueDate'];
    final parsedDate = Formatters.tryParse(dueDateStr);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Loan #$loanNumber ($loanType) • Due #$dueNumber',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                'Due Date: ${parsedDate != null ? Formatters.date(parsedDate) : '-'} • $daysOverdue days overdue',
                style: TextStyle(fontSize: 11, color: Colors.red.shade700),
              ),
            ],
          ),
          Text(
            Formatters.currency(amount),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.errorColor),
          ),
        ],
      ),
    );
  }
}
