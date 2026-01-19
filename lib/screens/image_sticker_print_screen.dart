import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/label_config.dart';
import '../services/image_printing_service.dart';
import '../services/label_config_service.dart';
import '../services/thermal_printer_service.dart';
import 'thermal_printer_settings_screen.dart';
import '../widgets/material3_components.dart';

class ImageStickerPrintScreen extends StatefulWidget {
  const ImageStickerPrintScreen({super.key});

  @override
  State<ImageStickerPrintScreen> createState() =>
      _ImageStickerPrintScreenState();
}

class _ImageStickerPrintScreenState extends State<ImageStickerPrintScreen> {
  final ImagePrintingService _imagePrintingService = ImagePrintingService();
  final LabelConfigService _labelConfigService = LabelConfigService.instance;
  final ThermalPrinterService _printerService = ThermalPrinterService();

  LabelConfig? _selectedLabelConfig;
  List<LabelConfig> _availableLabelConfigs = [];
  img.Image? _currentImage;
  ProcessedImageData? _processedImageData;
  bool _isLoading = false;
  bool _isPrinting = false;
  bool _isProcessing = false;
  bool _isPrinterConnected = false;
  String _printerStatus = 'Checking...';

  @override
  void initState() {
    super.initState();
    _loadLabelConfigs();
    _checkPrinterConnection();
  }

  Future<void> _loadLabelConfigs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final configs = await _labelConfigService.getAllConfigs();
      final currentConfig = await _labelConfigService.getCurrentConfig();

      setState(() {
        _availableLabelConfigs = configs;
        _selectedLabelConfig = currentConfig;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading label configs: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkPrinterConnection() async {
    try {
      final isConnected = await _printerService.isConnected;
      final status = _printerService.getConnectionStatus();

      setState(() {
        _isPrinterConnected = isConnected;
        if (isConnected) {
          _printerStatus = 'Connected to ${status['deviceName']}';
        } else {
          _printerStatus = 'Not connected';
        }
      });
    } catch (e) {
      setState(() {
        _isPrinterConnected = false;
        _printerStatus = 'Connection error';
      });
    }
  }

  void _showPrinterConnectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Printer Not Connected'),
        content: const Text(
            'Please connect to your XPrinter XP-365B before printing.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (context) =>
                          const ThermalPrinterSettingsScreen(),
                    ),
                  )
                  .then((_) => _checkPrinterConnection());
            },
            child: const Text('Printer Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      img.Image? image;

      switch (source) {
        case ImageSource.gallery:
          image = await _imagePrintingService.pickImageFromGallery();
          break;
        case ImageSource.camera:
          image = await _imagePrintingService.pickImageFromCamera();
          break;
        case ImageSource.files:
          image = await _imagePrintingService.pickImageFile();
          break;
      }

      if (image != null) {
        setState(() {
          _currentImage = image;
          _processedImageData = null; // Clear processed data
        });

        // Process image for current label
        if (_selectedLabelConfig != null) {
          await _processImage();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading image: $e')),
        );
      }
    }
  }

  Future<void> _processImage() async {
    if (_currentImage == null || _selectedLabelConfig == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final processedData = await _imagePrintingService.processImageForLabel(
        _currentImage!,
        _selectedLabelConfig!,
      );

      setState(() {
        _processedImageData = processedData;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing image: $e')),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _printImage() async {
    if (_processedImageData == null || _selectedLabelConfig == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please load an image first')),
      );
      return;
    }

    setState(() {
      _isPrinting = true;
    });

    try {
      // Check printer connection
      final isConnected = await _printerService.isConnected;
      if (!isConnected) {
        _showPrinterConnectionDialog();
        return;
      }

      // Print the image
      final success = await _printerService.printImageSticker(
        _processedImageData!.bitmapData,
        _processedImageData!.width,
        _processedImageData!.height,
        _selectedLabelConfig!,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image printed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to print image'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print error: $e')),
        );
      }
    } finally {
      setState(() {
        _isPrinting = false;
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Image Source',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading:
                        const Icon(Icons.photo_library, color: Colors.blue),
                    title: const Text('Photo Gallery'),
                    subtitle: const Text('Choose from your photos'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.camera_alt, color: Colors.green),
                    title: const Text('Camera'),
                    subtitle: const Text('Take a new photo'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.folder, color: Colors.orange),
                    title: const Text('File Browser'),
                    subtitle: const Text('Choose an image file'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.files);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Sticker Print'),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 3,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Material3Components.enhancedCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Print images on sticker labels. Images will be automatically resized and converted to monochrome for optimal thermal printing.',
                              style: textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Label Size Selection
                  Text(
                    'Label Size',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Material3Components.enhancedCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: DropdownButtonFormField<LabelConfig>(
                        value: _selectedLabelConfig,
                        decoration: const InputDecoration(
                          labelText: 'Select Label Size',
                          border: InputBorder.none,
                        ),
                        items: _availableLabelConfigs.map((config) {
                          return DropdownMenuItem(
                            value: config,
                            child: Text(
                              '${config.name} (${config.widthMm.toInt()}x${config.heightMm.toInt()} mm)',
                            ),
                          );
                        }).toList(),
                        onChanged: (config) async {
                          setState(() {
                            _selectedLabelConfig = config;
                          });
                          // Reprocess image if one is loaded
                          if (_currentImage != null) {
                            await _processImage();
                          }
                        },
                      ),
                    ),
                  ),

                  if (_selectedLabelConfig != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Label: ${_selectedLabelConfig!.widthMm.toInt()} mm × ${_selectedLabelConfig!.heightMm.toInt()} mm',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Printer Connection Status
                  Material3Components.enhancedCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            _isPrinterConnected
                                ? Icons.bluetooth_connected
                                : Icons.bluetooth_disabled,
                            color: _isPrinterConnected
                                ? Colors.green
                                : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Printer Status',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  _printerStatus,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: _isPrinterConnected
                                        ? Colors.green
                                        : colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ThermalPrinterSettingsScreen(),
                                    ),
                                  )
                                  .then((_) => _checkPrinterConnection());
                            },
                            child: const Text('Settings'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Image Preview Section
                  Text(
                    'Image Preview',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Preview Container
                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(16),
                      color: colorScheme.surfaceVariant.withOpacity(0.3),
                    ),
                    child: _isProcessing
                        ? const Center(child: CircularProgressIndicator())
                        : _processedImageData != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.memory(
                                  Uint8List.fromList(
                                    img.encodePng(
                                        _processedImageData!.previewImage),
                                  ),
                                  fit: BoxFit.contain,
                                ),
                              )
                            : _buildNoImagePlaceholder(),
                  ),

                  // Image Info
                  if (_processedImageData != null) ...[
                    const SizedBox(height: 12),
                    Material3Components.enhancedCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.image, color: colorScheme.secondary),
                                const SizedBox(width: 8),
                                Text(
                                  'Image Information',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                                'File Name',
                                _imagePrintingService.currentImageName ??
                                    'Unknown'),
                            _buildInfoRow('Dimensions',
                                '${_processedImageData!.width} × ${_processedImageData!.height} dots'),
                            _buildInfoRow('Size on Label',
                                '${(_processedImageData!.width / 8).toStringAsFixed(1)} × ${(_processedImageData!.height / 8).toStringAsFixed(1)} mm'),
                            _buildInfoRow('Position', 'Centered'),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action Buttons
                  Text(
                    'Actions',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Load Image Button
                  SizedBox(
                    width: double.infinity,
                    child: Material3Components.enhancedButton(
                      onPressed: _isProcessing || _isPrinting
                          ? null
                          : _showImageSourceDialog,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label:
                          _currentImage == null ? 'Load Image' : 'Change Image',
                      isPrimary: true,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Print Button
                  SizedBox(
                    width: double.infinity,
                    child: Material3Components.enhancedButton(
                      onPressed: _processedImageData == null ||
                              _isPrinting ||
                              _isProcessing
                          ? null
                          : _printImage,
                      icon: _isPrinting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.print),
                      label: _isPrinting ? 'Printing...' : 'Print Image',
                      isPrimary: false,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.secondary,
                        foregroundColor: colorScheme.onSecondary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tips Card
                  Material3Components.enhancedCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_outline,
                                  color: Colors.amber.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Tips for Best Results',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildTipRow(
                              'High contrast images work best on thermal printers'),
                          _buildTipRow(
                              'Images are automatically converted to black and white'),
                          _buildTipRow(
                              'Images will be resized to fit the selected label size'),
                          _buildTipRow(
                              'Ensure printer is connected before printing'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildNoImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_outlined,
          size: 64,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 16),
        Text(
          'No image loaded',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap "Load Image" to get started',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

enum ImageSource {
  gallery,
  camera,
  files,
}
