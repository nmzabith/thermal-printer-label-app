# Thermal Printer Label App

A Flutter-based Android application for creating and printing shipping labels using thermal printers (specifically optimized for XPrinter XP-365B).

## Features

- 📦 **Shipping Label Management**: Create, edit, and manage shipping labels with TO/FROM information
- 🖨️ **Thermal Printer Support**: Direct Bluetooth connection to TSC/TSPL compatible thermal printers
- 🤖 **AI-Powered Text Extraction**: Automatically extract shipping information using Google Gemini AI
- 🎨 **Visual Label Designer**: Drag-and-drop interface for custom label layouts
- 🏢 **Logo Support**: Add company logos to labels (bottom right corner)
- 📱 **Contact Management**: Save and reuse FROM contacts for quick label creation
- ⚙️ **Customizable Settings**: Configure label sizes, fonts, and print parameters
- 📋 **Print Sessions**: Organize labels into sessions for batch printing

## Prerequisites

- Flutter SDK (3.0.0 or higher)
- Android SDK
- Android device or emulator (Android 6.0+)
- XPrinter XP-365B or compatible TSC/TSPL thermal printer

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/printer_app_v2.git
cd printer_app_v2
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure API Keys

The app uses Google Gemini AI for automatic text extraction. You'll need to set up your API key:

#### Option A: Environment Variable (Recommended for Development)

Create a `.env` file in the project root:

```bash
cp .env.example .env
```

Edit `.env` and add your Gemini API key:

```
GEMINI_API_KEY=your_actual_api_key_here
```

#### Option B: Build-time Configuration

Run the app with the environment variable:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_actual_api_key_here
```

#### Get Your Gemini API Key

1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the generated key and use it in your configuration

## Building the App

### Debug Build

```bash
flutter build apk --debug
```

### Release Build

```bash
flutter build apk --release --dart-define=GEMINI_API_KEY=your_api_key
```

Or with APK split per ABI (smaller file sizes):

```bash
flutter build apk --split-per-abi --release --dart-define=GEMINI_API_KEY=your_api_key
```

## Running the App

### Development Mode

```bash
flutter run --dart-define=GEMINI_API_KEY=your_api_key
```

## Security Notes

⚠️ **Important**: Never commit API keys to version control!

- `.env` files are gitignored
- `lib/config/api_keys.dart` is gitignored
- Use environment variables for sensitive data
- Always use `--dart-define` for build-time configuration

## Troubleshooting

### Printer Connection Issues

1. Ensure Bluetooth is enabled on your device
2. Pair the printer in Android Bluetooth settings first
3. Check printer is powered on and has paper loaded
4. Try the "Quick Test" in Printer Settings to verify connection

### API Key Issues

- Verify your Gemini API key is valid
- Check you're passing the key correctly via `--dart-define`
- Check for API quota limits in Google Cloud Console

## License

This project is licensed under the MIT License.

---

**Built with Flutter 💙**
