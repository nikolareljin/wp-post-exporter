# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased] - 2025-10-31
### Changed
- Standardized plugin-specific constants and admin hooks to the `nrpexp` prefix to avoid collisions.
- Unified export/import nonces and action slugs under the new prefix for consistency with WordPress guidelines.
- Updated `readme.txt` metadata: added contributor `nreljin`, trimmed tags to five, and shortened the description to WordPress.org limits.
- Swapped `error_log()` call for the `nrpexp_export_terms_error` action to surface term export failures without shipping debug logging.

## [1.0.0] - 2025-10-19
### Added
- Initial release of NR Post Exporter
- Export single post/page to JSON with meta, taxonomies, and revisions
- Import JSON to recreate posts; sets current user as author
- Adds Export row action and Tools → Post Import page

[1.0.0]: https://github.com/nikolareljin/nr-post-exporter/releases/tag/v1.0.0
