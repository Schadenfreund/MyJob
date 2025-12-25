import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/documents_provider.dart';
import '../../models/cover_letter.dart';
import 'cover_letter_editor_screen.dart';

class CoverLetterListScreen extends StatelessWidget {
  const CoverLetterListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cover Letters'),
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
        label: const Text('New Cover Letter'),
      ),
      body: Consumer<DocumentsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.coverLetters.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 64,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No cover letters yet',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first cover letter to get started',
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
            itemCount: provider.coverLetters.length,
            itemBuilder: (context, index) {
              final letter = provider.coverLetters[index];
              return _CoverLetterCard(
                letter: letter,
                onTap: () => _openEditor(context, letter),
                onDelete: () => _confirmDelete(context, letter),
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
        title: const Text('Create Cover Letter'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'e.g., Tech Company Letter',
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
                final letter = await provider.createCoverLetter(
                  name: nameController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  _openEditor(context, letter);
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _openEditor(BuildContext context, CoverLetter letter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoverLetterEditorScreen(letterId: letter.id),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CoverLetter letter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Cover Letter?'),
        content: Text('Are you sure you want to delete "${letter.name}"?'),
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
              context.read<DocumentsProvider>().deleteCoverLetter(letter.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CoverLetterCard extends StatelessWidget {
  const _CoverLetterCard({
    required this.letter,
    required this.onTap,
    required this.onDelete,
  });

  final CoverLetter letter;
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
                  Icons.email,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      letter.name,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    if (letter.companyName != null)
                      Text(
                        letter.companyName!,
                        style: theme.textTheme.bodySmall,
                      ),
                    Text(
                      letter.lastModified != null
                          ? 'Modified ${dateFormat.format(letter.lastModified!)}'
                          : 'No modifications',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.labelSmall?.color,
                      ),
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
