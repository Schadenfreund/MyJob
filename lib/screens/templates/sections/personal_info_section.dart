import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_data_provider.dart';
import '../../../models/user_data/personal_info.dart';
import '../../../services/templates_storage_service.dart';
import '../../../widgets/profile_picture_picker.dart';
import '../../../constants/ui_constants.dart';

/// Personal information management section
class PersonalInfoSection extends StatelessWidget {
  const PersonalInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userDataProvider = context.watch<UserDataProvider>();
    final personalInfo = userDataProvider.personalInfo;

    return Container(
      decoration: UIConstants.getCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: UIConstants.cardPadding,
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Personal Information',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _showEditDialog(context, personalInfo),
                  icon: Icon(
                    personalInfo == null ? Icons.add : Icons.edit,
                    size: 16,
                  ),
                  label: Text(personalInfo == null ? 'Add Info' : 'Edit'),
                  style: UIConstants.getSecondaryButtonStyle(context),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: UIConstants.cardPadding,
            child: personalInfo == null
                ? _buildEmptyState(context)
                : _buildPersonalInfoContent(context, personalInfo),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.person_add_outlined,
              size: 48,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No personal information yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoContent(BuildContext context, PersonalInfo info) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile picture
        if (info.hasProfilePicture) ...[
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Image.file(
                File(info.profilePicturePath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: theme.colorScheme.primary,
                  child: Center(
                    child: Text(
                      info.fullName.isNotEmpty
                          ? info.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],

        // Info fields
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(context, Icons.badge, 'Name', info.fullName),
              if (info.jobTitle != null && info.jobTitle!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoRow(context, Icons.work, 'Job Title', info.jobTitle!),
              ],
              if (info.email != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(context, Icons.email, 'Email', info.email!),
              ],
              if (info.phone != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(context, Icons.phone, 'Phone', info.phone!),
              ],
              if (info.address != null ||
                  info.city != null ||
                  info.country != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  Icons.location_on,
                  'Location',
                  [info.address, info.city, info.country]
                      .where((e) => e != null && e.isNotEmpty)
                      .join(', '),
                ),
              ],
              if (info.linkedin != null && info.linkedin!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoRow(context, Icons.link, 'LinkedIn', info.linkedin!),
              ],
              if (info.website != null && info.website!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                    context, Icons.language, 'Website', info.website!),
              ],
              if (info.profileSummary != null &&
                  info.profileSummary!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 16,
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Profile Summary',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        info.profileSummary!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
      BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color:
                      theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context, PersonalInfo? existingInfo) {
    showDialog(
      context: context,
      builder: (dialogContext) => _PersonalInfoEditDialog(
        existingInfo: existingInfo,
        onSave: (newInfo) async {
          await context.read<UserDataProvider>().updatePersonalInfo(newInfo);
          if (dialogContext.mounted) Navigator.pop(dialogContext);
        },
      ),
    );
  }
}

/// Stateful dialog for editing personal info with profile picture support
class _PersonalInfoEditDialog extends StatefulWidget {
  const _PersonalInfoEditDialog({
    this.existingInfo,
    required this.onSave,
  });

  final PersonalInfo? existingInfo;
  final Future<void> Function(PersonalInfo) onSave;

  @override
  State<_PersonalInfoEditDialog> createState() =>
      _PersonalInfoEditDialogState();
}

class _PersonalInfoEditDialogState extends State<_PersonalInfoEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _jobTitleController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _countryController;
  late TextEditingController _linkedinController;
  late TextEditingController _websiteController;
  late TextEditingController _summaryController;
  String? _profilePicturePath;

  @override
  void initState() {
    super.initState();
    final info = widget.existingInfo;
    _nameController = TextEditingController(text: info?.fullName ?? '');
    _jobTitleController = TextEditingController(text: info?.jobTitle ?? '');
    _emailController = TextEditingController(text: info?.email ?? '');
    _phoneController = TextEditingController(text: info?.phone ?? '');
    _addressController = TextEditingController(text: info?.address ?? '');
    _cityController = TextEditingController(text: info?.city ?? '');
    _countryController = TextEditingController(text: info?.country ?? '');
    _linkedinController = TextEditingController(text: info?.linkedin ?? '');
    _websiteController = TextEditingController(text: info?.website ?? '');
    _summaryController =
        TextEditingController(text: info?.profileSummary ?? '');
    _profilePicturePath = info?.profilePicturePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jobTitleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _linkedinController.dispose();
    _websiteController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        widget.existingInfo == null
            ? 'Add Personal Info'
            : 'Edit Personal Info',
      ),
      content: SizedBox(
        width: 550,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile picture picker
              ProfilePicturePicker(
                imagePath: _profilePicturePath,
                size: 100,
                placeholderInitial: _nameController.text.isNotEmpty
                    ? _nameController.text[0]
                    : '?',
                backgroundColor: theme.colorScheme.primary,
                onImageSelected: (path) {
                  setState(() => _profilePicturePath = path);
                },
                onImageRemoved: () {
                  setState(() => _profilePicturePath = null);
                },
              ),
              const SizedBox(height: 24),

              // Name and job title row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: Icon(Icons.badge),
                      ),
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _jobTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Job Title',
                        prefixIcon: Icon(Icons.work),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Email and phone row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Address
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),

              // City and country row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        prefixIcon: Icon(Icons.location_city),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _countryController,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        prefixIcon: Icon(Icons.flag),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // LinkedIn and website row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _linkedinController,
                      decoration: const InputDecoration(
                        labelText: 'LinkedIn',
                        prefixIcon: Icon(Icons.link),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _websiteController,
                      decoration: const InputDecoration(
                        labelText: 'Website',
                        prefixIcon: Icon(Icons.language),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Profile summary
              TextField(
                controller: _summaryController,
                decoration: const InputDecoration(
                  labelText: 'Profile Summary',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: UIConstants.getTextButtonStyle(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          style: UIConstants.getPrimaryButtonStyle(context),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }

    String? trimOrNull(String value) =>
        value.trim().isEmpty ? null : value.trim();

    // Copy profile picture to UserData folder if not already stored there
    String? storedPicturePath = _profilePicturePath;
    if (_profilePicturePath != null && _profilePicturePath!.isNotEmpty) {
      final storage = TemplatesStorageService.instance;
      final isAlreadyStored =
          await storage.isStoredProfilePicture(_profilePicturePath);
      if (!isAlreadyStored) {
        // Copy to UserData folder
        final newPath = await storage.saveProfilePicture(_profilePicturePath!);
        if (newPath != null) {
          storedPicturePath = newPath;
        }
      }
    }

    final newInfo = widget.existingInfo?.copyWith(
          fullName: _nameController.text.trim(),
          jobTitle: trimOrNull(_jobTitleController.text),
          profilePicturePath: storedPicturePath,
          email: trimOrNull(_emailController.text),
          phone: trimOrNull(_phoneController.text),
          address: trimOrNull(_addressController.text),
          city: trimOrNull(_cityController.text),
          country: trimOrNull(_countryController.text),
          linkedin: trimOrNull(_linkedinController.text),
          website: trimOrNull(_websiteController.text),
          profileSummary: trimOrNull(_summaryController.text),
        ) ??
        PersonalInfo(
          fullName: _nameController.text.trim(),
          jobTitle: trimOrNull(_jobTitleController.text),
          profilePicturePath: storedPicturePath,
          email: trimOrNull(_emailController.text),
          phone: trimOrNull(_phoneController.text),
          address: trimOrNull(_addressController.text),
          city: trimOrNull(_cityController.text),
          country: trimOrNull(_countryController.text),
          linkedin: trimOrNull(_linkedinController.text),
          website: trimOrNull(_websiteController.text),
          profileSummary: trimOrNull(_summaryController.text),
        );

    await widget.onSave(newInfo);
  }
}
