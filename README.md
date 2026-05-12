# AutoCAD Dynamic Block Configurator

An interactive AutoCAD LISP tool for seamlessly configuring and inserting dynamic blocks from library files with real-time parameter customization.

## 🎯 Features

- **Interactive Block Selection**: Browse and select from all available dynamic blocks in a library DWG file
- **Visibility State Management**: Choose from multiple visibility states for each dynamic block
- **Dynamic Parameter Editing**: Modify numeric parameters with live preview and regeneration
- **Visibility-Based Filtering**: Automatically filter and display parameters relevant to the selected visibility state
- **Safe User Input**: Validated menu selections with error handling
- **Real-Time Feedback**: Visual indicators and status messages throughout the workflow
- **Flexible Insertion**: Pick custom insertion points or keep default placement

## 📋 Requirements

- **AutoCAD** 2018 or later
- **Active Document** in AutoCAD with ModelSpace available
- **Dynamic Block Library** (DWG file with dynamic blocks)

## 🚀 Installation

1. Download or clone this repository:
   ```bash
   git clone https://github.com/jeyapandiv/autocad-dynamic-block-configurator.git
   ```

2. In AutoCAD, load the LISP file:
   ```
   (load "DynamicBlockConfigurator.lsp")
   ```

3. Or use AutoCAD's **File** → **Load Application** menu

## 💻 Usage

### Starting the Tool

Type the command in AutoCAD:
```
GetDynBlk
```

### Workflow (11 Steps)

1. **Select Library DWG** - Choose a DWG file containing dynamic blocks
2. **Load Blocks** - Tool scans and lists all available dynamic blocks
3. **Select Block** - Choose which dynamic block to insert
4. **Load Definition** - Block definition is imported if not already in current document
5. **Create Instance** - Temporary block instance created for configuration
6. **Select Visibility** - Choose from available visibility states
7. **Apply Visibility** - Visibility state applied and preview updated
8. **Filter Parameters** - Parameters displayed based on selected visibility
9. **Select Parameters** - Choose which parameters to modify (can be multiple)
10. **Enter Values** - Input new values for selected parameters
11. **Pick Insertion Point** - Click to place configured block in drawing

## 🔧 Core Functions

### Main Command
- `c:GetDynBlk` - Entry point for the tool

### Utility Functions
- `get-choice-safe` - Safe menu selection with validation
- `select-dwg-file` - File picker dialog with validation
- `get-blocks-from-dwg` - Extract dynamic blocks from library
- `get-visibility-states` - List visibility options
- `set-visibility-by-name` - Apply visibility state
- `get-all-numeric-parameters` - Extract modifiable parameters
- `select-params-to-modify` - Interactive parameter selection
- `set-parameter-value` - Update parameter with regeneration

### Support Functions
- `get-params-for-visibility` - Visibility-to-parameter mapping
- `safe-allowed-values-to-list` - Safe array conversion

## 🎨 Visibility Parameter Mapping

The tool supports automatic parameter filtering based on visibility states:

```lisp
PLAN*       → Distance1, Distance3
SECTION*    → Distance2, Distance9
ELEVATION*  → Distance1, Distance4
```

Custom mappings can be added in the `get-params-for-visibility` function.

## 📝 Example Workflow

```
1. Run: GetDynBlk
2. Select: "C:\Libraries\BlockLibrary.dwg"
3. Choose: "Door_Swing" block
4. Select: "Left Swing" visibility
5. Modify: Height = 2100, Width = 900
6. Pick: Insertion point in drawing
7. Result: Configured dynamic block inserted
```

## ⚙️ Configuration

### Adding Custom Parameter Mappings

Edit `get-params-for-visibility` function:

```lisp
((wcmatch vis "YOURPATTERN*")
 (setq params '("Param1" "Param2"))
)
```

### Customizing Parameter Display

Modify `get-all-numeric-parameters` to include/exclude specific parameter types.

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| "No dynamic blocks found" | Ensure DWG contains properly defined dynamic blocks |
| Parameters not updating | Check block isn't locked; verify parameter names match |
| Visibility not changing | Confirm visibility state name matches exactly |
| Tool stops unexpectedly | Check AutoCAD console for LISP errors |

## 🤝 Contributing

Issues and pull requests are welcome!

## 📄 License

This project is open source and available under the MIT License.

## 👤 Author

**jeyapandiv** - AutoCAD LISP Developer

## 📧 Support

For issues, questions, or suggestions, please open an issue on GitHub.

---

**Version**: 1.0.0  
**Last Updated**: May 12, 2026  
**Status**: Production Ready ✅