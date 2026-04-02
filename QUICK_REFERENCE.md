
# ModernDropdown - Quick Reference

## Installation (Already Done ✅)

```dart
import '../../widgets/modern_dropdown.dart';
```

---

## Minimal Example

```dart
String? selected;

ModernDropdown(
  selectedValue: selected,
  items: [
    ModernDropdownItem(
      label: 'Option 1',
      value: 'opt1',
      icon: LucideIcons.star,
    ),
    ModernDropdownItem(
      label: 'Option 2',
      value: 'opt2',
      icon: LucideIcons.heart,
    ),
  ],
  hint: 'Select an option',
  label: 'My Dropdown',
  onChanged: (value) => setState(() => selected = value),
)
```

---

## Complete Example (Expense Screen)

```dart
class _AddExpenseScreenState extends State<AddExpenseScreen> {
  // Define items with icons
  late final List<ModernDropdownItem> categories = [
    ModernDropdownItem(
      label: 'Combustível',
      value: 'fuel',
      icon: LucideIcons.droplets,
    ),
    ModernDropdownItem(
      label: 'Manutenção',
      value: 'maintenance',
      icon: LucideIcons.wrench,
    ),
  ];

  String? selectedCategory;
  final amountController = TextEditingController();

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            ModernDropdown(
              selectedValue: selectedCategory,
              items: categories,
              hint: 'Selecione uma categoria',
              label: 'Categoria',
              onChanged: (value) {
                setState(() => selectedCategory = value);
              },
            ),
            SizedBox(height: 12),
            TextField(
              controller: amountController,
              decoration: InputDecoration(labelText: 'Valor (R\$)'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addExpense,
              child: Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  void _addExpense() {
    // Implementation
  }
}
```

---

## API Reference

### Parameters

| Param | Type | Required | Default |
|-------|------|----------|---------|
| `selectedValue` | `String?` | ✅ Yes | - |
| `items` | `List<ModernDropdownItem>` | ✅ Yes | - |
| `onChanged` | `Function(String)` | ✅ Yes | - |
| `hint` | `String` | ✅ Yes | - |
| `label` | `String` | ✅ Yes | - |
| `isExpanded` | `bool` | ❌ No | `true` |

### ModernDropdownItem

```dart
ModernDropdownItem(
  label: 'Display Text',      // What user sees
  value: 'unique_id',          // What gets returned in onChanged
  icon: LucideIcons.myIcon,    // Icon from Lucide
)
```

---

## Common Icons

```dart
LucideIcons.droplets        // 💧 Fuel
LucideIcons.wrench          // 🔧 Maintenance  
LucideIcons.shield          // 🛡️  Insurance
LucideIcons.sun             // ☀️  Car wash
LucideIcons.squareParking   // 🅿️ Parking
LucideIcons.ticketSlash     // 🎫 Toll
LucideIcons.car             // 🚗 Vehicle
LucideIcons.truck           // 🚚 Pickup
LucideIcons.zap             // ⚡ Battery
LucideIcons.droplet         // 💧 Oil
LucideIcons.settings        // ⚙️  Generic
LucideIcons.star            // ⭐ Rating
LucideIcons.heart           // ❤️  Favorite
```

[See full list: https://lucide.dev/]

---

## State Management with SetState

```dart
String? category;

// Reading selected value
print('Selected: $category');

// Handling selection
onChanged: (value) {
  setState(() {
    category = value;
  });
}

// Displaying selection
Text('Category: ${category ?? "Not selected"}')
```

---

## State Management with Provider

```dart
// With ChangeNotifier
class CategoryProvider extends ChangeNotifier {
  String? selectedCategory;
  
  selectCategory(String value) {
    selectedCategory = value;
    notifyListeners();
  }
}

// In widget
Consumer<CategoryProvider>(
  builder: (context, provider, _) => ModernDropdown(
    selectedValue: provider.selectedCategory,
    items: categories,
    onChanged: provider.selectCategory,
    // ...
  ),
)
```

---

## Validation

```dart
String? selectedCategory;
String? error;

// Validate
bool isValid() {
  if (selectedCategory == null || selectedCategory!.isEmpty) {
    error = 'Please select a category';
    return false;
  }
  return true;
}

// Display error
if (error != null)
  Padding(
    padding: EdgeInsets.only(top: 8),
    child: Text(
      error!,
      style: TextStyle(color: Colors.red, fontSize: 12),
    ),
  ),
```

---

## Styling Customization

### Modify Dropdown Trigger
Edit `modern_dropdown.dart` → `build()` method:

```dart
// Change colors
decoration: BoxDecoration(
  color: AppColors.card,           // Change background
  borderRadius: BorderRadius.circular(14),
  border: Border.all(
    color: widget.selectedValue != null
        ? AppColors.accent
        : AppColors.separator,
  ),
)

// Change padding
padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
```

### Modify Modal Header
Edit `modern_dropdown.dart` → `_buildModalContent()`:

```dart
Padding(
  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
  child: Row(
    children: [
      Text(
        widget.label,
        style: GoogleFonts.inter(
          fontSize: 18,  // Change size
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      // ...
    ],
  ),
)
```

### Modify Item Styling
Edit `modern_dropdown.dart` → `_buildItemTile()`:

```dart
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  child: Row(
    children: [
      // Icon styling
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withOpacity(0.1)
              : AppColors.bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          item.icon,
          size: 18,
          color: isSelected ? AppColors.accent : AppColors.secondary,
        ),
      ),
    ],
  ),
)
```

---

## Troubleshooting

### Modal doesn't appear
```dart
// ❌ Wrong
showModalBottomSheet(
  context: context,
  // ...
)

// ✅ Correct - save to variable, then show
Future<void> _showDropdownModal(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    // ...
  );
}
```

### Icons not showing
```dart
// ❌ Wrong
icon: Icons.star,  // Material icon

// ✅ Correct - Use Lucide
import 'package:lucide_icons_flutter/lucide_icons.dart';
icon: LucideIcons.star,
```

### Selection not updating
```dart
// ❌ Wrong - forgot setState
onChanged: (value) {
  selectedCategory = value;
},

// ✅ Correct
onChanged: (value) {
  setState(() {
    selectedCategory = value;
  });
},
```

### Modal too small/too big
```dart
// Adjust in _buildModalContent()
child: Container(
  decoration: BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(28),  // Adjust radius
      topRight: Radius.circular(28),
    ),
  ),
  child: Column(
    mainAxisSize: MainAxisSize.min,  // Don't change this!
    children: [
      // Items list
      Flexible(
        child: ListView.builder(
          // Items here
        ),
      ),
    ],
  ),
)
```

---

## Files Reference

| File | Purpose | Lines |
|------|---------|-------|
| `lib/widgets/modern_dropdown.dart` | Core component | 380 |
| `lib/widgets/modern_dropdown_demo.dart` | Examples | 280 |
| `lib/features/expenses/add_expense_screen.dart` | Usage | 200 |
| `MODERN_DROPDOWN_GUIDE.md` | Full documentation | 250+ |
| `IMPLEMENTATION_SUMMARY.md` | Overview | 200 |

---

## Performance Tips

1. Define items as `late final` (initialize once)
2. Use `SetState` only when necessary
3. Keep item lists under 100 items (or add search)
4. Don't build complex widgets inside items
5. Use `const` constructors where possible

---

## Browser Compatibility

| Feature | iOS | Android | Web | Desktop |
|---------|-----|---------|-----|---------|
| Dropdown | ✅ | ✅ | ✅ | ✅ |
| Animations | ✅ | ✅ | ✅ | ✅ |
| Icons | ✅ | ✅ | ✅ | ✅ |
| Touch | ✅ | ✅ | ✅ | ✅ |
| Hover | ⚠️ | - | ✅ | ✅ |

---

## Version Info

- **Flutter**: 3.0+
- **Dart**: 2.17+
- **Dependencies**: `lucide_icons_flutter`, `google_fonts`
- **Status**: ✅ Production Ready

---

**Need help?** → See `MODERN_DROPDOWN_GUIDE.md`  
**Want examples?** → Check `lib/widgets/modern_dropdown_demo.dart`  
**Using in code?** → Look at `lib/features/expenses/add_expense_screen.dart`
