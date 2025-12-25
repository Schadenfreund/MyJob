# UserData Templates

This folder contains structured templates for importing your personal data into the MyLife application.

## Structure

```
UserData/
├── CV/
│   ├── cv_data_english.yaml
│   └── cv_data_german.yaml
└── CoverLetter/
    ├── cover_letter_template_english.yaml
    └── cover_letter_template_german.yaml
```

## How to Use

### CV Data Templates

The CV data templates (`cv_data_english.yaml` and `cv_data_german.yaml`) contain structured information about:

- **Personal Info**: Name, contact details, profile summary
- **Skills**: Professional and technical skills with proficiency levels
- **Languages**: Language proficiencies
- **Interests**: Hobbies and interests
- **Work Experience**: Detailed employment history

**To import:**
1. Edit the YAML file with your information
2. Open MyLife application
3. Navigate to the Templates tab
4. Click "Import Data" and select your YAML file
5. Review and confirm the imported data

### Cover Letter Templates

The cover letter templates contain:
- Multiple versions (current employment / past employment)
- Customizable placeholders (marked with `==`)
- Structured paragraphs for easy editing

**To use:**
1. Select the appropriate language template
2. Choose between `current` or `past_tense` version
3. Replace placeholders with specific job application details
4. Import or copy into a new cover letter

## File Format

All templates use **YAML format** for the following reasons:
- Human-readable and easy to edit
- Structured and parseable by the application
- Supports multi-line text and special characters
- Industry standard for configuration files

## Tips

- Keep backups of your templates
- Create new versions for different job types
- Use the placeholders (==XX==) to quickly identify areas that need customization
- Both English and German versions are provided - use the one that matches your target language

## Support

For questions or issues with importing data, refer to the MyLife application documentation.
