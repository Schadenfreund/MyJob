import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/documents_provider.dart';
import '../../models/cv_data.dart';
import 'cv_editor_screen.dart';

class CvListScreen extends StatelessWidget {
  const CvListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CVs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DocumentsProvider>().loadDocuments();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New CV'),
      ),
      body: Consumer<DocumentsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.cvs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No CVs yet',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first CV to get started',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.cvs.length,
            itemBuilder: (context, index) {
              final cv = provider.cvs[index];
              return _CvCard(
                cv: cv,
                onTap: () => _openEditor(context, cv),
                onDelete: () => _confirmDelete(context, cv),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New CV'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'CV Name',
            hintText: 'e.g., Main CV, Tech CV',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final provider = context.read<DocumentsProvider>();
                final cv = await provider.createCv(name: nameController.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  _openEditor(context, cv);
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _openEditor(BuildContext context, CvData cv) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CvEditorScreen(cvId: cv.id),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CvData cv) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete CV?'),
        content: Text('Are you sure you want to delete "${cv.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              context.read<DocumentsProvider>().deleteCv(cv.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CvCard extends StatelessWidget {
  const _CvCard({
    required this.cv,
    required this.onTap,
    required this.onDelete,
  });

  final CvData cv;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cv.name,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cv.lastModified != null
                          ? 'Modified ${dateFormat.format(cv.lastModified!)}'
                          : 'No modifications',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
