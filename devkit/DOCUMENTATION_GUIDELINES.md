# Documentation Guidelines & Standards

## 📋 Purpose

This document establishes the **mandatory rules and standards** for all documentation in the SyncEditor project. All future work must follow these guidelines.

---

## 🚨 MANDATORY RULES

### Rule 1: Numbered Folder Structure
**ALL documentation must be organized in numbered folders within `devkit/`**

```
devkit/
├── 01-FEATURE_NAME/
├── 02-FEATURE_NAME/
├── 13-NEW_FEATURE/     ← Next feature goes here
├── 14-ANOTHER_FEATURE/ ← And so on...
└── README.md
```

**❌ NEVER place documentation files directly in root**  
**❌ NEVER place documentation files directly in devkit/**  
**✅ ALWAYS create a numbered folder first**

---

### Rule 2: Folder Naming Convention

**Format:** `##-DESCRIPTIVE_NAME`

**Examples:**
- ✅ `13-COMMENTS_FEATURE`
- ✅ `14-EXPORT_TO_CODE`
- ✅ `15-PERFORMANCE_OPTIMIZATION`
- ❌ `COMMENTS_FEATURE` (missing number)
- ❌ `13_COMMENTS_FEATURE` (wrong separator)
- ❌ `comments-feature` (not uppercase)

**Rules:**
1. **Two-digit number** (01, 02, ..., 13, 14, ...)
2. **Dash separator** between number and name
3. **UPPERCASE** with underscores for spaces
4. **Descriptive** and **concise** (2-4 words max)
5. **Chronological** - use next available number

---

### Rule 3: What Goes in Each Folder

Each numbered folder should contain **ALL documentation** related to that feature/work:

**Must Include:**
- Design documents
- Implementation plans
- API specifications
- Testing documentation
- Bug fix reports
- Code change summaries

**Can Include:**
- Screenshots/diagrams
- Configuration files
- Test data samples
- Migration scripts
- Related notes

**Example Structure:**
```
13-COMMENTS_FEATURE/
├── README.md                    ← Overview of this feature
├── DESIGN.md                    ← Feature design
├── API_SPECIFICATION.md         ← API docs
├── IMPLEMENTATION_CHECKLIST.md  ← Task list
├── TEST_RESULTS.md              ← Testing outcomes
└── SCREENSHOTS/                 ← Optional subfolder
    ├── comment-ui.png
    └── mention-popup.png
```

---

### Rule 4: Folder README Required

**EVERY numbered folder MUST have a README.md**

**Template:**
```markdown
# [Feature Name]

## Overview
Brief description of what this feature/work is about.

## Files in This Folder
- DESIGN.md - Feature design and architecture
- API_SPECIFICATION.md - API documentation
- IMPLEMENTATION_CHECKLIST.md - Task tracking
- TEST_RESULTS.md - Testing outcomes

## Status
- **Started:** [Date]
- **Completed:** [Date or "In Progress"]
- **Status:** [Planning/In Development/Testing/Complete]

## Related Folders
- Link to related documentation folders if any

## Quick Links
- [Specific section in another doc]
- [Related issue/PR]
```

---

### Rule 5: Update Index Files

**When creating a new numbered folder, MUST update:**

1. **Root `DOCUMENTATION_INDEX.md`**
   - Add new folder with description

2. **`devkit/README.md`**
   - Add to table with file count
   - Add to folder details section
   - Update statistics

**Example Update:**

```markdown
### 13-COMMENTS_FEATURE
Real-time commenting system with mentions, threads, and notifications.
```

---

## 📁 Folder Organization Patterns

### Pattern 1: Single Feature
One feature = One folder

```
13-COMMENTS_FEATURE/
├── README.md
├── DESIGN.md
├── API_SPECIFICATION.md
└── IMPLEMENTATION_CHECKLIST.md
```

### Pattern 2: Large Feature with Iterations
Large feature with multiple iterations

```
14-EXPORT_TO_CODE/
├── README.md
├── EXPORT_TO_CODE_DESIGN.md
├── ITERATION_1_REACT.md
├── ITERATION_2_FLUTTER.md
├── ITERATION_3_HTML.md
└── FINAL_IMPLEMENTATION.md
```

### Pattern 3: Bug Fix
Bug fix documentation

```
15-DRAG_DROP_BUG_FIX/
├── README.md
├── BUG_DESCRIPTION.md
├── ROOT_CAUSE_ANALYSIS.md
├── FIX_IMPLEMENTATION.md
└── TEST_VERIFICATION.md
```

### Pattern 4: Optimization/Refactoring
Performance or code improvements

```
16-PERFORMANCE_OPTIMIZATION/
├── README.md
├── PERFORMANCE_ANALYSIS.md
├── OPTIMIZATION_PLAN.md
├── BENCHMARK_RESULTS.md
└── IMPLEMENTATION_SUMMARY.md
```

---

## 📝 File Naming Conventions

### Document Files

**Format:** `DESCRIPTIVE_NAME.md`

**Rules:**
- UPPERCASE with underscores
- .md extension (Markdown)
- Descriptive and specific
- No dates in filename (use content)

**Examples:**
- ✅ `API_SPECIFICATION.md`
- ✅ `IMPLEMENTATION_CHECKLIST.md`
- ✅ `BUG_FIX_SUMMARY.md`
- ❌ `api-spec.md` (not uppercase)
- ❌ `implementation.md` (not descriptive)
- ❌ `fix_2026_09_01.md` (has date)

### Special Files

**Always Use These Names:**
- `README.md` - Folder overview (required)
- `DESIGN.md` - Design documentation
- `API_SPECIFICATION.md` - API documentation
- `IMPLEMENTATION_CHECKLIST.md` - Task tracking
- `TEST_RESULTS.md` - Testing outcomes

---

## 🔄 Workflow for New Work

### Step 1: Determine Next Number
```bash
# Check existing folders
ls devkit/

# Use next sequential number
# If last is 12-FOLLOW_FEATURE, use 13
```

### Step 2: Create Folder
```bash
mkdir devkit/13-NEW_FEATURE
```

### Step 3: Create README
Create `devkit/13-NEW_FEATURE/README.md` using template

### Step 4: Add Documentation
Add all related .md files to the folder

### Step 5: Update Indexes
Update `DOCUMENTATION_INDEX.md` and `devkit/README.md`

### Step 6: Commit
```bash
git add devkit/13-NEW_FEATURE/
git add DOCUMENTATION_INDEX.md
git add devkit/README.md
git commit -m "Add documentation for [Feature Name]"
```

---

## ❌ What NOT to Do

### Don't Do This:
```
❌ Creating doc files in root
❌ Creating doc files directly in devkit/
❌ Using unnumbered folders
❌ Skipping the README.md
❌ Not updating index files
❌ Using inconsistent naming
❌ Mixing unrelated work in one folder
```

### Do This Instead:
```
✅ Create numbered folder first
✅ Follow naming conventions
✅ Include README.md
✅ Update all index files
✅ Keep related docs together
✅ One folder per feature/work
```

---

## 📊 Folder Numbering Guide

### Current Usage (As of Sept 2026):
```
01 - PROJECT_SETUP
02 - DATABASE_SCHEMA
03 - INSTALLATION_GUIDES
04 - TESTING_PHASE_1
05 - UNDO_REDO_FEATURE
06 - NESTED_WIDGETS_V2
07 - WIDGET_FEATURES
08 - FRONTEND_INTEGRATION
09 - DEVELOPMENT_PHASES
10 - SYNC_FEATURES
11 - CURSOR_POSITION_FIX
12 - FOLLOW_FEATURE
```

### Next Available: **13**

### Reserved Ranges:
- **01-09**: Foundation & Core Features
- **10-19**: Feature Development
- **20-29**: Optimizations & Refactoring (future)
- **30-39**: Advanced Features (future)
- **40-49**: Integrations (future)

---

## 🎯 Quality Standards

### Documentation Must Be:
1. **Clear** - Easy to understand
2. **Complete** - All necessary information included
3. **Organized** - Logical structure
4. **Up-to-date** - Reflects current state
5. **Accessible** - Easy to find

### Each Document Should:
- Have a clear title/header
- Include a brief overview/summary
- Use proper markdown formatting
- Include code examples where relevant
- Link to related documents
- Specify dates/versions

---

## 📖 Markdown Standards

### Headers
```markdown
# Main Title (H1) - Use once per file
## Section (H2)
### Subsection (H3)
#### Detail (H4)
```

### Code Blocks
````markdown
```language
code here
```
````

### Lists
```markdown
- Bullet point
  - Nested point
  
1. Numbered item
2. Another item
```

### Links
```markdown
[Link Text](./path/to/file.md)
[External Link](https://example.com)
```

### Tables
```markdown
| Column 1 | Column 2 |
|----------|----------|
| Data 1   | Data 2   |
```

---

## 🔍 Examples of Good Documentation

### Example 1: Feature Documentation
```
13-COMMENTS_FEATURE/
├── README.md                      ← Overview
├── COMMENTS_FEATURE_DESIGN.md    ← Design specs
├── API_SPECIFICATION.md          ← API docs
├── IMPLEMENTATION_CHECKLIST.md   ← Tasks
├── UI_DESIGN.md                  ← UI specs
├── TEST_PLAN.md                  ← Testing
└── IMPLEMENTATION_COMPLETE.md    ← Summary
```

### Example 2: Bug Fix Documentation
```
14-WIDGET_SELECTION_BUG/
├── README.md                  ← Overview
├── BUG_REPORT.md             ← Issue description
├── ROOT_CAUSE_ANALYSIS.md    ← Investigation
├── FIX_IMPLEMENTATION.md     ← Solution
└── TEST_VERIFICATION.md      ← Testing
```

---

## ✅ Checklist for New Documentation

When creating new documentation work:

- [ ] Determined next sequential number
- [ ] Created numbered folder with correct naming
- [ ] Created README.md in the folder
- [ ] Added all relevant documentation files
- [ ] Followed file naming conventions
- [ ] Used proper markdown formatting
- [ ] Updated `DOCUMENTATION_INDEX.md`
- [ ] Updated `devkit/README.md`
- [ ] Cross-referenced related docs
- [ ] Committed with descriptive message

---

## 🚀 Benefits of This System

### For Developers:
- ✅ Easy to navigate and find documentation
- ✅ Clear development history and timeline
- ✅ Self-contained features - all info in one place
- ✅ Consistent structure across all documentation

### For Project:
- ✅ Professional documentation organization
- ✅ Easy onboarding for new team members
- ✅ Clear audit trail of development
- ✅ Maintainable and scalable structure

### For Future:
- ✅ Can easily add more features (13, 14, 15...)
- ✅ Clear pattern to follow
- ✅ No confusion about where to put docs
- ✅ Easy to archive or reference old work

---

## 📞 Questions?

If you're unsure about:
- **Where to put documentation**: Create a new numbered folder
- **What to name it**: Use the pattern `##-FEATURE_NAME`
- **What to include**: Put ALL related docs in the folder
- **Existing docs**: Check similar folders for examples

---

## 🔄 Maintaining This System

### Monthly Review:
- Check all folders have README.md
- Verify index files are up-to-date
- Ensure naming conventions are followed
- Archive completed work if needed

### When Adding Team Members:
- Direct them to this file first
- Show them the folder structure
- Explain the numbering system
- Review examples together

---

## 📜 Summary

**Golden Rules:**
1. 📁 Always use numbered folders in devkit/
2. 📝 Always include README.md in each folder
3. 📊 Always update index files
4. 🔤 Always follow naming conventions
5. 🗂️ Keep related work together

**Remember:** This system exists to make documentation **easy to find**, **easy to understand**, and **easy to maintain**.

---

**Established:** September 1, 2026  
**Last Updated:** September 1, 2026  
**Status:** Active  
**Compliance:** Mandatory for all team members
