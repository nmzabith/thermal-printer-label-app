import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/contact_info.dart';
import '../models/shipping_label.dart';
import 'gemini_model_rotation_service.dart';

class GeminiAiService {
  // Model rotation service for handling rate limits
  final GeminiModelRotationService _modelRotation =
      GeminiModelRotationService();

  // Get API key from .env file
  String get _apiKey {
    try {
      final key = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (key.isEmpty) {
        print(
            'ERROR: GEMINI_API_KEY is empty. Make sure .env file exists and contains the key.');
      }
      return key;
    } catch (e) {
      print('ERROR accessing dotenv: $e');
      print(
          'Make sure to rebuild the app (not just hot restart) after adding .env file');
      return '';
    }
  }

  /// Extract shipping label information from pasted text using Gemini AI
  Future<ShippingLabel?> extractShippingInfo(String text) async {
    try {
      final response = await _makeGeminiRequestWithRetry(text);
      if (response != null) {
        return _parseGeminiResponse(response);
      }
      return null;
    } catch (e) {
      print('Error extracting shipping info: $e');
      return null;
    }
  }

  /// Make request to Gemini AI with retry logic for incomplete responses
  Future<Map<String, dynamic>?> _makeGeminiRequestWithRetry(String text,
      {int maxRetries = 2}) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      final response = await _makeGeminiRequest(text, attempt: attempt + 1);

      if (response != null) {
        // Validate response completeness
        if (_isResponseComplete(response)) {
          return response;
        } else {
          print('Incomplete response on attempt ${attempt + 1}, retrying...');
          if (attempt < maxRetries) {
            // Wait a bit before retrying
            await Future.delayed(Duration(milliseconds: 500));
          }
        }
      }
    }

    // If all retries failed, return the last response (might be incomplete)
    return await _makeGeminiRequest(text, attempt: maxRetries + 1);
  }

  /// Validate if the response contains both TO and FROM information
  bool _isResponseComplete(Map<String, dynamic> response) {
    if (response['to_info'] == null) return false;
    if (response['from_info'] == null) return false;

    final toInfo = response['to_info'];
    final fromInfo = response['from_info'];

    // Check if TO info has at least name and address
    final hasToInfo = toInfo['name'] != null &&
        toInfo['name'].toString().trim().isNotEmpty &&
        toInfo['address'] != null &&
        toInfo['address'].toString().trim().isNotEmpty;

    // Check if FROM info has at least name (address can be empty)
    final hasFromInfo = fromInfo['name'] != null &&
        fromInfo['name'].toString().trim().isNotEmpty;

    return hasToInfo && hasFromInfo;
  }

  /// Make request to Gemini AI with structured output schema
  /// Automatically handles rate limits by switching models
  Future<Map<String, dynamic>?> _makeGeminiRequest(String text,
      {int attempt = 1}) async {
    // Get current best available model
    final modelName = await _modelRotation.getCurrentModel();
    final baseUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent';

    print('Using Gemini model: $modelName (attempt $attempt)');

    final requestBody = {
      "contents": [
        {
          "parts": [
            {
              "text":
                  """Extract shipping label information from the following text and return BOTH TO and FROM information.

IMPORTANT: You must extract BOTH sender (FROM) and recipient (TO) information. If the text contains multiple addresses or contacts, identify which is the sender and which is the recipient.

${attempt > 1 ? 'RETRY ATTEMPT $attempt: Please ensure you provide COMPLETE information for both TO and FROM sections.' : ''}

Guidelines:
1. Look for explicit labels like "TO:", "FROM:", "SENDER:", "RECIPIENT:", "SHIP TO:", "RETURN ADDRESS:"
2. If no explicit labels, use context clues:
   - First address mentioned might be recipient (TO)
   - Look for business names or return addresses (FROM)
   - If there are 2 addresses, typically first is TO, second is FROM
3. If only one complete address is found, use it as TO and create a minimal FROM entry with at least a name
4. Extract names, complete addresses, and phone numbers for both TO and FROM
5. Both to_info and from_info sections are REQUIRED - do not omit either one
6. If information is missing, leave the field empty
7. Format the information like Name, Address, Phone Number 1, Phone Number 2

Text to analyze:
$text

Return the information in the exact JSON format specified, ensuring both to_info and from_info are present."""
            }
          ]
        }
      ],
      "generationConfig": {
        "response_mime_type": "application/json",
        "response_schema": {
          "type": "object",
          "properties": {
            "to_info": {
              "type": "object",
              "properties": {
                "name": {
                  "type": "string",
                  "description": "Recipient's full name"
                },
                "address": {
                  "type": "string",
                  "description": "Complete shipping address"
                },
                "phone_number_1": {
                  "type": "string",
                  "description": "Primary phone number"
                },
                "phone_number_2": {
                  "type": "string",
                  "description": "Secondary phone number"
                }
              },
              "required": ["name", "address"]
            },
            "from_info": {
              "type": "object",
              "properties": {
                "name": {"type": "string", "description": "Sender's full name"},
                "address": {
                  "type": "string",
                  "description": "Complete return address"
                },
                "phone_number_1": {
                  "type": "string",
                  "description": "Primary phone number"
                },
                "phone_number_2": {
                  "type": "string",
                  "description": "Secondary phone number"
                }
              },
              "required": ["name", "address"]
            }
          },
          "required": ["to_info", "from_info"],
          "propertyOrdering": ["to_info", "from_info"]
        }
      }
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        // Success - increment request count
        await _modelRotation.incrementRequestCount(modelName);

        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['candidates'] != null &&
            jsonResponse['candidates'].isNotEmpty &&
            jsonResponse['candidates'][0]['content'] != null &&
            jsonResponse['candidates'][0]['content']['parts'] != null &&
            jsonResponse['candidates'][0]['content']['parts'].isNotEmpty) {
          final textResponse =
              jsonResponse['candidates'][0]['content']['parts'][0]['text'];
          print('Gemini response text: $textResponse'); // Debug log
          return jsonDecode(textResponse);
        } else {
          print('Invalid response structure: $jsonResponse');
        }
      } else if (response.statusCode == 429) {
        // Rate limit hit - mark model and retry with next available model
        print('Rate limit hit for model: $modelName');
        await _modelRotation.markModelRateLimited(modelName);

        // Get next available model and retry
        final nextModel = await _modelRotation.getCurrentModel();
        if (nextModel != modelName) {
          print('Switching to model: $nextModel');
          // Recursive retry with new model
          return await _makeGeminiRequest(text, attempt: attempt);
        } else {
          print('All models are rate limited. Please try again later.');
          final resetTime = await _modelRotation.getNextResetTimeFormatted();
          print('Rate limits reset at: $resetTime');
        }
      } else {
        print('Gemini API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Request error: $e');
    }

    return null;
  }

  /// Parse Gemini response into ShippingLabel
  ShippingLabel _parseGeminiResponse(Map<String, dynamic> response) {
    final label = ShippingLabel.empty();

    print('Parsing Gemini response: ${jsonEncode(response)}'); // Debug log

    // Parse TO information
    if (response['to_info'] != null) {
      final toInfo = response['to_info'];
      label.toInfo = ContactInfo(
        name: toInfo['name'] ?? '',
        address: toInfo['address'] ?? '',
        phoneNumber1: toInfo['phone_number_1'] ?? '',
        phoneNumber2: toInfo['phone_number_2'] ?? '',
      );
      print('Parsed TO info: ${label.toInfo.name} - ${label.toInfo.address}');
    } else {
      print('Warning: No to_info found in response');
    }

    // Parse FROM information
    if (response['from_info'] != null) {
      final fromInfo = response['from_info'];
      label.fromInfo = ContactInfo(
        name: fromInfo['name'] ?? '',
        address: fromInfo['address'] ?? '',
        phoneNumber1: fromInfo['phone_number_1'] ?? '',
        phoneNumber2: fromInfo['phone_number_2'] ?? '',
      );
      print(
          'Parsed FROM info: ${label.fromInfo.name} - ${label.fromInfo.address}');
    } else {
      print('Warning: No from_info found in response');
      // Create a placeholder FROM info to indicate missing data
      label.fromInfo = ContactInfo(
        name: 'Not specified',
        address: '',
        phoneNumber1: '',
        phoneNumber2: '',
      );
    }

    // Log completeness status
    final isComplete = _isResponseComplete(response);
    print('Response completeness check: $isComplete');

    return label;
  }
}
