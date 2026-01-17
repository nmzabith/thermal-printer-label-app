import 'package:flutter/material.dart';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import '../services/thermal_printer_service.dart';
import 'label_settings_screen.dart';
import '../widgets/material3_components.dart';

class ThermalPrinterSettingsScreen extends StatefulWidget {
  const ThermalPrinterSettingsScreen({super.key});

  @override
  State<ThermalPrinterSettingsScreen> createState() =>
      _ThermalPrinterSettingsScreenState();
}

class _ThermalPrinterSettingsScreenState
    extends State<ThermalPrinterSettingsScreen> with WidgetsBindingObserver {
  final ThermalPrinterService _printerService = ThermalPrinterService();
  List<BluetoothDevice> _availablePrinters = [];
  BluetoothDevice? _selectedPrinter;
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _showAllDevices = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeService();
    _updatePrinterStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh connection status when returning to screen
      _updatePrinterStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Initialize the thermal printer service
  Future<void> _initializeService() async {
    try {
      await _printerService.initialize();
      print('Thermal printer service initialized');
    } catch (e) {
      print('Error initializing thermal printer service: $e');
    }
  }

  /// Update printer connection status with real verification
  Future<void> _updatePrinterStatus() async {
    try {
      bool connected = await _printerService.isConnected;
      Map<String, dynamic> status = await _printerService.getPrinterStatus();

      if (mounted) {
        setState(() {
          _isConnected = connected;
          if (connected && status['printer_name'] != 'None') {
            // Try to find the connected printer in our list
            try {
              _selectedPrinter = _availablePrinters.firstWhere(
                (printer) => printer.name == status['printer_name'],
              );
            } catch (e) {
              // Printer not found in current list, that's okay
              _selectedPrinter = null;
            }
          } else {
            _selectedPrinter = null;
          }
        });
      }
    } catch (e) {
      print('Error updating printer status: $e');
      if (mounted) {
        setState(() {
          _isConnected = false;
          _selectedPrinter = null;
        });
      }
    }
  }

  /// Scan for available Bluetooth printers
  Future<void> _scanForPrinters() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _availablePrinters.clear();
    });

    try {
      List<BluetoothDevice> devices;

      if (_showAllDevices) {
        devices = await _printerService.getAllDevices();
      } else {
        devices = await _printerService.discoverPrinters();
      }

      if (mounted) {
        setState(() {
          _availablePrinters = devices;
          _isScanning = false;
        });
      }

      if (devices.isEmpty) {
        _showNoDevicesDialog();
      }
    } catch (e) {
      print('Error scanning for printers: $e');
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        _showErrorDialog(
            'Scan Error', 'Failed to scan for printers: ${e.toString()}');
      }
    }
  }

  /// Connect to selected printer
  Future<void> _connectToPrinter(BluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
    });

    try {
      // Show progress message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connecting to ${device.name}...'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 3),
        ),
      );

      bool success = await _printerService.connectToPrinter(device);

      // Allow extra time for connection to stabilize
      if (success) {
        await Future.delayed(const Duration(seconds: 1));
        // Double check connection status
        success = await _printerService.isConnected;
      }

      if (mounted) {
        setState(() {
          _isConnecting = false;
          if (success) {
            _selectedPrinter = device;
            _isConnected = true;
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Connected to ${device.name}'),
                backgroundColor: Colors.green, // Keep consistent success color
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).clearSnackBars();
            _showErrorDialog(
                'Connection Failed',
                'Failed to connect to ${device.name}.\n\n'
                    'Please ensure:\n'
                    '• Printer is turned on\n'
                    '• Printer is in pairing mode\n'
                    '• Printer is not connected to another device\n'
                    '• You are within range (< 10m)');
          }
        });
      }
    } catch (e) {
      print('Error connecting to printer: $e');
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        _showErrorDialog(
            'Connection Error',
            'Failed to connect to printer: ${e.toString()}\n\n'
                'Try turning the printer off and on again, then retry.');
      }
    }
  }

  /// Disconnect from current printer
  Future<void> _disconnectPrinter() async {
    try {
      bool success = await _printerService.disconnectPrinter();

      if (mounted) {
        setState(() {
          _isConnected = false;
          _selectedPrinter = null;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Disconnected from printer'),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error disconnecting printer: $e');
      _showErrorDialog(
          'Disconnect Error', 'Failed to disconnect: ${e.toString()}');
    }
  }

  /// Perform quick connection test with TSC beep command
  Future<void> _quickConnectionTest() async {
    if (!_isConnected) {
      _showErrorDialog('Test Error', 'No printer connected');
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material3Components.enhancedProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Testing connection...\nListen for beep sound'),
            ],
          ),
        ),
      );

      bool success = await _printerService.quickConnectionTest();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  const Text('Connection test passed! Did you hear the beep?'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          _showErrorDialog('Test Failed',
              'Connection test failed. Please check printer connection and try again.');
          await _updatePrinterStatus(); // Refresh status
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }
      print('Error during quick test: $e');
      _showErrorDialog('Test Error', 'Connection test error: ${e.toString()}');
    }
  }

  /// Perform full test print with comprehensive TSC commands
  Future<void> _fullTestPrint() async {
    if (!_isConnected) {
      _showErrorDialog('Test Error', 'No printer connected');
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material3Components.enhancedProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Printing test label...\nUsing TSC commands'),
            ],
          ),
        ),
      );

      bool success = await _printerService.fullTestPrint();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Test print completed successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          _showErrorDialog('Print Failed',
              'Test print failed. Please check printer and try again.');
          await _updatePrinterStatus(); // Refresh status
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }
      print('Error during full test print: $e');
      _showErrorDialog('Print Error', 'Test print error: ${e.toString()}');
    }
  }

  /// Show error dialog
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title,
            style: TextStyle(color: Theme.of(context).colorScheme.error)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show no devices found dialog
  void _showNoDevicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Devices Found'),
        content: const Text(
          'No Bluetooth devices found. Please ensure:\n\n'
          '• Bluetooth is enabled\n'
          '• Printer is turned on\n'
          '• Printer is in pairing mode\n'
          '• You are within range\n\n'
          'Try scanning again or enable "Show All Devices" to see paired devices.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Thermal Printer Settings', style: textTheme.titleLarge),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 3,
        actions: [
          IconButton(
            icon: const Icon(Icons.label_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LabelSettingsScreen(),
                ),
              );
            },
            tooltip: 'Label Settings',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _updatePrinterStatus,
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection Status Card
              Material3Components.enhancedCard(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isConnected
                                ? Icons.bluetooth_connected
                                : Icons.bluetooth_disabled,
                            color: _isConnected
                                ? Colors.green
                                : colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Printer Status',
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildStatusRow('Status',
                          _isConnected ? 'Connected' : 'Disconnected'),
                      if (_selectedPrinter != null) ...[
                        _buildStatusRow(
                            'Printer',
                            _selectedPrinter!.name.isNotEmpty
                                ? _selectedPrinter!.name
                                : 'Unknown'),
                        _buildStatusRow(
                            'Address',
                            _selectedPrinter!.address.isNotEmpty
                                ? _selectedPrinter!.address
                                : 'Unknown'),
                      ],
                      const SizedBox(height: 16),

                      // Action Buttons Row
                      Row(
                        children: [
                          if (_isConnected) ...[
                            Expanded(
                              child: Material3Components.enhancedButton(
                                onPressed: _quickConnectionTest,
                                label: 'Quick Test',
                                icon: const Icon(Icons.volume_up, size: 18),
                                isPrimary: false,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Material3Components.enhancedButton(
                                onPressed: _fullTestPrint,
                                label: 'Test Print',
                                icon: const Icon(Icons.print, size: 18),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Material3Components.enhancedButton(
                                onPressed: _disconnectPrinter,
                                label: 'Disconnect',
                                icon: const Icon(Icons.bluetooth_disabled,
                                    size: 18),
                                isPrimary: false,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.error,
                                  foregroundColor: colorScheme.onError,
                                ),
                              ),
                            ),
                          ] else ...[
                            Expanded(
                              child: Material3Components.enhancedButton(
                                onPressed:
                                    _isScanning ? null : _scanForPrinters,
                                label: _isScanning
                                    ? 'Scanning...'
                                    : 'Scan Devices',
                                icon: _isScanning
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.search, size: 18),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Scan Options
              if (!_isConnected) ...[
                SwitchListTile(
                  // Changed from CheckboxListTile for M3 Feel
                  title: const Text('Show All Devices'),
                  subtitle:
                      const Text('Include paired devices in scan results'),
                  value: _showAllDevices,
                  onChanged: (value) {
                    setState(() {
                      _showAllDevices = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Available Printers List
              Text(
                'Available Devices (${_availablePrinters.length})',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              _availablePrinters.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bluetooth_searching,
                              size: 48,
                              color: colorScheme.outlineVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No devices found',
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap "Scan Devices" to search for printers',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true, // Needed inside SingleChildScrollView
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _availablePrinters.length,
                      itemBuilder: (context, index) {
                        final device = _availablePrinters[index];
                        final isSelected =
                            _selectedPrinter?.address == device.address;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Material3Components.enhancedListTile(
                            leading: Icon(
                              Icons.print,
                              color: isSelected
                                  ? Colors.green
                                  : colorScheme.primary,
                            ),
                            title: device.name.isNotEmpty
                                ? device.name
                                : 'Unknown Device',
                            subtitle:
                                'Address: ${device.address}\nType: ${device.type}',
                            isSelected: isSelected,
                            trailing: _isConnecting && isSelected
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colorScheme.primary),
                                  )
                                : isSelected && _isConnected
                                    ? const Icon(Icons.check_circle,
                                        color: Colors.green)
                                    : Icon(Icons.arrow_forward_ios,
                                        size: 16,
                                        color: colorScheme.onSurfaceVariant),
                            onTap: () {
                              if (!_isConnecting && !_isConnected) {
                                _connectToPrinter(device);
                              }
                            },
                          ),
                        );
                      },
                    ),

              // Help Text
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.secondaryContainer),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: colorScheme.secondary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'TSC/TSPL Thermal Printer',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Uses TSC/TSPL commands optimized for XPrinter XP-365B\n'
                      '• Quick Test sends beep commands to verify connection\n'
                      '• Test Print creates a full label with text and barcode\n'
                      '• Supports precise positioning and professional labels',
                      style: textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSecondaryContainer),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
