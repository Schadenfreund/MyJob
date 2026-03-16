# MyJob

A portable Windows desktop app for managing job applications, generating professional CVs and cover letters, and staying organized throughout your job search.

## Example CV (one of 4 customizable templates)

<img width="742" height="1047" alt="example" src="https://github.com/user-attachments/assets/21b905b1-f61e-4762-84d0-b13bb5c79106" />

## Features

- **Multilingual Profiles** — Maintain a separate profile per language; switch with one click
- **Custom Translations** — Import any language as a JSON file; it appears immediately in the UI, Profile selector, and PDF editor
- **Job Application Tracking** — Track status, notes, salary expectations, and contacts for every application
- **Notes & Todos** — Organize with priorities, due dates, tags, and archiving
- **Professional PDF Generation** — Multiple CV and cover letter templates with customizable colors, fonts, and layout presets
- **Backup & Restore** — Create and restore ZIP backups of all your data, including safety backups on every restore
- **Auto-Update** — Check for and install updates directly from the app
- **Dark / Light Mode** — Five accent color themes to choose from

---

## Quick Start

### Download & Run

1. Download the latest release from [Releases](https://github.com/Schadenfreund/MyJob/releases)
2. Extract the ZIP to any folder
3. Run `MyJob.exe`

No installation required — the app is fully portable.

### First Steps

1. **Fill out your Profile** — Open the Profile tab and add your personal info, work experience, education, skills, and languages
2. **Create a Job Application** — Switch to Job Applications, create your first entry, and customize the cloned profile data for that job
3. **Generate a PDF** — Open the PDF editor from any application to preview and export a professional CV or cover letter

---

## Adding Custom Languages

MyJob ships with English and German. You can add any other language by importing a JSON locale file — no restart required.

A **Croatian example** (`locale_hr.json`) is included in `DEMO_DATA/localization/` as a ready-to-use starting point.

### Creating a Translation File

1. Copy `DEMO_DATA/localization/locale_hr.json` and rename it to `locale_<code>.json` (e.g. `locale_fr.json` for French)
2. Open the file in any text editor
3. Edit the `_meta` section at the top with your language's name, code, and flag emoji
4. Translate every value (the part after the colon) into your target language — keep all keys unchanged

The `_meta` block should look like this:

```json
{
  "_meta": {
    "language_name": "Francais",
    "language_code": "fr",
    "flag": "🇫🇷",
    "author": "Your Name",
    "version": "1.0"
  },
  "tab_profile": "Profil",
  ...
}
```

### Importing into the App

1. Go to **Settings > Language**
2. Click **Import Language File** and select your JSON file

Once imported, the new language appears in three places:

- **App UI** — the entire interface switches to the new language
- **Profile tab** — a new chip appears in the language selector so you can create a profile in that language
- **PDF editor** — the language becomes available in the document language dropdown

Custom language profiles work exactly like built-in ones: fill in your data, generate PDFs, and switch between languages with a single click. You can remove a custom language at any time from **Settings > Language**.

---

## Importing Your Own CV Data

MyJob uses YAML files for CV and cover letter data. The **DEMO_DATA** folder included in every release contains templates you can use as a starting point.

### DEMO_DATA Folder Structure

```text
DEMO_DATA/
├── CV/
│   ├── cv_data_english_test.yaml    # English CV template
│   └── cv_data_german_test.yaml     # German CV template
├── CoverLetter/
│   ├── cover_letter_template_english_test.yaml
│   └── cover_letter_template_german_test.yaml
└── localization/
    └── locale_hr.json               # Croatian translation example
```

### How to Import

1. Copy one of the templates from `DEMO_DATA/CV/`
2. Edit the YAML file with your own data (any text editor works)
3. In the app, go to the **Profile** tab and click **Import**
4. Select your edited YAML file and choose which sections to import

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

All your data lives in `<app folder>/UserData/`:

```text
UserData/
├── profiles/        # One subfolder per language (en/, de/, fr/, ...)
├── applications/    # Job applications and their tailored documents
├── notes/           # Notes and todos (YAML)
├── localization/    # Custom language files
├── pdf_presets/     # Saved PDF style presets
└── settings.json    # App preferences
```

The entire folder is portable — move or copy it to transfer your data to another computer.

---

## Backup & Restore

### Creating a Backup

1. Go to **Settings > Data Management**
2. Select a backup destination folder
3. Click **Create Backup ZIP**

The backup contains everything: profiles, applications, notes, custom languages, PDF presets, and settings.

### Restoring from Backup

1. Go to **Settings > Data Management**
2. Click **Restore ZIP** and select your backup file
3. Restart the app to load the restored data

A safety backup of your current data is created automatically before every restore, so you can always roll back if something goes wrong. Safety backups are stored in `UserData/.backup_safety/`.

---

## Updating the App

1. Go to **Settings**
2. Click **Check for Updates**
3. If an update is available, click **Download & Install**
4. The app restarts automatically with the new version

Your `UserData` folder is preserved during updates.

---

## Building from Source

### Requirements

- Flutter SDK >= 3.0.0
- Windows 10 or 11

### Build & Run

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

If you find this tool helpful, consider supporting its development:

**[Support via PayPal](https://www.paypal.com/paypalme/ivburic)**

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

**Version**: 1.2.0
**Author**: Ivan Buric
