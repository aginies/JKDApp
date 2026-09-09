# AGENTS.md - Code Organization Guidelines

## Mandatory Code Splitting Requirements

This document establishes **mandatory requirements** for AI agents and developers working on this Flutter project. Code splitting into sub-files is not optional—it is a fundamental architectural requirement that must be enforced at all times.

## 🚨 CRITICAL RULE: No Single File Over 1,500 Lines

**ABSOLUTE MAXIMUM:** Any single Dart file exceeding **1,500 lines** MUST be immediately refactored into smaller, focused sub-files.

**RECOMMENDED TARGET:** Keep individual files under **500 lines** whenever possible.

**REAL-WORLD EXAMPLE:** The `series_detail_screen.dart` file reached **3,807 lines** and became unmaintainable, causing:

- Difficulty finding specific methods
- Complex merge conflicts during team development
- IDE performance issues
- Testing complexity due to mixed concerns
- Refactoring challenges

## 📋 Mandatory Code Splitting Triggers

### Immediate Action Required When

- ✅ Any file exceeds 1,500 lines
- ✅ A class has more than 15 methods
- ✅ Multiple distinct responsibilities exist in one file
- ✅ Code becomes difficult to navigate or understand
- ✅ Testing becomes complex due to mixed concerns
- ✅ Multiple developers need to work on the same file simultaneously
- ✅ Methods exceed 100 lines each
- ✅ Import statements exceed 30 lines
- ✅ Nested widget trees become too deep (>5 levels)

### File Size Categories

- 🟢 **0-500 lines**: Acceptable, optimal for maintainability
- 🟡 **501-1,500 lines**: Refactoring recommended, plan extraction
- 🔴 **1,500+ lines**: IMMEDIATE refactoring required, halt feature development

### Technical Debt Indicators

- **Scroll fatigue**: Taking >5 seconds to find a method
- **Method density**: >50 methods in a single class
- **Import bloat**: >30 import statements
- **Mixed concerns**: UI, business logic, and utilities in same file
- **Deep nesting**: Widget trees >5 levels deep
- **Duplicate patterns**: Similar code blocks repeated >3 times

## 🏗️ Mandatory Splitting Strategies

### 1. **Services Pattern** (REQUIRED for business logic)

```
lib/screens/[screen_name]/services/
├── [feature]_service.dart         # Business logic (200-400 lines max)
├── [api]_service.dart            # External integrations (150-300 lines max)
├── [media]_service.dart          # Media handling (200-350 lines max)
├── [voice]_service.dart          # Voice processing (100-200 lines max)
├── [training]_service.dart       # Training workflows (200-400 lines max)
└── [utility]_service.dart        # Helper functions (100-250 lines max)
```

**Service Class Template:**

```dart
/// Service for handling [specific functionality]
class FeatureService {
  // Private fields
  final SomeRepository _repository = SomeRepository();
  
  // Public methods (max 10-12 per service)
  Future<Result> performAction() async { ... }
  
  void handleEvent() { ... }
  
  // Private helper methods
  void _helperMethod() { ... }
}
```

### 2. **Mixins Pattern** (REQUIRED for shared utilities)

```
lib/screens/[screen_name]/mixins/
├── [screen]_utils.dart           # Reusable utility methods (100-200 lines max)
├── [validation]_mixin.dart       # Input validation (50-150 lines max)
├── [formatting]_mixin.dart       # Data formatting (50-100 lines max)
└── [navigation]_mixin.dart       # Navigation helpers (50-100 lines max)
```

**Mixin Template:**

```dart
/// Mixin containing utility methods for [specific purpose]
mixin ScreenUtils {
  // Required getters that implementing class must provide
  List<Item> get items;
  ScrollController get scrollController;
  
  // Utility methods (max 8-10 per mixin)
  String getDisplayNumber(int index) { ... }
  void scrollToIndex(int index) { ... }
  List<String> getAvailableOptions() { ... }
}
```

### 3. **Widgets Pattern** (REQUIRED for UI components)

```
lib/screens/[screen_name]/widgets/
├── [component]_widget.dart       # Reusable UI components (150-300 lines max)
├── [dialog]_widget.dart         # Dialog components (100-250 lines max)
├── [list_item]_widget.dart      # List item components (50-150 lines max)
├── [card]_widget.dart           # Card components (100-200 lines max)
└── [form]_widget.dart           # Form components (200-400 lines max)
```

**Widget Class Guidelines:**

- Single responsibility: One widget = one UI concern
- Max 5-7 parameters in constructor
- Use composition over inheritance
- Extract sub-widgets when build() method > 50 lines

### 4. **Controllers Pattern** (REQUIRED for state management)

```
lib/screens/[screen_name]/controllers/
├── [feature]_controller.dart     # State management logic (200-400 lines max)
├── [form]_controller.dart        # Form state management (150-300 lines max)
└── [animation]_controller.dart   # Animation controllers (100-200 lines max)
```

### 5. **Models Pattern** (REQUIRED for data structures)

```
lib/screens/[screen_name]/models/
├── [data]_model.dart            # Data models and DTOs (100-200 lines max)
├── [request]_model.dart         # API request models (50-150 lines max)
├── [response]_model.dart        # API response models (50-150 lines max)
└── [view]_model.dart            # View-specific models (50-100 lines max)
```

### 6. **Constants Pattern** (REQUIRED for configuration)

```
lib/screens/[screen_name]/constants/
├── [screen]_constants.dart      # Configuration and constants (50-100 lines max)
├── [api]_constants.dart         # API endpoints and keys (30-70 lines max)
└── [ui]_constants.dart          # UI constants (colors, sizes) (50-100 lines max)
```

### 7. **Dialogs Pattern** (REQUIRED for modal interfaces)

```
lib/screens/[screen_name]/dialogs/
├── [action]_dialog.dart         # Action dialogs (100-200 lines max)
├── [confirmation]_dialog.dart   # Confirmation dialogs (50-150 lines max)
├── [help]_dialog.dart           # Help and info dialogs (100-250 lines max)
└── [input]_dialog.dart          # Input dialogs (150-300 lines max)
```

## 🎯 Specific Splitting Requirements

### Screen Files Must Split When Containing

- **Media/Gallery Logic** → `services/media_gallery_service.dart` (195 lines extracted)
- **Voice Processing** → `services/voice_processing_service.dart` (85 lines extracted)
- **Training/Workflow Logic** → `services/training_management_service.dart` (118 lines extracted)
- **Network/API Calls** → `services/api_service.dart` (200-400 lines typical)
- **Database Operations** → `services/database_service.dart` (300-500 lines typical)
- **Utility Methods** → `mixins/[screen]_utils.dart` (108 lines extracted)
- **Complex UI Builders** → `widgets/[component]_widget.dart` (200-400 lines typical)
- **Dialog Definitions** → `dialogs/[dialog]_dialog.dart` (95 lines extracted)
- **Form Handling** → `controllers/form_controller.dart` (200-300 lines typical)
- **State Management** → `controllers/state_controller.dart` (150-400 lines typical)

### Widget Files Must Split When Containing

- **Multiple Widget Classes** → Separate files per widget (1 widget = 1 file rule)
- **Business Logic** → Move to services (no business logic in widgets)
- **Complex State** → Move to controllers (widgets should be mostly stateless)
- **Utility Functions** → Move to mixins (pure functions separate from UI)
- **API Calls** → Move to services (no network calls in widgets)
- **Database Access** → Move to services (no direct DB access in widgets)

## 🔧 Implementation Requirements

### For AI Agents

1. **MUST** analyze file size before any modifications (`wc -l filename.dart`)
2. **MUST** propose splitting strategy if file > 1,500 lines
3. **MUST** implement splitting before adding new features
4. **MUST** update imports and dependencies correctly
5. **MUST** run `flutter analyze` after splitting
6. **MUST** verify build success after refactoring (`flutter build apk --debug`)
7. **MUST** test functionality after refactoring
8. **MUST** maintain backwards compatibility during splitting
9. **MUST** preserve all existing functionality during extraction
10. **MUST** use proper naming conventions for extracted files

### For Developers

1. **MUST** follow splitting guidelines for all new code
2. **MUST** refactor existing large files before modification
3. **MUST** review file sizes in code reviews
4. **MUST** reject PRs with files exceeding limits
5. **MUST** document splitting decisions in commit messages
6. **MUST** run tests after refactoring
7. **MUST** update documentation when splitting files
8. **MUST** coordinate with team when splitting shared files

## 📊 Enforcement & Monitoring

### Pre-Commit Hooks (REQUIRED)

```bash
# Check file sizes before commit
find lib -name "*.dart" -exec wc -l {} + | awk '$1 > 1500 {print "ERROR: " $2 " has " $1 " lines (max 1500)"; exit 1}'

# Check for mixed concerns
grep -r "class.*Service.*extends.*Widget" lib/ && echo "ERROR: Services should not extend Widget"

# Check for business logic in widgets
grep -r "http\|database\|api" lib/widgets/ && echo "WARNING: Business logic detected in widgets"
```

### Automated Analysis Tools

```bash
# Complexity analysis
flutter packages pub run dart_code_metrics:metrics analyze lib

# Architecture validation
flutter packages pub run dependency_validator

# Code quality check
flutter analyze --fatal-infos
```

### Code Review Checklist (MANDATORY)

- [ ] No single file exceeds 1,500 lines
- [ ] Business logic is in services (not widgets)
- [ ] UI components are in widgets (not services)
- [ ] Utility methods are in mixins (reusable across classes)
- [ ] All imports are correct and necessary
- [ ] `flutter analyze` passes with no warnings
- [ ] Build succeeds on all platforms
- [ ] Tests pass after refactoring
- [ ] No code duplication between extracted files
- [ ] Proper error handling in all extracted methods
- [ ] Documentation updated for architectural changes

## 🎯 Success Example: Series Detail Refactoring

### **Before Refactoring:**

- `series_detail_screen.dart`: **3,807 lines** ❌ (CRITICAL VIOLATION)
- Single monolithic file with mixed concerns
- Difficult to navigate and maintain
- Multiple developers couldn't work simultaneously
- Complex testing due to interdependencies
- IDE performance issues during editing
- Merge conflicts were frequent and complex

### **After Refactoring (Phase 1 & 4):**

- `series_detail_screen.dart`: **3,476 lines** ❌ (Still needs more work)
- `media_gallery_service.dart`: **195 lines** ✅
- `voice_processing_service.dart`: **85 lines** ✅  
- `training_management_service.dart`: **118 lines** ✅
- `series_detail_utils.dart`: **108 lines** ✅
- `workflow_help_dialog.dart`: **95 lines** ✅

### **Measurable Improvements:**

- **331 lines** removed from main file
- **601 lines** of well-organized code in dedicated files
- **5 new reusable components** created
- **Zero breaking changes** during refactoring
- **Clean service architecture** with proper separation
- **Improved testability** with isolated components

### **Next Steps Required:**

- Extract picker management (**~800 lines**) → `services/picker_management_service.dart`
- Extract UI builders (**~600 lines**) → `services/ui_builder_service.dart`
- Extract move management (**~400 lines**) → `services/move_management_service.dart`
- Extract series operations (**~300 lines**) → `services/series_operations_service.dart`
- **Target:** Main screen under **1,500 lines** (compliance achieved)

### **Technical Debt Eliminated:**

- ✅ Mixed responsibilities separated
- ✅ Service layer properly implemented
- ✅ Utility methods made reusable via mixins
- ✅ Dialog components isolated
- ✅ Import cleanup completed
- ✅ Code duplication eliminated
- ✅ Error handling improved

## 🚫 Anti-Patterns to Avoid

### NEVER DO

- ❌ Add features to files > 1,500 lines without splitting first
- ❌ Mix business logic with UI code (services in widgets)
- ❌ Put multiple unrelated classes in one file
- ❌ Create "God classes" that do everything
- ❌ Ignore file size warnings during development
- ❌ Skip refactoring due to "time constraints"
- ❌ Copy-paste code instead of creating reusable components
- ❌ Put API calls directly in widget build methods
- ❌ Store business logic in StatefulWidget classes
- ❌ Create services that depend on UI frameworks
- ❌ Mix data models with view logic
- ❌ Create circular dependencies between services

### WARNING SIGNS

- 🚨 Difficult to find specific methods (scroll time > 5 seconds)
- 🚨 Long scroll times to navigate file (>1500 lines visible)
- 🚨 Multiple developers editing same file simultaneously
- 🚨 Complex merge conflicts during team development
- 🚨 Testing requires mocking many dependencies
- 🚨 IDE performance issues with large files (syntax lag)
- 🚨 Build times increase significantly
- 🚨 Code reviews take > 30 minutes per file
- 🚨 Bug fixes require changes in multiple unrelated sections
- 🚨 New feature additions affect existing functionality

### Code Smell Detection

```bash
# Detect overly large files
find lib -name "*.dart" -exec wc -l {} + | sort -nr | head -10

# Detect complex methods (>50 lines)
grep -n "^[[:space:]]*[a-zA-Z].*{" lib/**/*.dart | wc -l

# Detect import bloat (>30 imports)
grep -c "^import " lib/**/*.dart | awk -F: '$2 > 30 {print $1 " has " $2 " imports"}'
```

## ✅ Benefits of Mandatory Splitting

### Code Quality Benefits

- **Maintainability**: Each file has single responsibility (easier to understand)
- **Testability**: Isolated components can be unit tested independently
- **Reusability**: Services and mixins can be shared across multiple screens
- **Readability**: Focused files reduce cognitive load for developers
- **Debugging**: Easier to trace bugs when concerns are separated
- **Documentation**: Smaller files are easier to document thoroughly

### Team Productivity Benefits

- **Parallel Development**: Multiple developers can work on different services
- **Reduced Conflicts**: Smaller files result in fewer merge conflicts
- **Faster Reviews**: Code reviews are more focused and faster
- **Better Architecture**: Forces proper separation of concerns
- **Knowledge Sharing**: Easier to onboard new team members
- **Specialization**: Developers can specialize in specific services

### Performance Benefits

- **IDE Performance**: Better syntax highlighting and code analysis
- **Build Performance**: Incremental compilation benefits from smaller files
- **Memory Usage**: Lower memory footprint during development
- **Tree Shaking**: Better dead code elimination in production builds
- **Hot Reload**: Faster hot reload cycles with smaller compilation units
- **Debug Performance**: Faster debugging with focused call stacks

### Technical Debt Reduction

- **Lower Complexity**: Smaller files have lower cyclomatic complexity
- **Easier Refactoring**: Isolated components are safer to refactor
- **Better Testing**: Higher test coverage with focused components
- **Reduced Duplication**: Services eliminate code duplication
- **Clear Dependencies**: Explicit import statements show relationships
- **Version Control**: Better diff tracking with smaller files

## 📝 Implementation Checklist

For every file modification, agents and developers MUST:

### Pre-Modification Analysis

- [ ] Check current file size (`wc -l filename.dart`)
- [ ] Analyze file complexity (`grep -c "^[[:space:]]*[a-zA-Z].*{" filename.dart`)
- [ ] Review import count (`grep -c "^import " filename.dart`)
- [ ] Identify mixed concerns (UI + business logic)
- [ ] Document current functionality before changes

### Splitting Strategy (if > 1,500 lines)

- [ ] Plan splitting strategy BEFORE making changes
- [ ] Identify logical boundaries (services, widgets, utilities)
- [ ] Create appropriate subdirectories (services/, widgets/, mixins/, etc.)
- [ ] Design service interfaces and dependencies
- [ ] Plan data flow between components

### Extraction Process

- [ ] Extract logical components to separate files (largest concerns first)
- [ ] Maintain single responsibility per extracted file
- [ ] Create proper class/service interfaces
- [ ] Update all imports and dependencies
- [ ] Preserve existing functionality during extraction
- [ ] Add proper documentation to extracted components

### Quality Assurance

- [ ] Run `flutter analyze` and fix any issues
- [ ] Test build success with `flutter build apk --debug`
- [ ] Verify functionality still works correctly
- [ ] Run unit tests and fix any failures
- [ ] Check for performance regressions
- [ ] Validate error handling in extracted components

### Documentation and Cleanup

- [ ] Update documentation if needed
- [ ] Remove unused imports and dead code
- [ ] Add proper comments to complex methods
- [ ] Update README or architectural documentation
- [ ] Record refactoring decisions in commit messages

### Team Coordination

- [ ] Communicate breaking changes to team
- [ ] Update shared utilities and dependencies
- [ ] Coordinate with other developers working on related code
- [ ] Update development guidelines if patterns emerge

## 🛠️ Tools and Automation

### Recommended VS Code Extensions

- **Dart Code Metrics**: Analyze code complexity
- **Flutter Widget Inspector**: Visualize widget trees
- **GitLens**: Track code changes and history
- **Error Lens**: Show analysis issues inline

### CLI Tools for Analysis

```bash
# File size analysis
find lib -name "*.dart" | xargs wc -l | sort -nr

# Complexity metrics  
flutter packages pub run dart_code_metrics:metrics analyze lib

# Dependency analysis
flutter packages pub run dependency_validator

# Architecture validation
flutter analyze --fatal-infos --fatal-warnings
```

### Automated Refactoring Scripts

```bash
# Extract service template
create_service() {
  SERVICE_NAME=$1
  SCREEN_NAME=$2
  mkdir -p "lib/screens/${SCREEN_NAME}/services"
  cp templates/service_template.dart "lib/screens/${SCREEN_NAME}/services/${SERVICE_NAME}_service.dart"
}

# Extract widget template  
create_widget() {
  WIDGET_NAME=$1
  SCREEN_NAME=$2
  mkdir -p "lib/screens/${SCREEN_NAME}/widgets"
  cp templates/widget_template.dart "lib/screens/${SCREEN_NAME}/widgets/${WIDGET_NAME}_widget.dart"
}
```

## 🎯 Conclusion

Code splitting is not a suggestion—it's a **mandatory architectural requirement**. Every AI agent and developer working on this project MUST follow these guidelines to ensure maintainable, scalable, and high-quality code.

### Key Principles

1. **1,500 lines maximum** - Non-negotiable hard limit
2. **Single Responsibility** - One file, one concern  
3. **Service Layer** - Business logic separate from UI
4. **Composition over Inheritance** - Use mixins and services
5. **Test-Driven Refactoring** - Maintain functionality during splits
6. **Team Coordination** - Communicate architectural changes

### Success Metrics

- Files stay under 1,500 lines (compliance)
- Build times remain stable (performance)
- Test coverage increases (quality)
- Merge conflicts decrease (productivity)
- Code review time decreases (efficiency)
- Bug fixing time decreases (maintainability)

**Remember: A codebase with properly split files is a codebase that can grow and evolve successfully over time.**

*Every line of code should have a clear home, every file should have a single purpose, and every change should improve the overall architecture.*

---

*This document must be reviewed and updated as the project evolves, but the core principle of mandatory code splitting remains non-negotiable.*
