// API Configuration Template
// This file shows the structure for API keys
// Create a copy as 'lib/config/api_keys.dart' with your actual keys

class ApiKeys {
  // Gemini AI API Key
  // Get your API key from: https://makersuite.google.com/app/apikey
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'YOUR_GEMINI_API_KEY_HERE',
  );
}
