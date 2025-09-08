import 'package:flutter/material.dart';
import '../widgets/material3_components.dart';

/// Material 3 Showcase Screen for Thermal Printer App
/// Demonstrates the latest Material 3 design components and patterns
class Material3ShowcaseScreen extends StatefulWidget {
  const Material3ShowcaseScreen({super.key});

  @override
  State<Material3ShowcaseScreen> createState() => _Material3ShowcaseScreenState();
}

class _Material3ShowcaseScreenState extends State<Material3ShowcaseScreen> {
  bool _isSelected = false;
  double _progressValue = 0.0;
  String _selectedChip = 'Text';
  final List<String> _chipOptions = ['Text', 'QR Code', 'Barcode', 'Image'];

  @override
  void initState() {
    super.initState();
    // Animate progress indicator for demo
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _progressValue = 0.75;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Material 3 Showcase'),
        actions: [
          IconButton(
            onPressed: () => _showThemeInfo(context),
            icon: const Icon(Icons.palette_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header with dynamic color info
          _buildHeaderSection(colorScheme, textTheme),
          const SizedBox(height: 24),

          // Enhanced Cards Section
          _buildCardsSection(),
          const SizedBox(height: 24),

          // Buttons Section
          _buildButtonsSection(),
          const SizedBox(height: 24),

          // Chips Section
          _buildChipsSection(),
          const SizedBox(height: 24),

          // Progress Indicators Section
          _buildProgressSection(),
          const SizedBox(height: 24),

          // Input Fields Section
          _buildInputSection(),
          const SizedBox(height: 24),

          // List Items Section
          _buildListSection(),
          const SizedBox(height: 100), // Space for FAB
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Material3Components.showEnhancedBottomSheet(
          context: context,
          title: 'Material 3 Features',
          child: _buildBottomSheetContent(),
        ),
        icon: const Icon(Icons.design_services),
        label: const Text('Show Features'),
      ),
    );
  }

  Widget _buildHeaderSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Material3Components.enhancedCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Material 3 Design System',
                  style: textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Your thermal printer app now uses the latest Material 3 design system with dynamic colors, expressive typography, and modern components.',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                Material3Components.enhancedChip(
                  label: 'Dynamic Colors',
                  avatar: Icon(
                    Icons.color_lens,
                    size: 16,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                Material3Components.enhancedChip(
                  label: 'Material You',
                  avatar: Icon(
                    Icons.person,
                    size: 16,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                Material3Components.enhancedChip(
                  label: 'Android 12+',
                  avatar: Icon(
                    Icons.android,
                    size: 16,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enhanced Cards',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Material3Components.enhancedCard(
                isSelected: _isSelected,
                onTap: () => setState(() => _isSelected = !_isSelected),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.print, size: 32),
                      SizedBox(height: 8),
                      Text('Print Session'),
                      Text(
                        'Tap to select',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Material3Components.enhancedCard(
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.design_services, size: 32),
                      SizedBox(height: 8),
                      Text('Label Designer'),
                      Text(
                        'Create layouts',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildButtonsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Material 3 Buttons',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            Material3Components.enhancedButton(
              label: 'Print Label',
              onPressed: () {},
              icon: const Icon(Icons.print),
              isPrimary: true,
            ),
            Material3Components.enhancedButton(
              label: 'Preview',
              onPressed: () {},
              icon: const Icon(Icons.preview),
              isPrimary: false,
            ),
            FilledButton.tonal(
              onPressed: () {},
              child: const Text('Save Draft'),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter Chips',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _chipOptions.map((option) {
            return Material3Components.enhancedChip(
              label: option,
              isSelected: _selectedChip == option,
              onSelected: () => setState(() => _selectedChip = option),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress Indicators',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Material3Components.enhancedProgressIndicator(
          value: _progressValue,
          label: 'Printing Progress',
          isLinear: true,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Material3Components.enhancedProgressIndicator(
              value: 0.6,
              label: 'Queue',
              isLinear: false,
            ),
            const SizedBox(width: 32),
            Material3Components.enhancedProgressIndicator(
              label: 'Processing',
              isLinear: false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Input Fields',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Material3Components.enhancedTextField(
          label: 'Label Name',
          hint: 'Enter a name for your label',
          suffixIcon: const Icon(Icons.edit),
        ),
        const SizedBox(height: 16),
        Material3Components.enhancedTextField(
          label: 'Description',
          hint: 'Describe your label design',
          maxLines: 3,
          prefixIcon: const Icon(Icons.description),
        ),
      ],
    );
  }

  Widget _buildListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enhanced List Items',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Material3Components.enhancedCard(
          child: Column(
            children: [
              Material3Components.enhancedListTile(
                title: 'Shipping Label Template',
                subtitle: 'Standard 4x6 shipping label with logo',
                leading: const Icon(Icons.local_shipping),
                trailing: const Icon(Icons.arrow_forward_ios),
                isSelected: true,
                onTap: () {},
              ),
              const Divider(height: 1),
              Material3Components.enhancedListTile(
                title: 'Product Label Template',
                subtitle: 'Small product labels with QR codes',
                leading: const Icon(Icons.qr_code),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),
              const Divider(height: 1),
              Material3Components.enhancedListTile(
                title: 'Custom Design',
                subtitle: 'Create your own label layout',
                leading: const Icon(Icons.design_services),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSheetContent() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Material 3 Features in Your App',
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            icon: Icons.palette,
            title: 'Dynamic Color',
            description: 'Colors adapt to your wallpaper on Android 12+',
          ),
          _buildFeatureItem(
            icon: Icons.dark_mode,
            title: 'Dark Theme',
            description: 'Automatic dark theme support',
          ),
          _buildFeatureItem(
            icon: Icons.touch_app,
            title: 'Modern Interactions',
            description: 'Enhanced ripples and touch feedback',
          ),
          _buildFeatureItem(
            icon: Icons.accessibility,
            title: 'Accessibility',
            description: 'Built-in accessibility improvements',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it!'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Current Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Brightness: ${colorScheme.brightness.name}'),
            const SizedBox(height: 8),
            Text('Primary: ${colorScheme.primary}'),
            const SizedBox(height: 8),
            Text('Surface: ${colorScheme.surface}'),
            const SizedBox(height: 8),
            const Text('Material 3: Enabled'),
            const SizedBox(height: 8),
            const Text('Dynamic Color: Auto-detected'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
