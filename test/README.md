Test Environment for WP Post Exporter

What this does
- Spins up a minimal WordPress Multisite (subdirectory) on http://localhost:8080 with MariaDB.
- Creates sites: test1 and test2.
- Network-activates this plugin from the repo.
- Seeds multilingual content + taxonomies on test1.
- Exports the post using the plugin’s Export class.
- Imports it into test2 using a helper that mirrors the plugin’s Import logic.
- Verifies content and taxonomy terms.

Requirements
- Docker and Docker Compose plugin installed.

Quick start
1) Start and run the test end-to-end:
   - `bash test/bin/run.sh`

2) Access the network:
   - WP Admin: `http://localhost:8080/wp-admin/` (admin / admin)
   - test1: `http://localhost:8080/test1/`
   - test2: `http://localhost:8080/test2/`

Notes
- The export helper writes to `test/tmp/export.json` inside this repo.
- To re-run from scratch, you can stop and remove containers/volumes:
  - `bash test/bin/down.sh`
