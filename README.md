# MyJob

A comprehensive job application management tool with CV and cover letter creation.

## 🌟 Features

### 📝 Bilingual Profile Management
- Maintain separate **English** and **German** profiles
- Fill out your master profile once, use it for all applications
- Edit and customize for each job application

### 📊 Job Application Tracking
- Track all your job applications in one place
- Monitor application status (Draft, Applied, Interview, Accepted, Rejected)
- Add notes, salary expectations, and contact information
- Time-based filtering (last 7/30/90 days)

### 📓 Notes & Todo System
- Create notes with priorities and tags
- Archive completed notes
- Search by title, description, or tags
- Collapsible sections for better organization

### 📄 Professional PDF Generation
- Generate CVs with multiple templates
- Create tailored cover letters
- Customize colors, fonts, and layout
- Live preview before export

### 💾 Backup & Restore
- Create backup ZIP files of all your data
- Restore from backup with one click
- Portable design - move your data anywhere

### 🎨 Customizable Interface
- Multiple accent colors (Blue, Green, Cyan, Orange, Red)
- Dark and Light mode support
- Modern Material Design 3 interface

---

## 🚀 Getting Started

### Requirements
- **Flutter SDK** >=3.0.0
- **Windows** (primary target platform)
- Dart SDK >=3.0.0

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/MyJob.git
   cd MyJob
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run -d windows
   ```

### Building for Release

Use the provided PowerShell script for a complete release build:

```powershell
.\build-release.ps1
```

This will:
- Build the Windows executable
- Create a release folder structure
- Include the UserData folder
- Package everything for distribution

---

## 📁 User Data Location

All user data is stored in: `<executable_location>/UserData/`

**Folder structure:**
```
UserData/
├── profiles/
│   ├── en/          # English profile
│   └── de/          # German profile
├── applications/    # Job applications
├── notes/           # Notes & todos
├── pdf_presets/     # PDF customizations
└── settings.json    # App settings
```

**Portable by design**: Simply move the entire application folder (including UserData) to backup or transfer to another computer.

---

## 🏗️ Project Structure

```
lib/
├── constants/       # App-wide constants (colors, spacing, etc.)
├── dialogs/         # Reusable dialog components
├── models/          # Data models (Job, Profile, Notes, etc.)
├── providers/       # State management (Provider pattern)
├── screens/         # Main application screens
├── services/        # Business logic & data persistence
├── theme/           # Design system & theming
├── utils/           # Helper utilities
└── widgets/         # Reusable UI components
```

---

## 🔧 Technologies Used

- **Flutter** - Cross-platform UI framework
- **Provider** - State management
- **PDF Package** - PDF generation
- **Window Manager** - Custom titlebar & window controls
- **YAML** - Data import/export
- **Material Design 3** - Modern UI design

---

## 💡 Usage Tips

### First Time Setup

1. **Start with the Profile tab** - Fill out your master profile data
2. Add your work experience, education, skills, and languages
3. Create your first job application
4. Customize the CV content for each application
5. Generate and preview your PDF

### Profile Warning System

When creating a new job application with an empty profile, you'll see a helpful warning guiding you to fill out your Profile tab first.

### Notes Feature

- Use **tags** to organize notes
- **Archive** completed notes to keep your workspace clean
- Use **search** to quickly find notes
- Filter by type: To-Do, Company Lead, General Note, Reminder

---

## 🛠️ Backup & Restore

### Creating a Backup

1. Go to **Settings** → **Data Management**
2. Select a backup destination folder
3. Click **"Create Backup Zip"**
4. Your backup will be saved with a timestamp

### Restoring from Backup

1. Go to **Settings** → **Data Management**
2. Click **"Restore Zip"**
3. Select your backup file
4. Confirm the restore (⚠️ This will overwrite current data)
5. Restart the application

---

## 🐛 Troubleshooting

### App won't start
- Ensure you have Flutter SDK installed
- Run `flutter doctor` to check your setup

### Data not saving
- Check that the UserData folder exists next to the executable
- Ensure you have write permissions

### PDF generation fails
- Verify all required fields are filled
- Check that fonts are properly loaded

---

## 🤝 Contributing

This is a personal project, but suggestions and feedback are welcome!

If you encounter bugs or have feature requests, please open an issue.

---

## 💖 Support

Made with ❤️ for you to enjoy.

If you find this tool helpful, please consider supporting the development:

**[Support via PayPal](https://www.paypal.com/paypalme/ivburic)**

---

## 📄 License

[Specify your license here - MIT, GPL, etc.]

---

## 📧 Contact

For questions or support, reach out via GitHub issues.

---

## 🗺️ Roadmap

### v1.1 (Future)
- Additional CV templates
- Email integration
- Application deadline reminders
- Statistics dashboard

---

**Version**: 1.0.0  
**Last Updated**: January 2026
