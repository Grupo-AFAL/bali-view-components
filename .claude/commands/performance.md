# Rails Performance Analysis

Analyze Rails application performance across runtime, development, and test environments.

## Usage

```
/performance $ARGUMENTS
```

Where `$ARGUMENTS` can be:

| Argument | Description |
|----------|-------------|
| (empty) | Full analysis across all domains |
| `runtime` | Focus on query/memory/caching performance |
| `dev` | Focus on development speed (boot time, assets, workflow) |
| `test` | Focus on test suite speed |
| `--quick` | Static analysis only (no profiling) |
| `--profile` | Include active profiling (runs benchmarks) |
| `[file/path]` | Analyze specific file or directory |

## Examples

```bash
# Full analysis
/performance

# Just test suite speed
/performance test

# Quick scan of a controller
/performance app/controllers/orders_controller.rb --quick

# Deep runtime analysis with profiling
/performance runtime --profile
```

## Workflow

### Step 1: Determine Scope

Based on arguments, identify what to analyze:

| Argument | Scope |
|----------|-------|
| (empty) | All three domains |
| `runtime` | N+1, indexes, memory, caching |
| `dev` | Boot time, assets, file watching |
| `test` | Slow tests, factories, parallelization |
| `[file]` | Focused analysis on that file |

### Step 2: Static Analysis (Always Run)

**For Runtime:**
```bash
# Search for N+1 patterns
grep -rn "\.each.*|.*|.*\." app/ --include="*.rb" | head -50

# Check for pluck opportunities
grep -rn "\.all\.map" app/ --include="*.rb"

# Check for missing includes
grep -rn "belongs_to\|has_many\|has_one" app/models/ --include="*.rb"
```

**For Development:**
```bash
# Check Gemfile for performance gems
grep -E "bootsnap|spring|listen" Gemfile

# Check eager_load settings
grep -rn "eager_load" config/environments/
```

**For Tests:**
```bash
# Check test setup
grep -rn "before.*:each\|before.*:all" spec/ --include="*.rb" | head -20

# Check factory usage patterns
grep -rn "create(\|build(" spec/ --include="*.rb" | wc -l
grep -rn "build_stubbed(" spec/ --include="*.rb" | wc -l
```

### Step 3: Active Profiling (If --profile)

**For Runtime:**
```bash
# Boot time
time bundle exec rails runner "puts 'booted'"

# Query profiling (if development server accessible)
# Use rack-mini-profiler or bullet output
```

**For Tests:**
```bash
# Profile slow tests
bundle exec rspec --profile 10

# If test-prof available
TEST_PROF=1 bundle exec rspec spec/ --format documentation 2>&1 | head -100
```

### Step 4: Invoke Rails Performance Expert Agent

Use the `rails-performance-expert` agent to:
1. Analyze findings from static analysis
2. Correlate patterns across domains
3. Prioritize by business impact
4. Generate actionable report

### Step 5: Generate Report

```markdown
# Performance Analysis Report

## Analyzed: [scope]
## Mode: [quick | full | profile]

## Executive Summary
[Main findings and recommended focus area]

## Critical Issues

### [Issue 1]
- **Domain**: Runtime/Dev/Test
- **Location**: file:line
- **Impact**: [Quantified]
- **Fix**: [Code example]

## Metrics (if profiled)

| Metric | Value | Status |
|--------|-------|--------|
| Boot time | X.Xs | ✓/⚠/✗ |
| Test suite | X.Xs | ✓/⚠/✗ |
| Query count | N | ✓/⚠/✗ |

## Recommendations

1. [Highest ROI fix]
2. [Second priority]
3. [Third priority]

## Tools to Add

[Suggest gems that would help ongoing monitoring]
```

## Thresholds

Use these as guidelines for flagging issues:

| Metric | Good | Warning | Critical |
|--------|------|---------|----------|
| Rails boot (dev) | < 3s | 3-8s | > 8s |
| Test suite (full) | < 60s | 60-180s | > 180s |
| Queries per request | < 10 | 10-50 | > 50 |
| Memory per request | < 50MB | 50-100MB | > 100MB |

## Bali-Specific Checks

For this ViewComponent library:

### Component Tests
```bash
# Count render_inline calls
grep -rn "render_inline" spec/components/ --include="*.rb" | wc -l

# Check for expensive setup
grep -rn "before.*do" spec/components/ --include="*.rb"
```

### Lookbook Previews
```bash
# Check for unbounded queries in previews
grep -rn "\.all" app/components/*/preview.rb
grep -rn "\.all" spec/dummy/app/components/*/preview.rb
```

### Asset Build
```bash
# Measure Tailwind build time
time bin/rails tailwindcss:build 2>&1

# Check content paths
grep -A 10 "content:" spec/dummy/tailwind.config.js
```

## Quick Reference

### Immediate Wins (Usually Safe)

| Issue | Quick Fix |
|-------|-----------|
| Missing bootsnap | Add gem, require in boot.rb |
| N+1 in controller | Add `.includes(:assoc)` |
| Factory cascade | Use `build_stubbed` |
| Slow before(:each) | Check if can be before(:all) |

### Needs Investigation

| Issue | Next Step |
|-------|-----------|
| High memory | Profile with derailed |
| Slow queries | EXPLAIN ANALYZE |
| Test isolation issues | Check database_cleaner strategy |
