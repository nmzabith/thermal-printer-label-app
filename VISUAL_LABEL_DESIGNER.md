# Visual Label Designer

## Overview
The Visual Label Designer is a comprehensive drag-and-drop interface that allows users to create custom label layouts with precise positioning of all label elements.

## Features

### 🎨 Drag & Drop Interface
- **Element Palette**: Left side panel with all available elements
- **Design Canvas**: Center canvas showing actual label dimensions  
- **Properties Panel**: Right side panel for customizing selected elements

### 📦 Available Elements
- **Headers**: TO:, FROM:, Label Title
- **Contact Info**: Names, Addresses, Phone Numbers  
- **Other**: Custom Text, Separators, Icons/Images

### 🛠️ Customization Options
- **Position**: Drag elements to any position on the label
- **Font Size**: Adjustable from 1-8 for each element
- **Style**: Bold text option for emphasis
- **Visibility**: Show/hide elements as needed
- **Content**: Edit text content for custom elements

## How to Use

### Creating a New Design
1. Navigate to **Label Designer** from the main menu
2. Click **"New Design"** button
3. Enter a name for your custom design
4. The visual designer opens with a default layout

### Adding Elements
1. **From Palette**: Drag any element from the left panel to the canvas
2. **Custom Text**: Use the floating action button (+ icon) to add text
3. **Positioning**: Click and drag elements to move them around

### Editing Elements
1. **Select**: Click on any element in the canvas
2. **Properties**: Use the right panel to modify:
   - Content text
   - Font size (1-8 scale)
   - Bold styling
   - Visibility toggle
   - Position coordinates

### Managing Designs
- **Save**: Click the save icon to preserve changes
- **Preview**: Click preview to see how the label will print
- **Duplicate**: Create copies of existing designs
- **Export/Import**: Share designs between devices
- **Set Active**: Choose which design to use for printing

## Navigation

### From Main Menu
- **Main Screen** → **Menu** → **"Label Designer"**

### From Label Editor  
- **Label Editor** → **Design Services Icon** (🎨) in app bar

### From Design List
- **Label Designer List** → **Select Design** → **Edit**

## Design Canvas

### Canvas Features
- **Scale**: Displays label at 50% scale for easier manipulation
- **Boundaries**: Black border shows exact label dimensions
- **Grid**: Visual reference for element alignment
- **Selection**: Blue highlight indicates selected element

### Element Interaction
- **Single Click**: Select element (shows blue border)
- **Drag**: Move element to new position
- **Properties**: Modify using right panel when selected
- **Delete**: Use delete button in properties panel

## Element Types & Icons

| Element | Icon | Description |
|---------|------|-------------|
| TO Header | 📥 | "TO:" label header |
| FROM Header | 📤 | "FROM:" label header |
| TO Name | 👤 | Recipient name |
| FROM Name | 👤 | Sender name |
| TO Address | 🏠 | Recipient address |
| FROM Address | 🏠 | Sender address |
| TO Phone | 📞 | Recipient phone |
| FROM Phone | 📞 | Sender phone |
| Label Title | 🏷️ | Main label title |
| Custom Text | 📝 | User-defined text |
| Separator | ➖ | Horizontal line |
| Icon/Image | 🖼️ | Custom graphics |

## Default Layout

When creating a new design, a standard layout is automatically generated with:
- Label title at the top
- TO section on the left
- FROM section on the right  
- Headers, names, addresses, and phone numbers appropriately positioned
- Proper font sizes and styling

## Tips & Best Practices

### 🎯 Positioning
- Use the canvas rulers for precise alignment
- Group related elements (TO info, FROM info) together
- Leave adequate spacing between sections
- Consider thermal printer limitations (text clarity)

### 🔤 Typography
- **Headers**: Use larger, bold fonts (size 4-5)
- **Names**: Medium fonts (size 3-4) 
- **Addresses**: Smaller fonts (size 2-3)
- **Details**: Smallest readable size (size 1-2)

### 📐 Layout Guidelines
- Keep important info in the center area
- Avoid placing text too close to edges
- Use separators to divide sections
- Test print to verify readability

### 💾 Organization
- Use descriptive names for designs
- Add descriptions to explain layout purpose
- Duplicate successful designs before major changes
- Export important designs as backups

## Technical Notes

### File Format
- Designs saved as JSON in SharedPreferences
- Compatible with all label configurations
- Includes element positions in dots (8 dots per mm)

### Performance
- Canvas rendered at 50% scale for smooth interaction
- Real-time preview of changes
- Efficient drag & drop implementation

### Compatibility
- Works with all thermal printer configurations
- Supports TSC/TSPL command generation
- Responsive to different label sizes

## Troubleshooting

### Common Issues
- **Elements not showing**: Check visibility toggle in properties
- **Text too small**: Increase font size in properties panel
- **Positioning problems**: Use coordinate sliders for precision
- **Save failures**: Check storage permissions

### Performance Tips
- Limit number of elements for complex designs
- Use appropriate font sizes for thermal printing
- Test designs with actual print sessions
- Keep design names under 50 characters

## Future Features

### Planned Enhancements
- 🔍 Zoom in/out functionality
- 📏 Snap-to-grid alignment
- 🎨 Custom color support (for color printers)
- 📋 Template library
- 🔄 Undo/redo functionality
- 📱 Touch gestures for mobile devices

---

*The Visual Label Designer provides unlimited flexibility for creating professional shipping labels with precise control over every element.*
