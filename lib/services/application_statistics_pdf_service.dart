import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/job_application.dart';
import '../constants/app_constants.dart';

/// Service for generating application statistics PDF reports
/// Styled to match the professional CV and cover letter templates
class ApplicationStatisticsPdfService {
  /// Generate a comprehensive statistics PDF overview
  static Future<Uint8List> generateStatisticsPdf({
    required List<JobApplication> applications,
    required PdfColor accentColor,
  }) async {
    final pdf = pw.Document();

    // Calculate statistics
    final stats = _calculateStatistics(applications);

    // Group applications by status
    final byStatus = _groupByStatus(applications);

    // Sort applications by date for timeline
    final timeline = applications
        .where((app) => app.applicationDate != null)
        .toList()
      ..sort((a, b) => b.applicationDate!.compareTo(a.applicationDate!));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Professional Header
          _buildProfessionalHeader(accentColor),
          pw.SizedBox(height: 32),

          // Summary Statistics Cards
          _buildStatisticsOverview(stats, accentColor),
          pw.SizedBox(height: 28),

          // Key Metrics
          _buildKeyMetrics(stats, accentColor),
          pw.SizedBox(height: 28),

          // Recent Activity Timeline
          if (timeline.isNotEmpty) ...[
            _buildSectionHeader('Recent Activity', accentColor),
            pw.SizedBox(height: 12),
            _buildTimelineSection(timeline.take(12).toList(), accentColor),
            pw.SizedBox(height: 28),
          ],

          // Applications by Status
          _buildSectionHeader('Applications Overview', accentColor),
          pw.SizedBox(height: 12),
          _buildApplicationsByStatus(byStatus, accentColor),
        ],
      ),
    );

    return pdf.save();
  }

  static Map<String, dynamic> _calculateStatistics(
      List<JobApplication> applications) {
    final total = applications.length;
    final draft = applications
        .where((app) => app.status == ApplicationStatus.draft)
        .length;
    final applied = applications
        .where((app) => app.status == ApplicationStatus.applied)
        .length;
    final interviewing = applications
        .where((app) => app.status == ApplicationStatus.interviewing)
        .length;
    final successful = applications
        .where((app) => app.status == ApplicationStatus.successful)
        .length;
    final rejected = applications
        .where((app) => app.status == ApplicationStatus.rejected)
        .length;
    final noResponse = applications
        .where((app) => app.status == ApplicationStatus.noResponse)
        .length;

    final active = draft + applied + interviewing;
    final closed = successful + rejected + noResponse;
    final successRate =
        total > 0 ? (successful / total * 100).toStringAsFixed(1) : '0.0';
    final responseRate = total > 0
        ? ((total - noResponse) / total * 100).toStringAsFixed(1)
        : '0.0';
    final interviewRate = total > 0
        ? ((interviewing + successful) / total * 100).toStringAsFixed(1)
        : '0.0';

    return {
      'total': total,
      'draft': draft,
      'applied': applied,
      'interviewing': interviewing,
      'successful': successful,
      'rejected': rejected,
      'noResponse': noResponse,
      'active': active,
      'closed': closed,
      'successRate': successRate,
      'responseRate': responseRate,
      'interviewRate': interviewRate,
    };
  }

  static Map<ApplicationStatus, List<JobApplication>> _groupByStatus(
      List<JobApplication> applications) {
    final Map<ApplicationStatus, List<JobApplication>> grouped = {};

    for (final app in applications) {
      grouped.putIfAbsent(app.status, () => []).add(app);
    }

    // Sort each group by date (most recent first)
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) {
        if (a.applicationDate == null && b.applicationDate == null) return 0;
        if (a.applicationDate == null) return 1;
        if (b.applicationDate == null) return -1;
        return b.applicationDate!.compareTo(a.applicationDate!);
      });
    }

    return grouped;
  }

  /// Professional header matching CV style
  static pw.Widget _buildProfessionalHeader(PdfColor accentColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'JOB APPLICATION STATISTICS',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey900,
            letterSpacing: 2,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Comprehensive Overview',
          style: pw.TextStyle(
            fontSize: 14,
            color: accentColor,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          height: 2,
          width: 60,
          color: accentColor,
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'Generated on ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
        ),
      ],
    );
  }

  /// Section header matching CV style
  static pw.Widget _buildSectionHeader(String title, PdfColor accentColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: accentColor,
            letterSpacing: 1.5,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          height: 1.5,
          width: 40,
          color: accentColor,
        ),
      ],
    );
  }

  /// Statistics overview with clean cards
  static pw.Widget _buildStatisticsOverview(
      Map<String, dynamic> stats, PdfColor accentColor) {
    return pw.Column(
      children: [
        // First row: Total, Active, Closed
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildStatCard(
                label: 'Total Applications',
                value: stats['total'].toString(),
                color: accentColor,
                isLarge: true,
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: _buildStatCard(
                label: 'Active',
                value: stats['active'].toString(),
                color: PdfColors.blue700,
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: _buildStatCard(
                label: 'Closed',
                value: stats['closed'].toString(),
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        // Second row: Status breakdown
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildStatCard(
                label: 'Draft',
                value: stats['draft'].toString(),
                color: PdfColors.grey600,
                compact: true,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: _buildStatCard(
                label: 'Applied',
                value: stats['applied'].toString(),
                color: PdfColors.blue600,
                compact: true,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: _buildStatCard(
                label: 'Interviewing',
                value: stats['interviewing'].toString(),
                color: PdfColors.purple600,
                compact: true,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: _buildStatCard(
                label: 'Successful',
                value: stats['successful'].toString(),
                color: PdfColors.green700,
                compact: true,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: _buildStatCard(
                label: 'Rejected',
                value: stats['rejected'].toString(),
                color: PdfColors.red700,
                compact: true,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: _buildStatCard(
                label: 'No Response',
                value: stats['noResponse'].toString(),
                color: PdfColors.orange700,
                compact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Clean stat card matching CV style
  static pw.Widget _buildStatCard({
    required String label,
    required String value,
    required PdfColor color,
    bool isLarge = false,
    bool compact = false,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.all(compact ? 8 : 12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isLarge ? 28 : (compact ? 16 : 20),
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: compact ? 2 : 4),
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: compact ? 8 : 9,
              color: PdfColors.grey700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Key metrics section
  static pw.Widget _buildKeyMetrics(
      Map<String, dynamic> stats, PdfColor accentColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: accentColor.shade(0.95),
        border: pw.Border.all(color: accentColor, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(
              'Success Rate', '${stats['successRate']}%', accentColor),
          pw.Container(width: 1, height: 30, color: accentColor.shade(0.7)),
          _buildMetricItem(
              'Response Rate', '${stats['responseRate']}%', accentColor),
          pw.Container(width: 1, height: 30, color: accentColor.shade(0.7)),
          _buildMetricItem(
              'Interview Rate', '${stats['interviewRate']}%', accentColor),
        ],
      ),
    );
  }

  static pw.Widget _buildMetricItem(
      String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  /// Timeline section with clean design
  static pw.Widget _buildTimelineSection(
      List<JobApplication> applications, PdfColor accentColor) {
    return pw.Column(
      children: applications.map((app) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              left: pw.BorderSide(color: _getStatusColor(app.status), width: 3),
            ),
            color: PdfColors.grey100,
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      app.company,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey900,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      app.position,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: _getStatusColor(app.status).shade(0.9),
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(3)),
                      ),
                      child: pw.Text(
                        _getStatusLabel(app.status),
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: _getStatusColor(app.status),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Text(
                      DateFormat('MMM dd, yyyy').format(app.applicationDate!),
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Applications by status with clean grouping
  static pw.Widget _buildApplicationsByStatus(
      Map<ApplicationStatus, List<JobApplication>> byStatus,
      PdfColor accentColor) {
    // Define order for status display
    final statusOrder = [
      ApplicationStatus.interviewing,
      ApplicationStatus.applied,
      ApplicationStatus.draft,
      ApplicationStatus.successful,
      ApplicationStatus.rejected,
      ApplicationStatus.noResponse,
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: statusOrder
          .where((status) => byStatus[status]?.isNotEmpty ?? false)
          .map((status) {
        final apps = byStatus[status]!;
        final color = _getStatusColor(status);

        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Status header
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: color.shade(0.9),
                  border: pw.Border(
                    left: pw.BorderSide(color: color, width: 3),
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      _getStatusLabel(status),
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.Spacer(),
                    pw.Text(
                      '${apps.length} ${apps.length == 1 ? 'application' : 'applications'}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),
              // Applications list
              ...apps.map((app) => pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 3,
                          height: 3,
                          decoration: const pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            color: PdfColors.grey500,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            app.company,
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey900,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            app.position,
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ),
                        if (app.location != null && app.location!.isNotEmpty)
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              app.location!,
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.grey600,
                              ),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                      ],
                    ),
                  )),
            ],
          ),
        );
      }).toList(),
    );
  }

  static PdfColor _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.draft:
        return PdfColors.grey600;
      case ApplicationStatus.applied:
        return PdfColors.blue600;
      case ApplicationStatus.interviewing:
        return PdfColors.purple600;
      case ApplicationStatus.successful:
        return PdfColors.green700;
      case ApplicationStatus.rejected:
        return PdfColors.red700;
      case ApplicationStatus.noResponse:
        return PdfColors.orange700;
    }
  }

  static String _getStatusLabel(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.draft:
        return 'DRAFT';
      case ApplicationStatus.applied:
        return 'APPLIED';
      case ApplicationStatus.interviewing:
        return 'INTERVIEWING';
      case ApplicationStatus.successful:
        return 'SUCCESSFUL';
      case ApplicationStatus.rejected:
        return 'REJECTED';
      case ApplicationStatus.noResponse:
        return 'NO RESPONSE';
    }
  }
}
