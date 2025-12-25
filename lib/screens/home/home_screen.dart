import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/applications_provider.dart';
import '../../providers/templates_provider.dart';
import '../../constants/app_constants.dart';
import '../../theme/app_theme.dart';
import '../../widgets/application_card.dart';
import '../applications/application_editor_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onNavigateToTab});

  final ValueChanged<int>? onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          Text(
            'Welcome to MyLife',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your job applications and document templates',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),

          // Stats cards
          Text(
            'Applications Overview',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Consumer<ApplicationsProvider>(
            builder: (context, provider, _) {
              final counts = provider.statusCounts;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildStatCard(
                    context,
                    'Total Applications',
                    provider.totalCount.toString(),
                    Icons.work,
                    theme.colorScheme.primary,
                    isDark,
                  ),
                  _buildStatCard(
                    context,
                    'Applied',
                    counts[ApplicationStatus.applied]?.toString() ?? '0',
                    Icons.send,
                    AppTheme.statusApplied,
                    isDark,
                  ),
                  _buildStatCard(
                    context,
                    'Interviewing',
                    counts[ApplicationStatus.interviewing]?.toString() ?? '0',
                    Icons.people,
                    AppTheme.statusInterviewing,
                    isDark,
                  ),
                  _buildStatCard(
                    context,
                    'Accepted',
                    counts[ApplicationStatus.accepted]?.toString() ?? '0',
                    Icons.check_circle,
                    AppTheme.statusAccepted,
                    isDark,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // Templates stats
          Text(
            'Templates',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Consumer<TemplatesProvider>(
            builder: (context, provider, _) {
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildStatCard(
                    context,
                    'CV Templates',
                    provider.cvTemplates.length.toString(),
                    Icons.description,
                    AppTheme.lightInfo,
                    isDark,
                  ),
                  _buildStatCard(
                    context,
                    'Cover Letter Templates',
                    provider.coverLetterTemplates.length.toString(),
                    Icons.email,
                    AppTheme.lightSuccess,
                    isDark,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // Quick actions
          Text(
            'Quick Actions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildActionCard(
                context,
                'New Application',
                'Track a new job application',
                Icons.add_circle,
                theme.colorScheme.primary,
                () {
                  showDialog(
                    context: context,
                    builder: (context) => const ApplicationEditorDialog(),
                  );
                },
              ),
              _buildActionCard(
                context,
                'Create CV Template',
                'Build a reusable CV template',
                Icons.description_outlined,
                AppTheme.lightInfo,
                () {
                  // Switch to Templates tab (index 2)
                  onNavigateToTab?.call(2);
                },
              ),
              _buildActionCard(
                context,
                'Create Cover Letter',
                'Build a cover letter template',
                Icons.email_outlined,
                AppTheme.lightSuccess,
                () {
                  // Switch to Templates tab (index 2)
                  onNavigateToTab?.call(2);
                },
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Recent applications
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Applications',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // Switch to Applications tab (index 1)
                  onNavigateToTab?.call(1);
                },
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer<ApplicationsProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (provider.recentApplications.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(48),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.dividerColor,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.work_outline,
                          size: 64,
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No applications yet',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start tracking your job applications',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) =>
                                  const ApplicationEditorDialog(),
                            );
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create Application'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: provider.recentApplications.map((app) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ApplicationCard(
                      application: app,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => ApplicationEditorDialog(
                            applicationId: app.id,
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
