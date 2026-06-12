# MochaDS - Documentation

MochaDS is a comprehensive UI component library for QML, based on the **Catppuccin Mocha** theme. It provides a set of highly customizable, accessible, and visually appealing components for building modern desktop applications.

## Table of Contents
- [Theme (Singleton)](#theme-singleton)
- [Shell](#shell)
- [Sidebar](#sidebar)
- [NavigationBar](#navigationbar)
- [Button](#button)
- [TextField](#textfield)
- [Checkbox](#checkbox)
- [Card](#card)
- [Badge](#badge)
- [Modal](#modal)
- [Drawer](#drawer)
- [Table](#table)
- [ProgressBar](#progressbar)
- [Toast](#toast)
- [Select](#select)
- [Tabs](#tabs)
- [Accordion](#accordion)
- [Icons & Helpers](#icons--helpers)

---

## Theme (Singleton)
The `Theme` singleton manages global visual tokens, colors, and typography.

### Properties
- `colors`: Object containing theme colors (Catppuccin Mocha palette).
    - `background`: `#1e1e2e`
    - `primary`: `#cba6f7` (Mauve)
    - `secondary`: `#89b4fa` (Blue)
    - `text`: `#cdd6f4`
    - `success`: `#a6e3a1` (Green)
    - `danger`: `#f38ba8` (Red)
    - `warning`: `#f9e2af` (Yellow)
    - `info`: `#89dceb` (Sky)
- `spacing`: Spacing tokens (`xs`, `sm`, `md`, `lg`, `xl`, `xxl`).
- `geometry`: Geometry tokens like `radiusSm/Md/Lg`, `borderSm/Md`.
- `typography`: Typography configuration including font families and sizes (`sizeXs` to `sizeH1`).

---

## Shell
The high-level application layout manager. Handles responsive sidebars, headers, and multi-column content.

### Properties
- `sidebarWidth` (real): Width of the primary sidebar.
- `secondarySidebarWidth` (real): Width of the secondary sidebar.
- `headerHeight` (real): Height of the top header bar.
- `sidebarVisible` (bool): Toggle primary sidebar.
- `secondarySidebarVisible` (bool): Toggle secondary sidebar.
- `sidebarCollapsed` (bool): Collapse sidebar to mini-mode.
- `columnCount` (int): Number of visible content columns (1, 2, or 3).
- `columnSpacing` (real): Space between columns.
- `columnRatio1/2/3` (real): Relative width ratios for columns.
- `activeMobileColumn` (int): Active column on mobile view (0-2).
- `backgroundColor` (color): Background color of the main area.

### Slots
- `header` (list<Item>): Custom header content.
- `sidebar` (list<Item>): Primary sidebar content.
- `secondarySidebar` (list<Item>): Secondary sidebar content.
- `col1`, `col2`, `col3` (list<Item>): Content for each column.

---

## Sidebar
A vertical navigation panel that can be fixed or floated.

### Properties
- `variant` (string): `"fixed"` | `"floated"`.
- `isCollapsed` (bool): If true, reduces width.
- `expandOnHover` (bool): Expand automatically on mouse hover when collapsed.
- `collapsedWidth` (real): Width when collapsed (default 68).
- `expandedWidth` (real): Width when expanded (default 260).

### Sidebar Sub-components
- **SidebarHeader**: Top section with logo and title.
    - `title`, `subtitle`, `logoIcon`.
- **SidebarSection**: Scrollable container for items.
    - `spacing`.
- **SidebarItem**: Individual navigation entry.
    - `icon`, `label`, `isActive`, `expanded`.
    - Supports nested `SidebarItem` for sub-menus.
- **SidebarFooter**: Bottom section, typically for user profiles.
    - `username`, `email`, `avatarIcon`.

---

## NavigationBar
A floating or fixed pill-shaped navigation bar, often used for mobile or secondary navigation.

### Properties
- `variant` (string): `"standard"`, `"floating"`, `"expanding"`, `"labeled"`.
- `currentIndex` (int): Active item index.
- `highlightColor` (color): Color of the active indicator.
- `darkMode` (bool): Toggle dark/light appearance.

### NavigationItem
Individual items inside the `NavigationBar`.
- `iconName` (string): Lucide icon.
- `label` (string): Text label.

---

## Button
A versatile button component with multiple variants and sizes.

### Properties
- `text` (string): The label text.
- `icon` (string): Lucide icon name.
- `variant` (string): `"primary"`, `"secondary"`, `"danger"`, `"success"`, `"warning"`, `"info"`, `"outline"`, `"tonal"`, `"ghost"`.
- `size` (string): `"sm"`, `"md"`, `"lg"`.
- `loading` (bool): Shows a spinning loader.
- `disabled` (bool): Disables interaction.

### Signals
- `clicked()`: Emitted when the button is clicked.

---

## TextField
Input component for text, passwords, and numbers.

### Properties
- `text` (string): The input text.
- `placeholder` (string): Hint text.
- `type` (string): `"text"`, `"password"`, `"email"`, `"number"`.
- `iconLeft`, `iconRight` (string): Lucide icon names.
- `status` (string): `"normal"`, `"success"`, `"error"`.

---

## Checkbox
Toggleable checkbox component.

### Properties
- `checked` (bool): Current state.
- `label` (string): Label text.

### Signals
- `toggled(bool isChecked)`: Emitted when the state changes.

---

## Card
Container component for grouping content.

### Properties
- `title`, `subtitle`, `icon` (string): Header details.
- `variant` (string): `"default"`, `"accent"`, `"tonal"`, `"outline"`.
- `accentPosition` (string): `"left"`, `"top"`, `"none"`.

---

## Badge
Informational status pill.

### Properties
- `text` (string): Label text.
- `variant` (string): `"primary"`, `"secondary"`, `"success"`, `"warning"`, `"danger"`, `"info"`.
- `showDot` (bool): Shows a small indicator dot.

---

## Modal
Dialog box that overlays the application.

### Properties
- `open` (bool): Controls visibility.
- `title` (string): Modal title.
- `size` (string): `"sm"`, `"md"`, `"lg"`, `"full"`.

---

## Drawer
Sliding panel from any screen edge.

### Properties
- `open` (bool): Controls visibility.
- `position` (string): `"right"`, `"left"`, `"top"`, `"bottom"`.

---

## Table
Data grid with sorting, pagination, and selection.

### Properties
- `columns` (var): Column definitions `{ name, label, width, sortable, type }`.
- `rows` (var): Data array.
- `selectable` (bool): Enables checkboxes.

---

## ProgressBar
Visual progress indicator.

### Properties
- `value` (real): 0.0 to 1.0.
- `indeterminate` (bool): Pulse animation for busy state.

---

## Toast
Notification messages that auto-dismiss.

### Properties
- `title`, `message` (string): Content.
- `type` (string): `"info"`, `"success"`, `"warning"`, `"error"`.

---

## Select
Dropdown selection component.

### Properties
- `options` (var): Array of options.
- `selectedValue` (var): Current selection.

---

## Tabs
Tabbed navigation component.

### Properties
- `model` (var): Tab items array.
- `currentIndex` (int): Active tab.
- `variant` (string): `"line"`, `"pill"`, `"segmented"`, `"card"`.

---

## Accordion
Collapsible content panel.

### Properties
- `title` (string): Header text.
- `expanded` (bool): Current state.

---

## Icons & Helpers

### LucideIcon
Wrapper for SVG icons.
- `name` (string): Icon name (e.g., "home").
- `size` (real): Width and height.
- `color` (color): Icon stroke color.
- `strokeWidth` (real): Thickness (default 2).

### ScrollBar
Custom scrollbar for `Flickable` items.
- `flickable` (Item): Target view.
- `orientation` (string): `"vertical"` | `"horizontal"`.
- `permanent` (bool): Always show.

### CozySpinner
A simple spinning loader.
- `size` (real).
- `color` (color).
