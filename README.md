# MyJob

A comprehensive job application management tool with CV and cover letter creation.

## Features

- **Bilingual Profile Management** - Maintain separate English and German profiles
- **Job Application Tracking** - Track status, notes, salary expectations, and contacts
- **Notes & Todo System** - Organize with priorities, tags, and archiving
- **Professional PDF Generation** - Multiple CV templates with customizable colors and fonts
- **Backup & Restore** - Create and restore ZIP backups of all your data
- **Auto-Update** - Check for updates directly from the app
- **Dark/Light Mode** - Multiple accent color themes

---

## Quick Start

### Download & Run

1. Download the latest release from [Releases](https://github.com/Schadenfreund/MyJob/releases)
2. Extract the ZIP file to any folder
3. Run `MyJob.exe`

**That's it!** No installation required. The app is fully portable.

### First Steps

1. **Fill out your Profile** - Go to the Profile tab and add your personal info, work experience, education, skills, and languages
2. **Create a Job Application** - Go to Job Applications and create your first application
3. **Generate your CV** - Customize and export a professional PDF

---

## Importing Your Own CV Data

MyJob uses YAML files for CV and cover letter data. Check the **DEMO_DATA** folder included in the release for templates you can use as a starting point.

### DEMO_DATA Folder Structure

```text
DEMO_DATA/
├── CV/
│   ├── cv_data_english_test.yaml    # English CV template
│   └── cv_data_german_test.yaml     # German CV template
└── CoverLetter/
    ├── cover_letter_template_english_test.yaml
    └── cover_letter_template_german_test.yaml
```

### How to Create Your Own CV File

1. **Copy a template** from `DEMO_DATA/CV/`
2. **Edit the YAML file** with your own data (use any text editor like Notepad++)
3. **Import into MyJob**:
   - Go to the **Profile** tab
   - Click the **Import** button
   - Select your edited YAML file

### YAML Format Example

```yaml
personal_info:
  first_name: "John"
  last_name: "Doe"
  email: "john.doe@email.com"
  phone: "+1 234 567 890"
  address: "123 Main Street"
  city: "New York"
  postal_code: "10001"
  country: "USA"

work_experience:
  - company: "Tech Corp"
    position: "Software Developer"
    start_date: "2020-01"
    end_date: "2024-01"
    description: "Developed web applications..."

education:
  - institution: "University of Technology"
    degree: "Bachelor of Science"
    field: "Computer Science"
    start_date: "2016-09"
    end_date: "2020-06"

skills:
  - name: "Python"
    level: "Expert"
  - name: "JavaScript"
    level: "Advanced"

languages:
  - name: "English"
    level: "Native"
  - name: "German"
    level: "Intermediate"
```

---

## User Data Location

All your data is stored in: `<app folder>/UserData/`

```text
UserData/
├── profiles/
│   ├── en/          # English profile
│   └── de/          # German profile
├── applications/    # Job applications
├── notes/           # Notes & todos
├── pdf_presets/     # PDF customizations
└── settings.json    # App settings
```

**Portable by design**: Move the entire folder to backup or transfer to another computer.

---

## Updating the App

1. Go to **Settings** tab
2. Click **Check for Updates**
3. If an update is available, click **Download & Install**
4. The app will restart automatically with the new version

Your `UserData` folder is preserved during updates.

---

## Backup & Restore

### Creating a Backup

1. Go to **Settings** > **Data Management**
2. Select a backup destination folder
3. Click **Create Backup Zip**

### Restoring from Backup

1. Go to **Settings** > **Data Management**
2. Click **Restore Zip**
3. Select your backup file
4. Restart the application

---

## Building from Source

### Requirements

- Flutter SDK >=3.0.0
- Windows 10/11

### Build Steps

```bash
git clone https://github.com/Schadenfreund/MyJob.git
cd MyJob
flutter pub get
flutter run -d windows
```

### Release Build

```powershell
.\build-release.ps1              # Build current version
.\build-release.ps1 -BumpPatch   # Increment version and build
.\build-release.ps1 -Help        # See all options
```

---

## Support

If you find this tool helpful, please consider supporting the development:

**[Support via PayPal](https://www.paypal.com/paypalme/ivburic)**

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Version**: 1.0.0
**Author**: Ivan Buric
