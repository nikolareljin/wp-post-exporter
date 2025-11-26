# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [1.0.1] - 2025-11-26
### Changed
- Standardize constants and admin hooks under `nrpexp` prefix to avoid collisions.
- Unify export/import nonces and action slugs for consistency with WordPress guidelines.
- Update `readme.txt`: add `nreljin` to Contributors, limit tags to 5, and keep short description under 150 chars.
- Replace debug logging with `nrpexp_export_terms_error` action for term export failures.

## [1.0.0] - 2025-10-19
### Added
- Initial release of NR Post Exporter
- Export single post/page to JSON with meta, taxonomies, and revisions
- Import JSON to recreate posts; sets current user as author
- Adds Export row action and Tools → Post Import page

[1.0.0]: https://github.com/nikolareljin/nr-post-exporter/releases/tag/v1.0.0
[1.0.1]: https://github.com/nikolareljin/nr-post-exporter/releases/tag/v1.0.1
