# Scaling & Collaboration Plan

## Overview

Implementation plan covering three problems found while reviewing the current architecture: every edit rewrites the entire page's JSON instead of just what changed, concurrent edits from two people can silently overwrite one another with no safety check, and there's no Projects layer above Pages yet. The plan fixes these by normalizing widgets into their own database rows, closing the write-safety gap with an optimistic per-row check instead of locking, and adding Projects/multi-tenancy support on top.

## Files in This Folder

- `IMPLEMENTATION_CHECKLIST.md` - Full phased task checklist (Tracks A-F), with suggested execution order and dependencies

## Status

- **Started:** 2026-09-27
- **Completed:** In Progress
- **Status:** Planning

## Related Folders

- [10-SYNC_FEATURES](../10-SYNC_FEATURES/) - the existing real-time sync implementation this plan builds on and reworks
- [12-FOLLOW_FEATURE](../12-FOLLOW_FEATURE/) - referenced by Track C's optional "someone's editing this" awareness indicator

## Quick Links

- [Implementation Checklist](./IMPLEMENTATION_CHECKLIST.md)
