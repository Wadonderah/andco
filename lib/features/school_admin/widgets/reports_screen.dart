import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'This Month';
  ReportType _selectedReportType = ReportType.attendance;

  final List<String> _periods = [
    'Today',
    'This Week',
    'This Month',
    'This Quarter',
    'This Year',
    'Custom Range'
  ];

  final List<ReportTemplate> _reportTemplates = [
    ReportTemplate(
      id: '1',
      name: 'Daily Attendance Report',
      description: 'Student attendance summary for selected date',
      type: ReportType.attendance,
      icon: Icons.how_to_reg,
      color: AppColors.success,
      frequency: 'Daily',
      lastGenerated: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ReportTemplate(
      id: '2',
      name: 'Bus Utilization Report',
      description: 'Bus capacity and route efficiency analysis',
      type: ReportType.transportation,
      icon: Icons.directions_bus,
      color: AppColors.info,
      frequency: 'Weekly',
      lastGenerated: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ReportTemplate(
      id: '3',
      name: 'Incident Summary Report',
      description: 'Safety incidents and emergency responses',
      type: ReportType.incidents,
      icon: Icons.warning,
      color: AppColors.error,
      frequency: 'Weekly',
      lastGenerated: DateTime.now().subtract(const Duration(days: 3)),
    ),
    ReportTemplate(
      id: '4',
      name: 'Parent Feedback Report',
      description: 'Feedback and complaints analysis',
      type: ReportType.feedback,
      icon: Icons.feedback,
      color: AppColors.secondary,
      frequency: 'Monthly',
      lastGenerated: DateTime.now().subtract(const Duration(days: 7)),
    ),
    ReportTemplate(
      id: '5',
      name: 'Driver Performance Report',
      description: 'Driver ratings and performance metrics',
      type: ReportType.performance,
      icon: Icons.person,
      color: AppColors.warning,
      frequency: 'Monthly',
      lastGenerated: DateTime.now().subtract(const Duration(days: 10)),
    ),
    ReportTemplate(
      id: '6',
      name: 'Financial Summary Report',
      description: 'Transportation costs and budget analysis',
      type: ReportType.financial,
      icon: Icons.attach_money,
      color: AppColors.primary,
      frequency: 'Monthly',
      lastGenerated: DateTime.now().subtract(const Duration(days: 15)),
    ),
  ];

  final List<GeneratedReport> _recentReports = [
    GeneratedReport(
      id: '1',
      name: 'Daily Attendance - March 15, 2024',
      type: ReportType.attendance,
      generatedDate: DateTime.now().subtract(const Duration(hours: 2)),
      fileSize: '2.3 MB',
      format: 'PDF',
      status: ReportStatus.completed,
    ),
    GeneratedReport(
      id: '2',
      name: 'Bus Utilization - Week 11, 2024',
      type: ReportType.transportation,
      generatedDate: DateTime.now().subtract(const Duration(days: 1)),
      fileSize: '1.8 MB',
      format: 'Excel',
      status: ReportStatus.completed,
    ),
    GeneratedReport(
      id: '3',
      name: 'Incident Summary - March 2024',
      type: ReportType.incidents,
      generatedDate: DateTime.now().subtract(const Duration(days: 3)),
      fileSize: '856 KB',
      format: 'PDF',
      status: ReportStatus.processing,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: AppColors.schoolAdminColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Templates'),
            Tab(text: 'Generated'),
            Tab(text: 'Analytics'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _createCustomReport,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            onPressed: _scheduleReports,
            icon: const Icon(Icons.schedule),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTemplatesTab(),
          _buildGeneratedTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildTemplatesTab() {
    return Column(
      children: [
        // Filter Section
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          color: AppColors.surfaceVariant,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPeriod,
                      decoration: const InputDecoration(
                        labelText: 'Time Period',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _periods
                          .map((period) => DropdownMenuItem(
                                value: period,
                                child: Text(period),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedPeriod = value!),
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: DropdownButtonFormField<ReportType>(
                      value: _selectedReportType,
                      decoration: const InputDecoration(
                        labelText: 'Report Type',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: ReportType.values
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type.name.toUpperCase()),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedReportType = value!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              // Quick Stats
              Row(
                children: [
                  Expanded(
                      child: _buildStatCard('Total Templates',
                          _reportTemplates.length.toString(), AppColors.info)),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                      child: _buildStatCard(
                          'Generated Today', '12', AppColors.success)),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                      child:
                          _buildStatCard('Scheduled', '8', AppColors.warning)),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                      child: _buildStatCard(
                          'Processing', '3', AppColors.secondary)),
                ],
              ),
            ],
          ),
        ),

        // Templates List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium),
            itemCount: _reportTemplates.length,
            itemBuilder: (context, index) {
              final template = _reportTemplates[index];
              return _buildTemplateCard(template);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratedTab() {
    return Column(
      children: [
        // Summary Section
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          color: AppColors.surfaceVariant,
          child: Row(
            children: [
              Expanded(
                  child: _buildStatCard('Total Reports',
                      _recentReports.length.toString(), AppColors.info)),
              const SizedBox(width: AppConstants.paddingSmall),
              Expanded(
                  child: _buildStatCard('This Month', '45', AppColors.success)),
              const SizedBox(width: AppConstants.paddingSmall),
              Expanded(
                  child: _buildStatCard(
                      'Storage Used', '127 MB', AppColors.warning)),
              const SizedBox(width: AppConstants.paddingSmall),
              Expanded(
                  child:
                      _buildStatCard('Downloads', '234', AppColors.secondary)),
            ],
          ),
        ),

        // Reports List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium),
            itemCount: _recentReports.length,
            itemBuilder: (context, index) {
              final report = _recentReports[index];
              return _buildGeneratedReportCard(report);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Advanced Analytics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Interactive charts and data visualization',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(ReportTemplate template) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: template.color.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Icon(
                    template.icon,
                    color: template.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        template.description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.schedule,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Frequency: ${template.frequency}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.access_time,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Last: ${_formatDateTime(template.lastGenerated)}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleTemplateAction(value, template),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'generate', child: Text('Generate Now')),
                    const PopupMenuItem(
                        value: 'schedule', child: Text('Schedule')),
                    const PopupMenuItem(
                        value: 'customize', child: Text('Customize')),
                    const PopupMenuItem(
                        value: 'preview', child: Text('Preview')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _previewReport(template),
                    icon: const Icon(Icons.preview),
                    label: const Text('Preview'),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _generateReport(template),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Generate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: template.color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratedReportCard(GeneratedReport report) {
    final statusColor = _getReportStatusColor(report.status);

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              ),
              child: Icon(
                _getReportTypeIcon(report.type),
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(report.generatedDate),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.file_present,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${report.format} • ${report.fileSize}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusSmall),
                    ),
                    child: Text(
                      report.status.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (report.status == ReportStatus.completed) ...[
              IconButton(
                onPressed: () => _downloadReport(report),
                icon: const Icon(Icons.download),
                tooltip: 'Download',
              ),
              IconButton(
                onPressed: () => _shareReport(report),
                icon: const Icon(Icons.share),
                tooltip: 'Share',
              ),
            ] else if (report.status == ReportStatus.processing) ...[
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper Methods
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Color _getReportStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.completed:
        return AppColors.success;
      case ReportStatus.processing:
        return AppColors.warning;
      case ReportStatus.failed:
        return AppColors.error;
      case ReportStatus.scheduled:
        return AppColors.info;
    }
  }

  IconData _getReportTypeIcon(ReportType type) {
    switch (type) {
      case ReportType.attendance:
        return Icons.how_to_reg;
      case ReportType.transportation:
        return Icons.directions_bus;
      case ReportType.incidents:
        return Icons.warning;
      case ReportType.feedback:
        return Icons.feedback;
      case ReportType.performance:
        return Icons.person;
      case ReportType.financial:
        return Icons.attach_money;
    }
  }

  void _handleTemplateAction(String action, ReportTemplate template) {
    switch (action) {
      case 'generate':
        _generateReport(template);
        break;
      case 'schedule':
        _scheduleReport(template);
        break;
      case 'customize':
        _customizeTemplate(template);
        break;
      case 'preview':
        _previewReport(template);
        break;
    }
  }

  void _generateReport(ReportTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Generate ${template.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Generate report for: $_selectedPeriod'),
            const SizedBox(height: 16),
            const Text('Select format:'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _startReportGeneration(template, 'PDF');
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('PDF'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _startReportGeneration(template, 'Excel');
                    },
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Excel'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _startReportGeneration(ReportTemplate template, String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating ${template.name} in $format format...'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _previewReport(ReportTemplate template) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Preview ${template.name}')),
    );
  }

  void _scheduleReport(ReportTemplate template) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Schedule ${template.name}')),
    );
  }

  void _customizeTemplate(ReportTemplate template) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Customize ${template.name}')),
    );
  }

  void _downloadReport(GeneratedReport report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${report.name}...'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _shareReport(GeneratedReport report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share ${report.name}')),
    );
  }

  void _createCustomReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text('Create custom report functionality will be implemented')),
    );
  }

  void _scheduleReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Schedule reports functionality will be implemented')),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

enum ReportType {
  attendance,
  transportation,
  incidents,
  feedback,
  performance,
  financial
}

enum ReportStatus { completed, processing, failed, scheduled }

class ReportTemplate {
  final String id;
  final String name;
  final String description;
  final ReportType type;
  final IconData icon;
  final Color color;
  final String frequency;
  final DateTime lastGenerated;

  ReportTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.icon,
    required this.color,
    required this.frequency,
    required this.lastGenerated,
  });
}

class GeneratedReport {
  final String id;
  final String name;
  final ReportType type;
  final DateTime generatedDate;
  final String fileSize;
  final String format;
  final ReportStatus status;

  GeneratedReport({
    required this.id,
    required this.name,
    required this.type,
    required this.generatedDate,
    required this.fileSize,
    required this.format,
    required this.status,
  });
}
