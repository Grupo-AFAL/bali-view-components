# Bali Components - Tailwind/DaisyUI Migration Status

> **Detailed Migration Log**: See [.claude/migration-log.md](.claude/migration-log.md) for detailed change history, class mappings, and learnings from each migration.

## Legend
- :white_check_mark: Verified & Fixed (complete migration)
- :large_orange_diamond: Partially migrated (needs verification)
- :x: Not migrated (still uses Bulma)
- :grey_question: Unknown status

## Components Checklist

| Component | Migration Status | Verified | Tests | Notes |
|-----------|-----------------|----------|-------|-------|
| ActionsDropdown | :large_orange_diamond: | :x: | - | Migrated in a89f03a |
| Avatar | :grey_question: | :x: | :white_check_mark: | - |
| BooleanIcon | :large_orange_diamond: | :x: | :white_check_mark: | Migrated in fcae709 |
| Breadcrumb | :grey_question: | :x: | :white_check_mark: | - |
| BulkActions | :grey_question: | :x: | - | - |
| Calendar | :large_orange_diamond: | :x: | :white_check_mark: | Migrated in 65b05af |
| Card | :large_orange_diamond: | :x: | :white_check_mark: | Migrated in a89f03a |
| Carousel | :grey_question: | :x: | :white_check_mark: | - |
| Chart | :grey_question: | :x: | :white_check_mark: | - |
| Clipboard | :grey_question: | :x: | :white_check_mark: | - |
| **Columns** | :white_check_mark: | :white_check_mark: | :white_check_mark: | **Fully verified & fixed** - CSS Grid |
| DataTable | :large_orange_diamond: | :x: | :white_check_mark: | Migrated in 65b05af |
| DeleteLink | :large_orange_diamond: | :x: | :white_check_mark: | Migrated in 3c9cde2 |
| Drawer | :large_orange_diamond: | :x: | :white_check_mark: | Migrated in 3c9cde2 |
| Dropdown | :large_orange_diamond: | :x: | :white_check_mark: | Migrated in a89f03a |
| FieldGroupWrapper | :grey_question: | :x: | :white_check_mark: | - |
| Filters | :large_orange_diamond: | :x: | :white_check_mark: | Migrated in 65b05af |
| FlashNotifications | :grey_question: | :x: | :white_check_mark: | - |
| Form | :grey_question: | :x: | - | - |
| GanttChart | :large_orange_diamond: | :x: | - | Migrated in 65b05af |
| Heatmap | :grey_question: | :x: | :white_check_mark: | - |
| Hero | :large_orange_diamond: | :x: | :white_check_mark: | Migrated in 3c9cde2 |
| HoverCard | :grey_question: | :x: | :white_check_mark: | - |
| Icon | :grey_question: | :x: | :white_check_mark: | - |
| ImageField | :grey_question: | :x: | - | - |
| ImageGrid | :grey_question: | :x: | :white_check_mark: | - |
| InfoLevel | :large_orange_diamond: | :x: | :white_check_mark: | Migrated in 0b2c882 |
| LabelValue | :large_orange_diamond: | :x: | :white_check_mark: | Migrated in 0b2c882 |
| Level | :large_orange_diamond: | :x: | :white_check_mark: | Migrated in 0b2c882 |
| Link | :large_orange_diamond: | :x: | :white_check_mark: | Migrated in a89f03a |
| List | :large_orange_diamond: | :x: | :white_check_mark: | Migrated in fcae709 |
| Loader | :grey_question: | :x: | :white_check_mark: | - |
| LocationsMap | :grey_question: | :x: | :white_check_mark: | - |
| Message | :large_orange_diamond: | :x: | :white_check_mark: | Migrated in 3c9cde2 |
| Modal | :grey_question: | :x: | :white_check_mark: | Uses DaisyUI classes |
| Navbar | :large_orange_diamond: | :x: | :white_check_mark: | Migrated in 3c9cde2 |
| Notification | :grey_question: | :x: | :white_check_mark: | - |
| PageHeader | :large_orange_diamond: | :x: | :white_check_mark: | Migrated in 0b2c882 |
| Progress | :grey_question: | :x: | :white_check_mark: | - |
| PropertiesTable | :grey_question: | :x: | :white_check_mark: | - |
| Rate | :grey_question: | :x: | :white_check_mark: | - |
| RecurrentEventRuleForm | :grey_question: | :x: | - | - |
| Reveal | :grey_question: | :x: | :white_check_mark: | - |
| RichTextEditor | :grey_question: | :x: | :white_check_mark: | - |
| SearchInput | :large_orange_diamond: | :x: | :white_check_mark: | Migrated in 0b2c882 |
| SideMenu | :large_orange_diamond: | :x: | :white_check_mark: | Migrated in 3c9cde2 |
| SortableList | :grey_question: | :x: | :white_check_mark: | - |
| Stepper | :grey_question: | :x: | :white_check_mark: | - |
| Table | :large_orange_diamond: | :x: | :white_check_mark: | Migrated in 3c9cde2 |
| Tabs | :large_orange_diamond: | :x: | :white_check_mark: | Migrated in a89f03a |
| Tag | :grey_question: | :x: | :white_check_mark: | - |
| Tags | :grey_question: | :x: | :white_check_mark: | - |
| Timeago | :grey_question: | :x: | :white_check_mark: | - |
| Timeline | :grey_question: | :x: | :white_check_mark: | - |
| Tooltip | :grey_question: | :x: | :white_check_mark: | - |
| TreeView | :grey_question: | :x: | :white_check_mark: | - |
| TurboNativeApp | :grey_question: | :x: | :white_check_mark: | - |

## Summary

| Status | Count |
|--------|-------|
| :white_check_mark: Fully Verified | 1 |
| :large_orange_diamond: Partially Migrated | 22 |
| :grey_question: Unknown/Not Started | 34 |
| **Total Components** | **57** |

## Verification Commands

To verify a component:
```bash
/verify-component [ComponentName]
```

To fix issues found:
```bash
/fix-component [ComponentName]
```

To run full verify→fix→verify loop:
```bash
/component-cycle [ComponentName] --max-iterations:3
```

## Recently Verified

### Columns (2026-01-11)
- **Status**: :white_check_mark: Complete
- **Changes**: 
  - Migrated from Bulma `is-*` classes to Tailwind CSS Grid
  - Container: `grid grid-cols-12 gap-4`
  - Added `size:` param (`:half`, `:third`, `:quarter`, etc.)
  - Added `offset:` param (`:quarter`, `:third`, `:half`)
  - 15 tests passing
- **Commit**: Pending

## Next Steps

1. Run `/verify-component` on all :large_orange_diamond: components
2. Fix any issues found
3. Update this checklist as components are verified
