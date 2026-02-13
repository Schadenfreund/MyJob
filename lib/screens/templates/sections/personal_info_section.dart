import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_data_provider.dart';
import '../../../models/user_data/personal_info.dart';
import '../../../services/templates_storage_service.dart';
import '../../../widgets/profile_picture_picker.dart';
import '../../../constants/ui_constants.dart';
import '../../../localization/app_localizations.dart';

/// Personal information management section
class PersonalInfoSection extends StatelessWidget {
  const PersonalInfoSection({
    this.showHeader = true,
    super.key,
  });

  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userDataProvider = context.watch<UserDataProvider>();
    final personalInfo = userDataProvider.personalInfo;

    final content = Padding(
      padding: showHeader ? UIConstants.cardPadding : EdgeInsets.zero,
      child: personalInfo == null
          ? _buildEmptyState(context)
          : _buildPersonalInfoContent(context, personalInfo),
    );

    if (!showHeader) {
      return content;
    }

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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  context.tr('personal_info'),
                  style: theme.textTheme.titleMedium?.copyWith(
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
                  label: Text(personalInfo == null ? context.tr('add') : context.tr('edit')),
                  style: UIConstants.getSecondaryButtonStyle(context),
                ),
              ],
            ),
          ),
          content,
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
              context.tr('no_personal_info'),
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
    final userDataProvider = context.read<UserDataProvider>();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Picture Picker - Always visible for easy editing
        Column(
          children: [
            ProfilePicturePicker(
              imagePath: info.profilePicturePath,
              size: 90,
              placeholderInitial:
                  info.fullName.isNotEmpty ? info.fullName[0] : null,
              backgroundColor: theme.colorScheme.primary,
              onImageSelected: (selectedPath) async {
                await _handleProfilePictureUpdate(
                  context,
                  userDataProvider,
                  info,
                  selectedPath,
                );
              },
              onImageRemoved: () async {
                await _handleProfilePictureUpdate(
                  context,
                  userDataProvider,
                  info,
                  '', // Empty string to clear
                );
              },
            ),
          ],
        ),
        const SizedBox(width: 20),

        // Info fields
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(context, Icons.badge, context.tr('full_name'), info.fullName),
              if (info.jobTitle != null && info.jobTitle!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoRow(context, Icons.work, context.tr('job_title'), info.jobTitle!),
              ],
              if (info.email != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(context, Icons.email, context.tr('email'), info.email!),
              ],
              if (info.phone != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(context, Icons.phone, context.tr('phone'), info.phone!),
              ],
              if (info.address != null ||
                  info.city != null ||
                  info.country != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  Icons.location_on,
                  context.tr('location'),
                  [info.address, info.city, info.country]
                      .where((e) => e != null && e.isNotEmpty)
                      .join(', '),
                ),
              ],
              if (info.linkedin != null && info.linkedin!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoRow(context, Icons.link, context.tr('linkedin'), info.linkedin!),
              ],
              if (info.website != null && info.website!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                    context, Icons.language, context.tr('website'), info.website!),
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

  static void showEditDialog(BuildContext context) {
    final existingInfo = context.read<UserDataProvider>().personalInfo;
    _showEditDialogImpl(context, existingInfo);
  }

  void _showEditDialog(BuildContext context, PersonalInfo? existingInfo) {
    _showEditDialogImpl(context, existingInfo);
  }

  static void _showEditDialogImpl(BuildContext context, PersonalInfo? existingInfo) {
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

  /// Handle profile picture update
  Future<void> _handleProfilePictureUpdate(
    BuildContext context,
    UserDataProvider provider,
    PersonalInfo info,
    String newPath,
  ) async {
    try {
      debugPrint('[PersonalInfoSection] === Profile Picture Update ===');
      debugPrint('[PersonalInfoSection] New path from picker: "$newPath"');

      String? storedPath = newPath;

      // If adding/changing picture (not removing), copy to storage
      if (newPath.isNotEmpty) {
        final storage = TemplatesStorageService.instance;
        final isAlreadyStored = await storage.isStoredProfilePicture(newPath);
        debugPrint('[PersonalInfoSection] Is already stored: $isAlreadyStored');

        if (!isAlreadyStored) {
          // Copy to UserData folder (language-specific)
          final currentLanguage = provider.currentLanguage;
          debugPrint(
              '[PersonalInfoSection] Copying to UserData folder for language: ${currentLanguage.code}');
          final copiedPath = await storage.saveProfilePicture(newPath,
              language: currentLanguage);
          debugPrint('[PersonalInfoSection] Copied to: "$copiedPath"');
          if (copiedPath != null) {
            storedPath = copiedPath;
          }
        }
      } else {
        // Removing picture
        debugPrint('[PersonalInfoSection] Removing picture');
        storedPath = null;
      }

      // Update the personal info with new picture path
      debugPrint(
          '[PersonalInfoSection] Updating PersonalInfo with path: "$storedPath"');
      final updatedInfo = info.copyWith(profilePicturePath: storedPath ?? '');
      debugPrint(
          '[PersonalInfoSection] Updated info has picture: ${updatedInfo.hasProfilePicture}');
      debugPrint(
          '[PersonalInfoSection] Updated info path: "${updatedInfo.profilePicturePath}"');

      await provider.updatePersonalInfo(updatedInfo);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(newPath.isEmpty
                    ? context.tr('profile_picture_removed')
                    : context.tr('profile_picture_updated')),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('profile_picture_failed')}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        widget.existingInfo == null
            ? context.tr('add_personal_info')
            : context.tr('edit_personal_info'),
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
                      decoration: InputDecoration(
                        labelText: '${context.tr('full_name')} *',
                        prefixIcon: const Icon(Icons.badge),
                      ),
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _jobTitleController,
                      decoration: InputDecoration(
                        labelText: context.tr('job_title'),
                        prefixIcon: const Icon(Icons.work),
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
                      decoration: InputDecoration(
                        labelText: context.tr('email'),
                        prefixIcon: const Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: context.tr('phone'),
                        prefixIcon: const Icon(Icons.phone),
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
                decoration: InputDecoration(
                  labelText: context.tr('address'),
                  prefixIcon: const Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),

              // City and country row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: context.tr('city'),
                        prefixIcon: const Icon(Icons.location_city),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _countryController,
                      decoration: InputDecoration(
                        labelText: context.tr('country'),
                        prefixIcon: const Icon(Icons.flag),
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
                      decoration: InputDecoration(
                        labelText: context.tr('linkedin'),
                        prefixIcon: const Icon(Icons.link),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _websiteController,
                      decoration: InputDecoration(
                        labelText: context.tr('website'),
                        prefixIcon: const Icon(Icons.language),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: UIConstants.getTextButtonStyle(context),
          child: Text(context.tr('cancel')),
        ),
        FilledButton(
          onPressed: _save,
          style: UIConstants.getPrimaryButtonStyle(context),
          child: Text(context.tr('save')),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('name_is_required'))),
      );
      return;
    }

    String? trimOrNull(String value) =>
        value.trim().isEmpty ? null : value.trim();

    // Copy profile picture to UserData folder if not already stored there
    String? storedPicturePath = _profilePicturePath;
    if (_profilePicturePath != null && _profilePicturePath!.isNotEmpty) {
      // Get language before async operations
      final provider = context.read<UserDataProvider>();
      final currentLanguage = provider.currentLanguage;

      final storage = TemplatesStorageService.instance;
      final isAlreadyStored =
          await storage.isStoredProfilePicture(_profilePicturePath);
      if (!isAlreadyStored) {
        // Copy to UserData folder (language-specific)
        final newPath = await storage.saveProfilePicture(
          _profilePicturePath!,
          language: currentLanguage,
        );
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
        );

    await widget.onSave(newInfo);
  }
}
