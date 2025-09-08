import 'dart:async';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/shipping_label.dart';
import '../models/label_config.dart';
import 'label_config_service.dart';

/// Thermal Printer Service using bluetooth_print_plus with TSC/TSPL commands
/// Designed specifically for XPrinter XP-365B thermal label printer
class ThermalPrinterService {
  static final ThermalPrinterService _instance = ThermalPrinterService._internal();
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

  /// Check and request Bluetooth permissions
  Future<bool> checkBluetoothPermissions() async {
    try {
      Map<Permission, PermissionStatus> permissions = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      bool allGranted = permissions.values.every((status) => 
        status == PermissionStatus.granted);
      
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
      
      _scanResultsSubscription = BluetoothPrintPlus.scanResults.listen((devices) {
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

      await BluetoothPrintPlus.connect(device);
      await Future.delayed(const Duration(seconds: 2));

      // If connection state shows connected, accept it without strict verification
      if (BluetoothPrintPlus.isConnected) {
        _selectedDevice = device;
        _isConnected = true;
        _lastSuccessfulPrint = DateTime.now();
        print('Successfully connected to printer - connection state confirmed');
        return true;
      } else {
        print('Connection state shows disconnected');
        _selectedDevice = null;
        _isConnected = false;
        return false;
      }
      
    } catch (e) {
      print('Error connecting to printer: $e');
      _isConnected = false;
      _selectedDevice = null;
      await BluetoothPrintPlus.disconnect();
      return false;
    } finally {
      _isConnecting = false;
    }
  }

  /// Verify connection with simple TSC test
  /// Used for the test buttons - sends actual commands to printer
  Future<bool> _verifyConnectionWithTest() async {
    try {
      if (_selectedDevice == null || !BluetoothPrintPlus.isConnected) return false;

      await tscCommand.cleanCommand();
      await tscCommand.size(width: 80, height: 60);
      await tscCommand.cls();
      
      await tscCommand.text(
        content: "Connection Test",
        x: 10, 
        y: 10
      );
      
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
      if (_selectedDevice != null || _isConnected) {
        print('Disconnecting from printer...');
        await BluetoothPrintPlus.disconnect();
      }
      
      _selectedDevice = null;
      _isConnected = false;
      _lastSuccessfulPrint = null;
      print('Successfully disconnected from printer');
      return true;
      
    } catch (e) {
      print('Error disconnecting printer: $e');
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
      
      await tscCommand.text(
        content: "Quick Test OK",
        x: 10,
        y: 10
      );
      
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

      await tscCommand.cleanCommand();
      await tscCommand.size(width: labelConfig.widthMm.toInt(), height: labelConfig.heightMm.toInt());
      await tscCommand.cls();
      
      int yPos = 5;
      int lineHeight = labelConfig.heightMm < 60 ? 10 : 15;
      
      await tscCommand.text(
        content: "TSC TEST PRINT",
        x: 5, 
        y: yPos
      );
      yPos += lineHeight;
      
      await tscCommand.text(
        content: "XPrinter XP-365B",
        x: 5, 
        y: yPos
      );
      yPos += lineHeight;
      
      await tscCommand.text(
        content: "Config: ${labelConfig.name}",
        x: 5, 
        y: yPos
      );
      yPos += lineHeight;
      
      String timestamp = DateTime.now().toString().substring(0, 16);
      await tscCommand.text(
        content: timestamp,
        x: 5, 
        y: yPos
      );
      
      await tscCommand.print(1);
      
      final cmd = await tscCommand.getCommand();
      if (cmd == null) {
        throw Exception('Failed to generate TSC commands');
      }

      BluetoothPrintPlus.write(cmd);
      
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
      if (!_isConnected || _selectedDevice == null) {
        throw Exception('No printer connected');
      }

      if (labels.isEmpty) {
        throw Exception('No labels to print');
      }

      print('Printing ${labels.length} shipping labels using TSC commands...');
      
      for (int i = 0; i < labels.length; i++) {
        ShippingLabel label = labels[i];
        print('Printing label ${i + 1}/${labels.length}: ${label.toInfo.name}');
        
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

  /// Print a single shipping label using TSC commands
  /// Uses configurable label dimensions and spacing
  Future<bool> _printSingleShippingLabel(ShippingLabel label) async {
    try {
      // Get current label configuration
      final labelConfig = await LabelConfigService.instance.getCurrentConfig();
      
      await tscCommand.cleanCommand();
      await tscCommand.size(width: labelConfig.widthMm.toInt(), height: labelConfig.heightMm.toInt());
      await tscCommand.cls();
      
      // Calculate layout based on label height
      int yPos = 5; // Start closer to top
      int lineHeight = labelConfig.heightMm < 60 ? 8 : 12; // Smaller line height for smaller labels
      
      // Header - adjust based on label size
      if (labelConfig.heightMm >= 80) {
        await tscCommand.text(
          content: "SHIPPING LABEL",
          x: 5, 
          y: yPos
        );
        yPos += lineHeight + 5;
        
        // Separator line only for larger labels
        await tscCommand.text(
          content: "============================",
          x: 5, 
          y: yPos
        );
        yPos += lineHeight;
      }
      
      // FROM section
      await tscCommand.text(
        content: "FROM:",
        x: 5, 
        y: yPos
      );
      yPos += lineHeight;
      
      await tscCommand.text(
        content: label.fromInfo.name,
        x: 5, 
        y: yPos
      );
      yPos += lineHeight - 2;
      
      await tscCommand.text(
        content: label.fromInfo.address,
        x: 5, 
        y: yPos
      );
      yPos += lineHeight - 2;
      
      if (label.fromInfo.phoneNumber1.isNotEmpty && labelConfig.heightMm >= 60) {
        await tscCommand.text(
          content: "Tel: ${label.fromInfo.phoneNumber1}",
          x: 5, 
          y: yPos
        );
        yPos += lineHeight - 2;
      }
      
      yPos += 3; // Small spacing
      
      // TO section
      await tscCommand.text(
        content: "TO:",
        x: 5, 
        y: yPos
      );
      yPos += lineHeight;
      
      await tscCommand.text(
        content: label.toInfo.name,
        x: 5, 
        y: yPos
      );
      yPos += lineHeight - 2;
      
      await tscCommand.text(
        content: label.toInfo.address,
        x: 5, 
        y: yPos
      );
      yPos += lineHeight - 2;
      
      if (label.toInfo.phoneNumber1.isNotEmpty && labelConfig.heightMm >= 60) {
        await tscCommand.text(
          content: "Tel: ${label.toInfo.phoneNumber1}",
          x: 5, 
          y: yPos
        );
        yPos += lineHeight - 2;
      }
      
      // Footer information - only if space available
      if (yPos + (lineHeight * 2) < labelConfig.heightMm - 5) {
        yPos += 3;
        
        String timestamp = DateTime.now().toString().substring(0, 16);
        await tscCommand.text(
          content: timestamp,
          x: 5, 
          y: yPos
        );
        yPos += lineHeight - 2;
        
        await tscCommand.text(
          content: "ID: ${label.id}",
          x: 5, 
          y: yPos
        );
      }
      
      // Print with configured spacing
      await tscCommand.print(1);
      
      // Add gap between labels using GAP command
      if (labelConfig.spacingMm > 0) {
        await tscCommand.cleanCommand();
        // TSC GAP command: sets the gap between labels
        // This helps with proper label separation
        await tscCommand.size(width: labelConfig.widthMm.toInt(), height: labelConfig.spacingMm.toInt());
        await tscCommand.cls();
        await tscCommand.print(1); // Print empty space
      }
      
      final cmd = await tscCommand.getCommand();
      if (cmd == null) {
        throw Exception('Failed to generate TSC command for label ${label.id}');
      }

      BluetoothPrintPlus.write(cmd);
      
      _lastSuccessfulPrint = DateTime.now();
      print('Shipping label ${label.id} printed successfully with ${labelConfig.name} format');
      return true;

    } catch (e) {
      print('Error printing shipping label ${label.id}: $e');
      return false;
    }
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
