#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

compose="docker compose -f test/docker-compose.yml"

PLUGIN_SLUG=wp-post-exporter
BASE_URL=http://localhost:8080
ADMIN_USER=admin
SITE_URL=${BASE_URL}

OUT_DIR=test/tmp
mkdir -p "$OUT_DIR"

echo "[INFO] Ensuring containers are up…"
$compose up -d db wordpress

echo "[INFO] Ensuring WordPress is installed (multisite) …"
$compose run --rm wpcli sh -lc "if ! wp core is-installed; then wp config set WP_ALLOW_MULTISITE true --raw || true; wp config create --dbname=wordpress --dbuser=wordpress --dbpass=wordpress --dbhost=db:3306 --skip-check || true; wp core multisite-install --url=localhost:8080 --title='WP Test Multisite' --admin_user='${ADMIN_USER}' --admin_password='admin' --admin_email='admin@example.com' --skip-email --subdomains=0; else echo 'WordPress already installed'; fi"

echo "[INFO] Activating ${PLUGIN_SLUG} …"
$compose run --rm wpcli sh -lc "wp plugin activate ${PLUGIN_SLUG} --network || wp plugin activate ${PLUGIN_SLUG}"

echo "[INFO] Installing/activating plugin-check …"
$compose run --rm wpcli sh -lc "wp plugin install plugin-check --activate || true"

echo "[INFO] Running plugin-check via WP-CLI (if available)…"
set -o pipefail
if $compose run --rm wpcli sh -lc "wp help plugin | grep -q '\<check\>'"; then
  $compose run --rm wpcli sh -lc "wp plugin check ${PLUGIN_SLUG} --format=json" > "${OUT_DIR}/plugin-check.json" || true
  echo "[INFO] plugin-check JSON saved to ${OUT_DIR}/plugin-check.json"
else
  echo "[WARN] 'wp plugin check' command not found. The plugin may only expose checks via WP Admin."
fi

echo "[INFO] Running supplemental meta checks …"
$compose run --rm wpcli sh -lc "wp eval-file /workspace/wpcli-plugin-meta-check.php" > "${OUT_DIR}/meta-check.json"
echo "[INFO] meta-check JSON saved to ${OUT_DIR}/meta-check.json"

echo "[INFO] Summary:"
if [ -f "${OUT_DIR}/meta-check.json" ]; then
  jq -r '.checks | to_entries[] | "- \(.key): \(.value.ok)"' < "${OUT_DIR}/meta-check.json" || cat "${OUT_DIR}/meta-check.json"
fi

echo "[DONE] Plugin Check completed."
