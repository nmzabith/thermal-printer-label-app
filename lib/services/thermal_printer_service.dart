import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/shipping_label.dart';
import '../models/label_config.dart';
import '../models/font_settings.dart';
import '../models/logo_config.dart';
import '../models/logo_data.dart';
import 'label_config_service.dart';
import 'font_settings_service.dart';
import 'logo_service.dart';

/// Thermal Printer Service using bluetooth_print_plus with TSC/TSPL commands
/// Designed specifically for XPrinter XP-365B thermal label printer
class ThermalPrinterService {
  static final ThermalPrinterService _instance =
      ThermalPrinterService._internal();
  factory ThermalPrinterService() => _instance;
  ThermalPrinterService._internal();

  BluetoothDevice? _selectedDevice;
  late StreamSubscription<ConnectState> _connectStateSubscription;
  late StreamSubscription<List<BluetoothDevice>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;
  late StreamSubscription<BlueState> _blueStateSubscription;

  bool _isConnected = false;
  bool _isConnecting = false;
  DateTime? _lastSuccessfulPrint;

  // TSC Command instances for different command types
  final tscCommand = TscCommand();
  final cpclCommand = CpclCommand();
  final escCommand = EscCommand();

  /// Initialize service and set up listeners
  Future<void> initialize() async {
    _setupBluetoothListeners();
  }

  /// Set up Bluetooth state listeners
  void _setupBluetoothListeners() {
    // Listen to connection state changes
    _connectStateSubscription = BluetoothPrintPlus.connectState.listen((state) {
      print('Connection state changed: $state');
      _isConnected = (state == ConnectState.connected);
      if (state == ConnectState.connected) {
        _lastSuccessfulPrint = DateTime.now();
      }
    });

    // Listen to Bluetooth adapter state
    _blueStateSubscription = BluetoothPrintPlus.blueState.listen((state) {
      print('Bluetooth state changed: $state');
    });

    // Listen to scanning state
    _isScanningSubscription = BluetoothPrintPlus.isScanning.listen((scanning) {
      print('Scanning state changed: $scanning');
    });
  }

  /// Check if currently connected to a printer
  Future<bool> get isConnected async {
    return BluetoothPrintPlus.isConnected && _selectedDevice != null;
  }

  /// Get current printer status
  Future<Map<String, dynamic>> getPrinterStatus() async {
    bool connected = await isConnected;
    return {
      'connected': connected,
      'printer_name': _selectedDevice?.name ?? 'None',
      'printer_address': _selectedDevice?.address ?? 'None',
      'last_print_time': _lastSuccessfulPrint?.toIso8601String() ?? 'Never',
    };
  }

  /// Get detailed connection status for UI display
  Map<String, dynamic> getConnectionStatus() {
    return {
      'isConnected': _isConnected && BluetoothPrintPlus.isConnected,
      'isConnecting': _isConnecting,
      'deviceName': _selectedDevice?.name ?? 'None',
      'deviceAddress': _selectedDevice?.address ?? 'None',
      'lastSuccessfulPrint': _lastSuccessfulPrint?.toIso8601String(),
      'connectionHealth': _isConnected && BluetoothPrintPlus.isConnected
          ? 'Good'
          : _isConnecting
              ? 'Connecting'
              : 'Disconnected',
    };
  }

  /// Quick connection health check without reconnection attempts
  bool get isConnectionHealthy =>
      _isConnected && BluetoothPrintPlus.isConnected;

  /// Check and request Bluetooth permissions
  Future<bool> checkBluetoothPermissions() async {
    try {
      Map<Permission, PermissionStatus> permissions = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      bool allGranted = permissions.values
          .every((status) => status == PermissionStatus.granted);

      print('Bluetooth permissions granted: $allGranted');
      return allGranted;
    } catch (e) {
      print('Error requesting Bluetooth permissions: $e');
      return false;
    }
  }

  /// Discover nearby Bluetooth devices
  Future<List<BluetoothDevice>> discoverPrinters() async {
    try {
      print('Starting printer discovery...');

      bool permissionsGranted = await checkBluetoothPermissions();
      if (!permissionsGranted) {
        throw Exception('Bluetooth permissions not granted');
      }

      await BluetoothPrintPlus.startScan(timeout: const Duration(seconds: 10));

      Completer<List<BluetoothDevice>> completer = Completer();

      _scanResultsSubscription =
          BluetoothPrintPlus.scanResults.listen((devices) {
        if (!completer.isCompleted) {
          completer.complete(devices);
        }
      });

      List<BluetoothDevice> devices = await completer.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () => [],
      );

      print('Found ${devices.length} Bluetooth devices');
      return devices;
    } catch (e) {
      print('Error discovering printers: $e');
      return [];
    }
  }

  /// Get all paired Bluetooth devices
  Future<List<BluetoothDevice>> getAllDevices() async {
    try {
      return await discoverPrinters();
    } catch (e) {
      print('Error getting all devices: $e');
      return [];
    }
  }

  /// Connect to a selected Bluetooth printer
  Future<bool> connectToPrinter(BluetoothDevice device) async {
    if (_isConnecting) {
      print('Connection already in progress');
      return false;
    }

    try {
      _isConnecting = true;
      print('Connecting to printer: ${device.name} (${device.address})');

      // First disconnect any existing connection and wait longer
      await BluetoothPrintPlus.disconnect();
      await Future.delayed(
          const Duration(milliseconds: 1000)); // Increased delay

      // Clear any previous connection state
      _selectedDevice = null;
      _isConnected = false;

      print('Attempting connection...');
      // Connect to the device with timeout
      await BluetoothPrintPlus.connect(device).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Connection timeout', const Duration(seconds: 10));
        },
      );

      // Wait for connection to stabilize with more thorough checking
      bool connectionEstablished = false;
      print('Waiting for connection to stabilize...');

      for (int attempt = 0; attempt < 15; attempt++) {
        await Future.delayed(const Duration(milliseconds: 500));

        // Check connection state
        bool isConnectedNow = BluetoothPrintPlus.isConnected;
        print('Connection check attempt ${attempt + 1}/15: $isConnectedNow');

        if (isConnectedNow) {
          // Double-check with a small delay
          await Future.delayed(const Duration(milliseconds: 200));
          if (BluetoothPrintPlus.isConnected) {
            connectionEstablished = true;
            print('Connection confirmed as stable');
            break;
          } else {
            print('Connection became unstable, continuing to wait...');
          }
        }
      }

      if (connectionEstablished) {
        _selectedDevice = device;
        _isConnected = true;
        _lastSuccessfulPrint = DateTime.now();
        print('Successfully connected to printer - performing connection test');

        // Send a simple initialization command and test response
        try {
          // Send a safe command that shouldn't print anything
          String testCommand = 'STATUS\r\n'; // Query printer status
          Uint8List testBytes = Uint8List.fromList(testCommand.codeUnits);
          await BluetoothPrintPlus.write(testBytes);
          await Future.delayed(const Duration(milliseconds: 300));

          // If we got here without exception, connection is stable
          print('Printer connection test successful');
        } catch (e) {
          print('Warning: Printer test failed but connection seems stable: $e');
          // Don't fail the connection for this, printer might not support STATUS
        }

        // Final stability check
        await Future.delayed(const Duration(milliseconds: 500));
        if (BluetoothPrintPlus.isConnected) {
          print('Final connection stability check: PASSED');
          return true;
        } else {
          print('Final connection stability check: FAILED');
          _selectedDevice = null;
          _isConnected = false;
          return false;
        }
      } else {
        print('Connection failed - printer not responding after 15 attempts');
        _selectedDevice = null;
        _isConnected = false;
        await BluetoothPrintPlus.disconnect();
        return false;
      }
    } catch (e) {
      print('Error connecting to printer: $e');
      _isConnected = false;
      _selectedDevice = null;
      try {
        await BluetoothPrintPlus.disconnect();
      } catch (disconnectError) {
        print('Error during cleanup disconnect: $disconnectError');
      }
      return false;
    } finally {
      _isConnecting = false;
    }
  }

  /// Check connection health and attempt to reconnect if needed
  Future<bool> _ensureConnection() async {
    if (!BluetoothPrintPlus.isConnected || !_isConnected) {
      print('Connection lost, checking if we can reconnect...');

      if (_selectedDevice != null) {
        print(
            'Attempting to reconnect to previous device: ${_selectedDevice!.name}');
        _isConnected = false;

        // Try to reconnect
        bool reconnected = await connectToPrinter(_selectedDevice!);
        if (reconnected) {
          print('Successfully reconnected to printer');
          return true;
        } else {
          print('Failed to reconnect to printer');
          return false;
        }
      } else {
        print('No previous device to reconnect to');
        _isConnected = false;
        return false;
      }
    }

    // Connection seems good, but let's do a health check
    try {
      // Send a minimal command that shouldn't affect printing
      Uint8List healthCheck = Uint8List.fromList([27]); // ESC character
      await BluetoothPrintPlus.write(healthCheck);
      await Future.delayed(const Duration(milliseconds: 100));

      // If we got here, connection is healthy
      return BluetoothPrintPlus.isConnected;
    } catch (e) {
      print('Connection health check failed: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Verify connection with simple TSC test
  /// Used for the test buttons - sends actual commands to printer
  Future<bool> _verifyConnectionWithTest() async {
    try {
      if (_selectedDevice == null || !BluetoothPrintPlus.isConnected) {
        return false;
      }

      await tscCommand.cleanCommand();
      await tscCommand.size(width: 80, height: 60);
      await tscCommand.cls();

      await tscCommand.text(content: "Connection Test", x: 10, y: 10);

      await tscCommand.print(1);

      final cmd = await tscCommand.getCommand();
      if (cmd == null) return false;

      BluetoothPrintPlus.write(cmd);
      await Future.delayed(const Duration(seconds: 2));

      print('TSC connection test sent successfully');
      return true;
    } catch (e) {
      print('Connection verification test failed: $e');
      return false;
    }
  }

  /// Disconnect from current printer
  Future<bool> disconnectPrinter() async {
    try {
      print('Disconnecting from printer...');
      _isConnecting = false; // Clear any connecting state

      // Force disconnect regardless of current state
      await BluetoothPrintPlus.disconnect();
      await Future.delayed(
          const Duration(milliseconds: 500)); // Give time for cleanup

      // Clear all connection state
      _selectedDevice = null;
      _isConnected = false;
      _lastSuccessfulPrint = null;

      print('Successfully disconnected from printer - all state cleared');
      return true;
    } catch (e) {
      print('Error disconnecting printer: $e');
      // Clear state anyway
      _selectedDevice = null;
      _isConnected = false;
      _isConnecting = false;
      _lastSuccessfulPrint = null;
      return false;
    }
  }

  /// Quick connection test
  Future<bool> quickConnectionTest() async {
    try {
      if (!_isConnected || _selectedDevice == null) {
        return false;
      }

      await tscCommand.cleanCommand();
      await tscCommand.size(width: 80, height: 50);
      await tscCommand.cls();

      await tscCommand.text(content: "Quick Test OK", x: 10, y: 10);

      await tscCommand.print(1);

      final cmd = await tscCommand.getCommand();
      if (cmd == null) return false;

      BluetoothPrintPlus.write(cmd);

      _lastSuccessfulPrint = DateTime.now();
      return true;
    } catch (e) {
      print('Quick connection test failed: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Full test print with TSC commands
  /// Uses current label configuration for test print
  Future<bool> fullTestPrint() async {
    try {
      if (!_isConnected || _selectedDevice == null) {
        throw Exception('No printer connected');
      }

      print('Starting full test print with TSC commands...');

      // Get current label configuration
      final labelConfig = await LabelConfigService.instance.getCurrentConfig();

      // Build TSC commands manually as strings for better compatibility
      List<String> commands = [];

      // Setup commands
      commands.add(
          'SIZE ${labelConfig.widthMm.toInt()} mm, ${labelConfig.heightMm.toInt()} mm');
      commands.add('GAP ${labelConfig.spacingMm.toInt()} mm, 0 mm');
      commands.add('DIRECTION 0,0'); // 0,0 = normal orientation (not rotated)
      commands.add('REFERENCE 0,0');
      commands.add('OFFSET 0 mm');
      commands.add('SET PEEL OFF');
      commands.add('SET CUTTER OFF');
      commands.add('SET PARTIAL_CUTTER OFF');
      commands.add('SET TEAR ON');
      commands.add('CLS');

      // Convert mm to dots (203 DPI = ~8 dots per mm)
      int yPos = 20; // Start position in dots
      int lineHeight =
          labelConfig.heightMm < 60 ? 30 : 40; // Line spacing in dots

      // Font sizes: "1"=8x12, "2"=12x20, "3"=16x24, "4"=24x32, "5"=32x48
      String titleFont = labelConfig.heightMm >= 80 ? "4" : "3"; // Large title
      String headerFont = "3"; // Medium headers
      String textFont = "2"; // Normal text
      String smallFont = "1"; // Small details

      commands.add('TEXT 20,$yPos,"$titleFont",0,1,1,"TSC TEST PRINT"');
      yPos += lineHeight;

      commands.add('TEXT 20,$yPos,"$headerFont",0,1,1,"XPrinter XP-365B"');
      yPos += lineHeight;

      commands
          .add('TEXT 20,$yPos,"$textFont",0,1,1,"Config: ${labelConfig.name}"');
      yPos += lineHeight;

      String timestamp = DateTime.now().toString().substring(0, 16);
      commands.add('TEXT 20,$yPos,"$textFont",0,1,1,"$timestamp"');
      yPos += lineHeight;

      commands.add(
          'TEXT 20,$yPos,"$smallFont",0,1,1,"Size: ${labelConfig.widthMm.toInt()}mm x ${labelConfig.heightMm.toInt()}mm"');
      yPos += lineHeight;

      commands.add(
          'TEXT 20,$yPos,"$smallFont",0,1,1,"Gap: ${labelConfig.spacingMm.toInt()}mm"');

      // Print command
      commands.add('PRINT 1,1');

      // Combine all commands
      String fullCommand = commands.join('\r\n') + '\r\n';

      // Debug: Print the TSC commands being sent
      print('TSC Commands for Test Print:');
      print('--- START ---');
      print(fullCommand.replaceAll('\r\n', '\n'));
      print('--- END ---');

      // Send to printer
      await BluetoothPrintPlus.write(Uint8List.fromList(fullCommand.codeUnits));

      _lastSuccessfulPrint = DateTime.now();
      print('Full test print completed successfully');
      return true;
    } catch (e) {
      print('Full test print failed: $e');
      return false;
    }
  }

  /// Print shipping labels using TSC commands
  Future<bool> printSelectedLabels(List<ShippingLabel> labels) async {
    try {
      // Check and ensure connection health before printing
      bool connectionHealthy = await _ensureConnection();
      if (!connectionHealthy) {
        throw Exception('Printer connection not available or unstable');
      }

      if (labels.isEmpty) {
        throw Exception('No labels to print');
      }

      print(
          'Connection verified - printing ${labels.length} shipping labels using TSC commands...');

      for (int i = 0; i < labels.length; i++) {
        ShippingLabel label = labels[i];
        print('Printing label ${i + 1}/${labels.length}: ${label.toInfo.name}');

        // Verify connection before each label
        if (i > 0) {
          bool stillConnected = await _ensureConnection();
          if (!stillConnected) {
            print('Connection lost during printing batch');
            throw Exception('Connection lost during printing');
          }
        }

        bool success = await _printSingleShippingLabel(label);
        if (!success) {
          print('Failed to print label ${i + 1}');
          return false;
        }

        if (i < labels.length - 1) {
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      }

      print('All shipping labels printed successfully');
      return true;
    } catch (e) {
      print('Error printing shipping labels: $e');
      return false;
    }
  }

  /// Sanitize text for TSC commands (remove special characters that could break commands)
  String _sanitizeText(String text) {
    return text
        .replaceAll('"', "'") // Replace quotes
        .replaceAll('\r\n', ' ') // Replace newlines
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ')
        .replaceAll(',', ' ') // Replace commas that might break TSC syntax
        .trim();
  }

  /// Get font dimensions in dots for layout calculation
  Map<String, Map<String, int>> _getFontDimensions() {
    // TSC font sizes in dots (width x height) at 203 DPI
    return {
      "1": {"width": 8, "height": 12, "lineSpacing": 15}, // Small
      "2": {"width": 12, "height": 20, "lineSpacing": 24}, // Normal
      "3": {"width": 16, "height": 24, "lineSpacing": 28}, // Medium
      "4": {"width": 24, "height": 32, "lineSpacing": 36}, // Large
      "5": {"width": 32, "height": 48, "lineSpacing": 52}, // Extra Large
    };
  }

  /// Calculate if text fits within given width
  bool _textFitsWidth(String text, String fontId, int maxWidthDots) {
    final fontDims = _getFontDimensions()[fontId];
    if (fontDims == null) return false;

    int textWidthDots = text.length * fontDims["width"]!;
    return textWidthDots <= maxWidthDots;
  }

  /// Get the best font size that fits the text within width constraints
  String _getBestFitFont(
      String text, List<String> fontOptions, int maxWidthDots) {
    // Try fonts from largest to smallest
    for (String font in fontOptions) {
      if (_textFitsWidth(text, font, maxWidthDots)) {
        return font;
      }
    }
    // If nothing fits, return smallest font
    return fontOptions.last;
  }

  /// Calculate total content height to ensure it fits in label
  int _calculateContentHeight(
      ShippingLabel label, LabelConfig labelConfig, FontSettings fontSettings) {
    int totalHeight = 20; // Starting position

    // Get dimensions for different font types
    final titleDims = fontSettings.getTextDimensions('title');
    final subtitleDims = fontSettings.getTextDimensions('subtitle');
    final contentDims = fontSettings.getTextDimensions('content');
    final smallDims = fontSettings.getTextDimensions('small');

    int baseLineSpacing =
        (contentDims['height']! * fontSettings.lineSpacingFactor).round();
    int sectionSpacing = baseLineSpacing;

    // Header (if large label)
    if (labelConfig.heightMm >= 80) {
      totalHeight +=
          (titleDims['height']! * fontSettings.lineSpacingFactor).round() +
              sectionSpacing; // Title
      totalHeight += contentDims['height']!; // Separator
    }

    // TO section
    totalHeight += (subtitleDims['height']! * fontSettings.lineSpacingFactor)
        .round(); // "TO:" header
    totalHeight +=
        (contentDims['height']! * fontSettings.lineSpacingFactor).round() +
            5; // Name (bold) + extra spacing

    // TO Address lines
    if (label.toInfo.address.isNotEmpty) {
      List<String> toAddressLines = _splitAddress(label.toInfo.address,
          maxWidth: fontSettings.maxLinesAddress * 10);
      totalHeight += (toAddressLines.length * (baseLineSpacing - 5)) + 5;
    }

    // TO Phone
    if (label.toInfo.phoneNumber1.isNotEmpty ||
        label.toInfo.phoneNumber2.isNotEmpty) {
      totalHeight +=
          (smallDims['height']! * fontSettings.lineSpacingFactor).round();
    }
    totalHeight += sectionSpacing;

    // FROM section
    totalHeight += (subtitleDims['height']! * fontSettings.lineSpacingFactor)
        .round(); // "FROM:" header
    totalHeight +=
        (contentDims['height']! * fontSettings.lineSpacingFactor).round() +
            5; // Name (bold) + extra spacing

    // FROM Address lines (optional)
    if (label.fromInfo.address.isNotEmpty) {
      List<String> fromAddressLines = _splitAddress(label.fromInfo.address,
          maxWidth: fontSettings.maxLinesAddress * 10);
      totalHeight += (fromAddressLines.length * (baseLineSpacing - 5)) + 5;
    }

    // FROM Phone
    if (label.fromInfo.phoneNumber1.isNotEmpty ||
        label.fromInfo.phoneNumber2.isNotEmpty) {
      totalHeight +=
          (smallDims['height']! * fontSettings.lineSpacingFactor).round();
    }
    totalHeight += sectionSpacing;

    // Label details (if space)
    if (labelConfig.heightMm >= 60) {
      totalHeight +=
          (smallDims['height']! * fontSettings.lineSpacingFactor).round() *
              2; // ID + Date
    }

    return totalHeight;
  }

  /// Get auto-sized font settings when content doesn't fit
  FontSettings _getAutoSizedFontSettings(FontSettings originalSettings,
      ShippingLabel label, LabelConfig labelConfig) {
    // Start with smaller versions of the original settings
    FontSettings candidateSettings = originalSettings.copyWith(
      labelTitleFontSize: (originalSettings.labelTitleFontSize - 1).clamp(1, 8),
      headerFontSize: (originalSettings.headerFontSize - 1).clamp(1, 8),
      nameFontSize: (originalSettings.nameFontSize - 1).clamp(1, 8),
      addressFontSize: (originalSettings.addressFontSize)
          .clamp(1, 8), // Keep address font as is
      phoneFontSize:
          (originalSettings.phoneFontSize).clamp(1, 8), // Keep phone font as is
      lineSpacingFactor:
          (originalSettings.lineSpacingFactor * 0.9).clamp(0.5, 3.0),
    );

    // Check if the adjusted settings fit
    int estimatedHeight =
        _calculateContentHeight(label, labelConfig, candidateSettings);
    int labelHeightDots = (labelConfig.heightMm * 8).toInt();

    if (estimatedHeight <= labelHeightDots - 20) {
      return candidateSettings;
    }

    // If still doesn't fit, make more aggressive reductions
    return candidateSettings.copyWith(
      labelTitleFontSize: (originalSettings.labelTitleFontSize - 2).clamp(1, 8),
      headerFontSize: (originalSettings.headerFontSize - 1).clamp(1, 8),
      nameFontSize: (originalSettings.nameFontSize - 1).clamp(1, 8),
      addressFontSize: (originalSettings.addressFontSize - 1).clamp(1, 8),
      lineSpacingFactor: 0.8,
      maxLinesAddress: (originalSettings.maxLinesAddress - 1).clamp(1, 10),
    );
  }

  /// Split address into multiple lines for better formatting
  /// Handles line breaks and long addresses with width constraint
  List<String> _splitAddress(String address, {int maxWidth = 35}) {
    if (address.isEmpty) return [];

    // First handle explicit line breaks
    List<String> lines = address
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    List<String> finalLines = [];

    for (String line in lines) {
      // If line fits within max width, add it
      if (line.length <= maxWidth) {
        finalLines.add(line);
      } else {
        // Split long lines at logical points
        List<String> words = line.split(' ');
        String currentLine = '';

        for (String word in words) {
          if ((currentLine + ' ' + word).length <= maxWidth) {
            currentLine = currentLine.isEmpty ? word : '$currentLine $word';
          } else {
            if (currentLine.isNotEmpty) {
              finalLines.add(currentLine);
              currentLine = word;
            } else {
              // Single word is too long, truncate it
              finalLines.add(word.substring(0, maxWidth.clamp(1, word.length)));
            }
          }
        }

        if (currentLine.isNotEmpty) {
          finalLines.add(currentLine);
        }
      }
    }

    // Limit to maximum 3 lines for address
    if (finalLines.length > 3) {
      finalLines = finalLines.take(3).toList();
      // Add ellipsis to last line if truncated
      if (finalLines.length == 3 && finalLines[2].length > maxWidth - 3) {
        finalLines[2] = finalLines[2].substring(0, maxWidth - 3) + '...';
      }
    }

    return finalLines;
  }

  /// Print a single shipping label using TSC commands
  /// Uses configurable label dimensions and font settings
  Future<bool> _printSingleShippingLabel(ShippingLabel label) async {
    // Check for beta delivery format
    if (label.useBetaDeliveryFormat) {
      return _printBetaDeliveryLabel(label);
    }

    try {
      // Verify connection is still healthy before printing
      bool connectionHealthy = await _ensureConnection();
      if (!connectionHealthy) {
        print('Connection check failed before printing label ${label.id}');
        return false;
      }

      // Get current configurations
      final labelConfig = await LabelConfigService.instance.getCurrentConfig();
      final fontSettings =
          await FontSettingsService.instance.getCurrentSettings();

      // Build TSC commands manually as strings (more reliable for XPrinter)
      List<String> commands = [];

      // Setup commands
      commands.add(
          'SIZE ${labelConfig.widthMm.toInt()} mm, ${labelConfig.heightMm.toInt()} mm');
      commands.add('GAP ${labelConfig.spacingMm.toInt()} mm, 0 mm');
      commands.add('DIRECTION 0,0'); // 0,0 = normal orientation (not rotated)
      commands.add('REFERENCE 0,0');
      commands.add('OFFSET 0 mm');
      commands.add('SET PEEL OFF');
      commands.add('SET CUTTER OFF');
      commands.add('SET PARTIAL_CUTTER OFF');
      commands.add('SET TEAR ON');
      commands.add('CLS');

      // Calculate available space
      int labelWidthDots =
          (labelConfig.widthMm * 8).toInt(); // Convert mm to dots
      int labelHeightDots = (labelConfig.heightMm * 8).toInt();
      int maxTextWidthDots =
          labelWidthDots - 40; // Margin space (20 dots each side)

      // Check if content fits with current font settings
      int estimatedHeight =
          _calculateContentHeight(label, labelConfig, fontSettings);
      bool contentFits =
          estimatedHeight <= labelHeightDots - 20; // 20 dots bottom margin

      // Use configured fonts or auto-size if enabled and needed
      FontSettings effectiveSettings = fontSettings;
      if (fontSettings.enableAutoSizing && !contentFits) {
        effectiveSettings =
            _getAutoSizedFontSettings(fontSettings, label, labelConfig);
      }

      // Calculate dynamic line spacing
      double lineSpacingFactor = effectiveSettings.lineSpacingFactor;
      if (!contentFits && fontSettings.enableAutoSizing) {
        lineSpacingFactor = (lineSpacingFactor * 0.8)
            .clamp(0.5, lineSpacingFactor); // Reduce spacing if tight
      }

      // Calculate dynamic address width for wrapping
      int maxAddressChars = maxTextWidthDots ~/
          effectiveSettings.getTextDimensions('content')['width']!;

      // Start layout
      int yPos = 20; // Start position in dots

      print('Using font settings: $effectiveSettings');
      print(
          'Label space: ${labelWidthDots}x${labelHeightDots} dots, estimated height: $estimatedHeight, fits: $contentFits');

      // Calculate line spacing values
      final titleDims = effectiveSettings.getTextDimensions('title');
      final subtitleDims = effectiveSettings.getTextDimensions('subtitle');
      final contentDims = effectiveSettings.getTextDimensions('content');
      final smallDims = effectiveSettings.getTextDimensions('small');

      int titleLineHeight = (titleDims['height']! * lineSpacingFactor).round();
      int subtitleLineHeight =
          (subtitleDims['height']! * lineSpacingFactor * 1.5)
              .round(); // Extra space for headers
      int contentLineHeight = (contentDims['height']! * lineSpacingFactor * 1.2)
          .round(); // More space for content
      int smallLineHeight = (smallDims['height']! * lineSpacingFactor).round();
      int sectionSpacing = contentLineHeight;

      // TO section (appears first as per requirement)
      commands.add(
          'TEXT 20,$yPos,${effectiveSettings.getTscFontCommand('header')},"TO:"');
      yPos += subtitleLineHeight + 5; // Extra spacing after header

      // TO Name - Use font settings
      commands.add(
          'TEXT 20,$yPos,${effectiveSettings.getTscFontCommand('name')},"${_sanitizeText(label.toInfo.name)}"');
      yPos += contentLineHeight + 10; // More spacing after name

      // TO Address - handle multiple lines with dynamic width
      if (label.toInfo.address.isNotEmpty) {
        List<String> addressLines =
            _splitAddress(label.toInfo.address, maxWidth: maxAddressChars);
        for (String line in addressLines) {
          commands.add(
              'TEXT 20,$yPos,${effectiveSettings.getTscFontCommand('address')},"${_sanitizeText(line)}"');
          yPos +=
              contentLineHeight - 2; // Tighter spacing between address lines
        }
        yPos += 10; // Larger gap after address
      }

      // TO Phone numbers
      String phoneText = '';
      if (label.toInfo.phoneNumber1.isNotEmpty &&
          label.toInfo.phoneNumber2.isNotEmpty) {
        phoneText =
            'TEL: ${_sanitizeText(label.toInfo.phoneNumber1)} / ${_sanitizeText(label.toInfo.phoneNumber2)}';
      } else if (label.toInfo.phoneNumber1.isNotEmpty) {
        phoneText = 'TEL: ${_sanitizeText(label.toInfo.phoneNumber1)}';
      } else if (label.toInfo.phoneNumber2.isNotEmpty) {
        phoneText = 'TEL: ${_sanitizeText(label.toInfo.phoneNumber2)}';
      }

      if (phoneText.isNotEmpty) {
        commands.add(
            'TEXT 20,$yPos,${effectiveSettings.getTscFontCommand('phone')},"$phoneText"');
        yPos += smallLineHeight;
      }
      yPos += sectionSpacing;

      // FROM section
      commands.add(
          'TEXT 20,$yPos,${effectiveSettings.getTscFontCommand('header')},"FROM:"');
      yPos += subtitleLineHeight + 5; // Extra spacing after header

      // FROM Name - Use font settings
      commands.add(
          'TEXT 20,$yPos,${effectiveSettings.getTscFontCommand('name')},"${_sanitizeText(label.fromInfo.name)}"');
      yPos += contentLineHeight + 10; // More spacing after name

      // FROM Address - Optional, handle multiple lines with dynamic width
      if (label.fromInfo.address.isNotEmpty) {
        List<String> addressLines =
            _splitAddress(label.fromInfo.address, maxWidth: maxAddressChars);
        for (String line in addressLines) {
          commands.add(
              'TEXT 20,$yPos,${effectiveSettings.getTscFontCommand('address')},"${_sanitizeText(line)}"');
          yPos +=
              contentLineHeight - 2; // Tighter spacing between address lines
        }
        yPos += 10; // Larger gap after address
      }

      // FROM Phone numbers
      phoneText = '';
      if (label.fromInfo.phoneNumber1.isNotEmpty &&
          label.fromInfo.phoneNumber2.isNotEmpty) {
        phoneText =
            'TEL: ${_sanitizeText(label.fromInfo.phoneNumber1)} / ${_sanitizeText(label.fromInfo.phoneNumber2)}';
      } else if (label.fromInfo.phoneNumber1.isNotEmpty) {
        phoneText = 'TEL: ${_sanitizeText(label.fromInfo.phoneNumber1)}';
      } else if (label.fromInfo.phoneNumber2.isNotEmpty) {
        phoneText = 'TEL: ${_sanitizeText(label.fromInfo.phoneNumber2)}';
      }

      if (phoneText.isNotEmpty) {
        commands.add(
            'TEXT 20,$yPos,${effectiveSettings.getTscFontCommand('phone')},"$phoneText"');
        yPos += smallLineHeight;
      }
      yPos += sectionSpacing;

      // COD (Cash on Delivery) amount - if enabled (after FROM section)
      if (label.codEnabled && label.codAmount > 0) {
        String codText = 'COD: Rs ${label.codAmount.toStringAsFixed(2)}';
        commands.add(
            'TEXT 20,$yPos,${effectiveSettings.getTscFontCommand('cod')},"$codText"');
        yPos += contentLineHeight + 10; // Extra spacing after COD
      }

      // Footer section: Logo (centered) and Thanks Message (centered below logo)
      // Both are optional - calculate positions based on what's enabled
      await _addFooterToCommands(
          commands, label, labelConfig, labelWidthDots, labelHeightDots);

      // Print command
      commands.add('PRINT 1,1');

      // Combine all commands
      String fullCommand = commands.join('\r\n') + '\r\n';

      // Debug: Print the TSC commands being sent
      print('TSC Commands for Shipping Label ${label.id}:');
      if (!contentFits) {
        print('WARNING: Content may be tight for ${labelConfig.name} label');
        print(
            'Estimated height: ${estimatedHeight} dots, Available: ${labelHeightDots} dots');
      }
      print('--- START ---');
      print(fullCommand.replaceAll('\r\n', '\n'));
      print('--- END ---');

      // Final connection check before sending data
      if (!BluetoothPrintPlus.isConnected) {
        print('Connection lost before sending print data');
        return false;
      }

      // Send to printer with error handling
      print('Sending TSC commands to printer...');
      await BluetoothPrintPlus.write(Uint8List.fromList(fullCommand.codeUnits))
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Print command timeout', const Duration(seconds: 10));
        },
      );

      // Small delay to ensure command is processed
      await Future.delayed(const Duration(milliseconds: 200));

      // Verify connection is still stable after printing
      if (BluetoothPrintPlus.isConnected) {
        print(
            'Shipping label ${label.id} printed successfully with ${labelConfig.widthMm.toInt()}mm × ${labelConfig.heightMm.toInt()}mm format');
        _lastSuccessfulPrint = DateTime.now();
        return true;
      } else {
        print(
            'Warning: Connection lost after sending print command for label ${label.id}');
        _isConnected = false;
        return false;
      }
    } catch (e) {
      print('Error printing single shipping label: $e');
      return false;
    }
  }

  /// Beta Delivery Label Print Method
  /// Targets 80x75mm size specifically with Logo Header and Dividers
  Future<bool> _printBetaDeliveryLabel(ShippingLabel label) async {
    try {
      print('Starting printing for Beta Delivery Label...');
      bool connectionHealthy = await _ensureConnection();
      if (!connectionHealthy) return false;

      // Get current configurations
      final labelConfig = await LabelConfigService.instance.getCurrentConfig();
      final fontSettings =
          await FontSettingsService.instance.getCurrentSettings();

      // TSC Setup based on selected config
      List<String> commands = [];
      commands.add(
          'SIZE ${labelConfig.widthMm.toInt()} mm, ${labelConfig.heightMm.toInt()} mm');
      commands.add('GAP ${labelConfig.spacingMm.toInt()} mm, 0 mm');
      commands.add('DIRECTION 0,0');
      commands.add('REFERENCE 0,0');
      commands.add('OFFSET 0 mm');
      commands.add('CLS');

      // Layout Constants
      final int labelWidth =
          (labelConfig.widthMm * 8).toInt(); // Convert mm to dots
      final int labelHeight = (labelConfig.heightMm * 8).toInt();
      const int margin = 16;
      final int contentWidth = labelWidth - (margin * 2);
      int curY = 20;

      // 1. Header Section: Logo + Shop Name
      final logoService = LogoService();
      final defaultLogo = await logoService.getDefaultLogoConfig();
      if (defaultLogo.shouldShowLogo && label.includeLogo) {
        final logoData = await logoService.processLogoForPrinting(defaultLogo);
        if (logoData != null) {
          final logoBytes = logoData.imageData;
          if (logoBytes.isNotEmpty) {
            final hexData = logoBytes
                .map((b) => b.toRadixString(16).padLeft(2, '0'))
                .join('');
            final widthBytes = (80 + 7) ~/ 8; // 80 dots width
            commands.add('BITMAP $margin,$curY,$widthBytes,80,0,$hexData');
          }
        }
      }
      // Shop Name (Next to Logo)
      // "CF Sri Lanka"
      // "Online Store"
      // Font 3 (Bold approx 12x20), Scaled 1x1
      int textX = margin + 80 + 16; // Logo width + gap
      commands.add('TEXT $textX,${curY + 10},"3",0,1,1,"CF Sri Lanka"');
      commands.add('TEXT $textX,${curY + 40},"3",0,1,1,"Online Store"');

      curY += 90; // Move below header

      // Divider 1
      commands.add('BAR $margin,$curY,$contentWidth,3');
      curY += 15;

      // 2. SHIP FROM Section
      commands.add('TEXT $margin,$curY,"3",0,1,1,"SHIP FROM"');
      curY += 35;

      // FROM Address
      // Use smaller font for address (Font 2 approx 8x12)
      String fromName = _sanitizeText(label.fromInfo.name);
      commands.add('TEXT $margin,$curY,"2",0,1,1,"$fromName"');
      curY += 25;

      if (label.fromInfo.address.isNotEmpty) {
        List<String> fromLines =
            _splitAddress(label.fromInfo.address, maxWidth: 45);
        for (String line in fromLines) {
          commands.add(
              'TEXT $margin,$curY,"2",0,1,1,"${_sanitizeText(line.trim())}"');
          curY += 25;
        }
      }

      // FROM Phone
      String fromPhone = label.fromInfo.phoneNumber1;
      if (fromPhone.isNotEmpty) {
        commands.add('TEXT $margin,$curY,"2",0,1,1,"TEL: $fromPhone"');
        curY += 25;
      }

      curY += 10;
      // Divider 2
      commands.add('BAR $margin,$curY,$contentWidth,3');
      curY += 15;

      // 3. SHIP TO Section
      commands.add('TEXT $margin,$curY,"3",0,1,1,"SHIP TO"');
      curY += 35;

      // TO Name
      String toName = _sanitizeText(label.toInfo.name);
      // Font 3 for recipient name
      commands.add('TEXT $margin,$curY,"3",0,1,1,"$toName"');
      curY += 30;

      // TO Address (Full width now that checkmark is gone)
      int addressMaxWidthChars = 45; // Increased width

      if (label.toInfo.address.isNotEmpty) {
        List<String> toLines =
            _splitAddress(label.toInfo.address, maxWidth: addressMaxWidthChars);
        for (String line in toLines) {
          commands.add(
              'TEXT $margin,$curY,"2",0,1,1,"${_sanitizeText(line.trim())}"');
          curY += 25;
        }
      }

      // TO Phone
      String toPhone = label.toInfo.phoneNumber1;
      if (toPhone.isNotEmpty) {
        commands.add('TEXT $margin,$curY,"2",0,1,1,"TEL: $toPhone"');
        curY += 25;
      }

      // COD (Moved inside SHIP TO section)
      if (label.codEnabled) {
        String codText = 'COD: Rs ${label.codAmount.toStringAsFixed(2)}';
        commands.add(
            'TEXT $margin,$curY,${fontSettings.getTscFontCommand('cod')},"$codText"');
        curY += 35;
      }

      curY += 20; // Spacing after section

      // 5. Footer: Thanks Message
      // Align bottom relative to label height
      int footerY = labelHeight - 80; // Position slightly lower as COD is gone
      if (footerY < curY) footerY = curY + 20;

      // Divider line above footer
      commands.add('BAR $margin,$footerY,$contentWidth,2');
      footerY += 10;

      // Thanks Message
      if (label.includeThanksMessage) {
        String msg = defaultLogo.thanksMessage;
        if (msg.trim().isEmpty) msg = 'Thanks for shopping!';

        // Center text calculation
        // TSPL Font 3 is exactly 16 dots wide per character
        int charWidth = 16;
        int textLenPts = msg.length * charWidth;
        int centerX = (labelWidth - textLenPts) ~/ 2;

        print('DEBUG (Beta): Thanks Msg="$msg" (len=${msg.length})');
        print(
            'DEBUG (Beta): TextWidth=$textLenPts, LabelWidth=$labelWidth, Calc CenterX=$centerX');

        // Improve centering by ensuring margin
        if (centerX < margin) centerX = margin;

        commands.add('TEXT $centerX,$footerY,"3",0,1,1,"$msg"');
      }

      commands.add('PRINT 1,1');

      String fullCommand = commands.join('\r\n') + '\r\n';
      print('--- BETA DELIVERY LABEL COMMANDS ---');
      print(fullCommand);

      // Send to printer
      await BluetoothPrintPlus.write(Uint8List.fromList(fullCommand.codeUnits));
      await Future.delayed(const Duration(milliseconds: 500)); // Wait for print

      return true;
    } catch (e) {
      print('Error in beta delivery label print: $e');
      return false;
    }
  }

  /// Add footer section to label: Logo (centered) and Thanks Message (centered)
  /// Layout: Logo above Thanks Message when both enabled, both centered
  ///
  /// TSC Coordinate System:
  /// - Origin (0,0) is at TOP-LEFT corner
  /// - X increases to the right
  /// - Y increases DOWNWARD
  /// - Position specified is always TOP-LEFT corner of element
  Future<void> _addFooterToCommands(List<String> commands, ShippingLabel label,
      LabelConfig labelConfig, int labelWidthDots, int labelHeightDots) async {
    try {
      final logoService = LogoService();

      // Get logo config if logo is enabled
      LogoConfig? logoConfig;
      Uint8List? logoBytes;
      int logoWidthDots = 0;
      int logoHeightDots = 0;

      if (label.includeLogo) {
        if (label.fromInfo.hasLogo) {
          logoConfig = label.fromInfo.logoConfig!;
        } else {
          logoConfig = await logoService.getDefaultLogoConfig();
        }

        if (logoConfig != null && logoConfig.shouldShowLogo) {
          final logoData = await logoService.processLogoForPrinting(logoConfig);
          if (logoData != null) {
            // Limit logo size to max 80x80 dots (10mm x 10mm)
            final maxLogoDots = 80;
            logoWidthDots =
                (logoConfig.width * 8).toInt().clamp(8, maxLogoDots);
            logoHeightDots =
                (logoConfig.height * 8).toInt().clamp(8, maxLogoDots);
            logoBytes = logoData.imageData;
          }
        }
      }

      // Get thanks message if enabled
      String? thanksMessage;
      if (label.includeThanksMessage) {
        final defaultLogoConfig = await logoService.getDefaultLogoConfig();
        if (defaultLogoConfig != null &&
            defaultLogoConfig.thanksMessageEnabled) {
          thanksMessage = defaultLogoConfig.thanksMessage;
          if (thanksMessage.isEmpty) thanksMessage = null;
        }
      }

      // Layout constants
      const int bottomMargin =
          20; // margin from bottom of label in dots (~2.5mm)
      const int messageHeight =
          20; // approximate height for thanks message text
      const int logoToMsgGap = 8; // gap between logo and message

      // Calculate total footer height first to determine starting Y
      int footerHeight = 0;

      if (thanksMessage != null) {
        footerHeight += messageHeight;
      }
      if (logoBytes != null && logoBytes.isNotEmpty) {
        if (footerHeight > 0)
          footerHeight += logoToMsgGap; // add gap if message exists
        footerHeight += logoHeightDots;
      }

      // Calculate where footer starts (top of footer area)
      // Footer bottom edge: labelHeightDots - bottomMargin
      // Footer top edge: labelHeightDots - bottomMargin - footerHeight
      int footerTopY = labelHeightDots - bottomMargin - footerHeight;

      // Ensure footer doesn't go into negative Y
      if (footerTopY < 100) {
        print('Warning: Footer would overlap content area, adjusting position');
        footerTopY = 100; // Minimum Y to prevent overlap with content
      }

      int currentY = footerTopY;

      // Add Logo first (at top of footer, centered horizontally)
      if (logoBytes != null && logoBytes.isNotEmpty) {
        final bytesPerRow = (logoWidthDots + 7) ~/ 8;

        // Calculate centered X position for logo
        // X = (labelWidth - logoWidth) / 2
        final logoX = ((labelWidthDots - logoWidthDots) / 2).toInt();
        final logoY = currentY;

        // Validate positions
        if (logoY >= 0 &&
            logoX >= 0 &&
            logoX + logoWidthDots <= labelWidthDots) {
          // TODO: Fix logo printing using same approach as image printing
          // For now, using hex encoding (produces vertical lines)
          final hexData = logoBytes
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join('');
          commands.add(
              'BITMAP $logoX,$logoY,$bytesPerRow,$logoHeightDots,0,$hexData');
          print(
              'Added logo at ($logoX,$logoY) size ${logoWidthDots}x${logoHeightDots} dots');

          currentY += logoHeightDots + logoToMsgGap; // Move down for message
        } else {
          print(
              'Logo position out of bounds: x=$logoX, y=$logoY - skipping logo');
        }
      }

      // Add Thanks Message below logo (or at footer top if no logo), centered
      if (thanksMessage != null) {
        // Calculate centered X position for text
        // TSPL Font 3 is exactly 16 dots wide per character
        final charWidth = 16;
        final textWidthDots = thanksMessage.length * charWidth;
        final msgX = ((labelWidthDots - textWidthDots) / 2).toInt();
        final msgY = currentY;

        // Ensure X is within bounds
        final clampedMsgX = msgX.clamp(5, labelWidthDots - textWidthDots - 5);

        // TSC TEXT command: TEXT x,y,font,rotation,h-mult,v-mult,text
        // Font 3 = 8x16 alphanumeric? No, typically 12x20.
        commands.add(
            'TEXT $clampedMsgX,$msgY,"3",0,1,1,"${_sanitizeText(thanksMessage)}"');
        print('Added thanks message at ($clampedMsgX,$msgY): "$thanksMessage"');
      }
    } catch (e) {
      print('Error adding footer to label: $e');
      // Don't throw - continue printing without footer
    }
  }

  /// Add logo to TSC commands for label printing
  /// Places logo in the bottom right corner of the label
  Future<void> _addLogoToCommands(List<String> commands, ShippingLabel label,
      LabelConfig labelConfig) async {
    try {
      final logoService = LogoService();
      LogoConfig? logoConfig;

      // Determine which logo to use:
      // 1. First check if FROM contact has a specific logo
      if (label.fromInfo.hasLogo) {
        logoConfig = label.fromInfo.logoConfig!;
      } else {
        // 2. Fall back to default logo
        logoConfig = await logoService.getDefaultLogoConfig();
      }

      // If no logo is configured or enabled, skip
      if (logoConfig == null || !logoConfig.shouldShowLogo) {
        print('No logo configured or logo disabled - skipping logo addition');
        return;
      }

      // Process logo for thermal printing
      final logoData = await logoService.processLogoForPrinting(logoConfig);
      if (logoData == null) {
        print('Failed to process logo for printing - skipping logo addition');
        return;
      }

      // Limit logo size to prevent printer freeze (max 80x80 dots = 10x10mm)
      final maxLogoDots = 80;
      var logoWidthDots = (logoConfig.width * 8).toInt().clamp(8, maxLogoDots);
      var logoHeightDots =
          (logoConfig.height * 8).toInt().clamp(8, maxLogoDots);

      // Calculate logo position (bottom right corner)
      final labelWidthDots = (labelConfig.widthMm * 8).toInt();
      final labelHeightDots = (labelConfig.heightMm * 8).toInt();

      // Position logo in bottom right corner with margin
      const marginDots = 20; // 2.5mm margin
      final logoX = labelWidthDots - logoWidthDots - marginDots;
      final logoY = labelHeightDots - logoHeightDots - marginDots;

      // Ensure logo doesn't go outside label bounds
      if (logoX < 0 || logoY < 0) {
        print('Logo too large for label - skipping logo addition');
        return;
      }

      // Since LogoService already packs bits (TSPL format), we use them directly
      final bitmapBytes = logoData.imageData;

      if (bitmapBytes.isNotEmpty) {
        // Build BITMAP command with hex encoded data
        final bytesPerRow = (logoWidthDots + 7) ~/ 8;
        final hexData = bitmapBytes
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join('');
        commands.add(
            'BITMAP $logoX,$logoY,$bytesPerRow,$logoHeightDots,0,$hexData');
      } else {
        print(
            'Failed to convert logo to bitmap format - skipping logo addition');
      }
    } catch (e) {
      print('Error adding logo to label: $e');
      // Don't throw - continue printing without logo
    }
  }

  /// Add thanks message to TSC commands for label printing
  /// Centers the message at the bottom of the label
  Future<void> _addThanksMessageToCommands(List<String> commands,
      LabelConfig labelConfig, int labelWidthDots, int labelHeightDots) async {
    try {
      final logoService = LogoService();
      final logoConfig = await logoService.getDefaultLogoConfig();

      // If thanks message is not enabled in logo config, skip
      if (logoConfig == null || !logoConfig.thanksMessageEnabled) {
        print('Thanks message disabled in logo config - skipping');
        return;
      }

      final message = logoConfig.thanksMessage;
      if (message.isEmpty) {
        print('Thanks message is empty - skipping');
        return;
      }

      // Position message at bottom of label (centered)
      // Leave 30 dots from bottom for visibility
      final yPosition = labelHeightDots - 30; // 30 dots from bottom

      // Use TSC font 3 (small font) for thanks message
      // Format: "3",rotation,xmul,ymul
      final tscFont = '"3",0,1,1'; // Font 3, no rotation, normal size

      // Calculate approximate text width for centering
      // Font 3 is approximately 8 dots wide per character
      final charWidth = 8; // Approximate character width in dots for font 3
      final textWidthDots = message.length * charWidth;
      final xPosition = ((labelWidthDots - textWidthDots) / 2)
          .toInt()
          .clamp(10, labelWidthDots - 50);

      // Add centered thanks message
      commands.add(
          'TEXT $xPosition,$yPosition,$tscFont,"${_sanitizeText(message)}"');

      print(
          'Added thanks message at bottom center: "$message" at position ($xPosition, $yPosition)');
    } catch (e) {
      print('Error adding thanks message: $e');
      // Don't fail the print job if thanks message fails
    }
  }

  /// Print image sticker using TSPL BITMAP command
  /// Takes pre-processed bitmap data and prints it centered on the label
  Future<bool> printImageSticker(
    Uint8List bitmapData,
    int width,
    int height,
    LabelConfig labelConfig,
  ) async {
    try {
      // Check and ensure connection health before printing
      bool connectionHealthy = await _ensureConnection();
      if (!connectionHealthy) {
        throw Exception('Printer connection not available or unstable');
      }

      print(
          'Printing image sticker: ${width}x$height on ${labelConfig.name} label');

      // Build TSC commands
      List<String> commands = [];

      // Setup commands
      commands.add(
          'SIZE ${labelConfig.widthMm.toInt()} mm, ${labelConfig.heightMm.toInt()} mm');
      commands.add('GAP ${labelConfig.spacingMm.toInt()} mm, 0 mm');
      commands.add('DIRECTION 0,0'); // Normal orientation
      commands.add('REFERENCE 0,0');
      commands.add('OFFSET 0 mm');
      commands.add('SET PEEL OFF');
      commands.add('SET CUTTER OFF');
      commands.add('SET PARTIAL_CUTTER OFF');
      commands.add('SET TEAR ON');
      commands.add('CLS');

      // Calculate centering position
      final labelWidthDots = (labelConfig.widthMm * 8).toInt();
      final labelHeightDots = (labelConfig.heightMm * 8).toInt();
      final xPos =
          ((labelWidthDots - width) / 2).toInt().clamp(0, labelWidthDots);
      final yPos =
          ((labelHeightDots - height) / 2).toInt().clamp(0, labelHeightDots);

      // Calculate bitmap width in bytes
      final widthBytes = (width + 7) ~/ 8;

      // Use StackOverflow solution: https://stackoverflow.com/questions/76006152/
      // Key: Send BITMAP command as text, then raw binary data, then \r\n
      // Build command as byte array mixing text and binary data

      List<int> commandBytes = [];

      // Add setup commands as text
      for (String cmd in commands) {
        commandBytes.addAll(utf8.encode(cmd + '\r\n'));
      }

      // Add BITMAP command header (text, ending with comma)
      commandBytes
          .addAll(utf8.encode('BITMAP $xPos,$yPos,$widthBytes,$height,0,'));

      // Add raw binary bitmap data directly (NOT hex encoded!)
      commandBytes.addAll(bitmapData);

      // Add line feed after bitmap data
      commandBytes.addAll(utf8.encode('\r\n'));

      // Add PRINT command
      commandBytes.addAll(utf8.encode('PRINT 1,1\r\n'));

      // Convert to Uint8List
      final completeCommand = Uint8List.fromList(commandBytes);

      // Debug output
      print('TSC Commands for Image Print (StackOverflow method):');
      print('--- START ---');
      print('Image size: ${width}x$height dots');
      print('Width in bytes: $widthBytes');
      print('Bitmap data size: ${bitmapData.length} bytes');
      print('Total command size: ${completeCommand.length} bytes');
      print('Position: ($xPos, $yPos)');
      print('--- END ---');

      // Send complete command
      await BluetoothPrintPlus.write(completeCommand);

      // Small delay to ensure printer processes the command
      await Future.delayed(const Duration(milliseconds: 500));

      _lastSuccessfulPrint = DateTime.now();
      print('Image sticker print command sent successfully');
      return true;
    } catch (e) {
      print('Error printing image sticker: $e');
      return false;
    }
  }

  /// Create a BMP file from raw bitmap data
  /// Returns a complete BMP file with headers
  Uint8List _createBMPFile(Uint8List bitmapData, int width, int height) {
    // BMP file structure:
    // 1. BMP File Header (14 bytes)
    // 2. DIB Header (40 bytes for BITMAPINFOHEADER)
    // 3. Color Palette (8 bytes for monochrome: 2 colors × 4 bytes)
    // 4. Pixel Data (bitmap data, padded to 4-byte boundary per row)

    final bytesPerRow = (width + 7) ~/ 8;
    final paddedBytesPerRow =
        ((bytesPerRow + 3) ~/ 4) * 4; // Pad to 4-byte boundary
    final pixelDataSize = paddedBytesPerRow * height;
    final fileSize = 14 + 40 + 8 + pixelDataSize;

    final bmpFile = Uint8List(fileSize);
    int offset = 0;

    // BMP File Header (14 bytes)
    bmpFile[offset++] = 0x42; // 'B'
    bmpFile[offset++] = 0x4D; // 'M'
    _writeInt32(bmpFile, offset, fileSize);
    offset += 4; // File size
    _writeInt16(bmpFile, offset, 0);
    offset += 2; // Reserved
    _writeInt16(bmpFile, offset, 0);
    offset += 2; // Reserved
    _writeInt32(bmpFile, offset, 14 + 40 + 8);
    offset += 4; // Pixel data offset

    // DIB Header - BITMAPINFOHEADER (40 bytes)
    _writeInt32(bmpFile, offset, 40);
    offset += 4; // Header size
    _writeInt32(bmpFile, offset, width);
    offset += 4; // Width
    _writeInt32(bmpFile, offset, -height);
    offset += 4; // Height (negative = top-down)
    _writeInt16(bmpFile, offset, 1);
    offset += 2; // Color planes
    _writeInt16(bmpFile, offset, 1);
    offset += 2; // Bits per pixel (1 = monochrome)
    _writeInt32(bmpFile, offset, 0);
    offset += 4; // Compression (0 = none)
    _writeInt32(bmpFile, offset, pixelDataSize);
    offset += 4; // Image size
    _writeInt32(bmpFile, offset, 2835);
    offset += 4; // X pixels per meter (~72 DPI)
    _writeInt32(bmpFile, offset, 2835);
    offset += 4; // Y pixels per meter
    _writeInt32(bmpFile, offset, 2);
    offset += 4; // Colors in palette
    _writeInt32(bmpFile, offset, 0);
    offset += 4; // Important colors

    // Color Palette (8 bytes: 2 colors × 4 bytes BGRA)
    // Color 0: Black (0,0,0,0)
    bmpFile[offset++] = 0;
    bmpFile[offset++] = 0;
    bmpFile[offset++] = 0;
    bmpFile[offset++] = 0;
    // Color 1: White (255,255,255,0)
    bmpFile[offset++] = 255;
    bmpFile[offset++] = 255;
    bmpFile[offset++] = 255;
    bmpFile[offset++] = 0;

    // Pixel Data (with padding)
    for (int y = 0; y < height; y++) {
      // Copy row data
      for (int x = 0; x < bytesPerRow; x++) {
        bmpFile[offset++] = bitmapData[y * bytesPerRow + x];
      }
      // Add padding to reach 4-byte boundary
      for (int p = bytesPerRow; p < paddedBytesPerRow; p++) {
        bmpFile[offset++] = 0;
      }
    }

    return bmpFile;
  }

  /// Write 32-bit integer in little-endian format
  void _writeInt32(Uint8List buffer, int offset, int value) {
    buffer[offset] = value & 0xFF;
    buffer[offset + 1] = (value >> 8) & 0xFF;
    buffer[offset + 2] = (value >> 16) & 0xFF;
    buffer[offset + 3] = (value >> 24) & 0xFF;
  }

  /// Write 16-bit integer in little-endian format
  void _writeInt16(Uint8List buffer, int offset, int value) {
    buffer[offset] = value & 0xFF;
    buffer[offset + 1] = (value >> 8) & 0xFF;
  }

  /// Helper method to count set bits in a byte
  int _countSetBits(int byte) {
    int count = 0;
    for (int i = 0; i < 8; i++) {
      if ((byte & (1 << i)) != 0) count++;
    }
    return count;
  }

  /// Clean up resources and cancel subscriptions
  void dispose() {
    try {
      _connectStateSubscription.cancel();
      _scanResultsSubscription.cancel();
      _isScanningSubscription.cancel();
      _blueStateSubscription.cancel();
      disconnectPrinter();
      print('ThermalPrinterService disposed');
    } catch (e) {
      print('Error disposing ThermalPrinterService: $e');
    }
  }
}
