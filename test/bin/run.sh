#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

compose="docker compose -f test/docker-compose.yml"

info() { echo "[INFO] $*"; }
err() { echo "[ERROR] $*" 1>&2; }

ADMIN_USER=admin
ADMIN_PASS=admin
ADMIN_EMAIL=admin@example.com
BASE_URL=http://localhost:8080
SITE1_URL=${BASE_URL}/test1
SITE2_URL=${BASE_URL}/test2

POST_TITLE="Multilingual — 你好, مرحبا, Привет, 😀"

EXPORT_PATH_HOST="test/tmp/export.json"

mkdir -p test/tmp

info "Starting containers (db, wordpress)…"
$compose up -d db wordpress

info "Waiting 15s for DB to initialize…"
sleep 15

info "Ensuring WordPress (not yet installed) and configuring multisite…"
$compose run --rm wpcli sh -lc "if ! wp core is-installed; then wp config set WP_ALLOW_MULTISITE true --raw || true; wp config create --dbname=wordpress --dbuser=wordpress --dbpass=wordpress --dbhost=db:3306 --skip-check || true; wp core multisite-install --url=localhost:8080 --title='WP Test Multisite' --admin_user='${ADMIN_USER}' --admin_password='${ADMIN_PASS}' --admin_email='${ADMIN_EMAIL}' --skip-email --subdomains=0; else echo 'WordPress already installed'; fi"

info "Creating sites test1 and test2 if missing…"
$compose run --rm wpcli sh -lc "wp site list --field=path | grep -q '^/test1/' || wp site create --slug=test1 --title='Test 1'"
$compose run --rm wpcli sh -lc "wp site list --field=path | grep -q '^/test2/' || wp site create --slug=test2 --title='Test 2'"

info "Activating plugin network-wide…"
$compose run --rm wpcli sh -lc "wp plugin activate nr-post-exporter --network"

info "Seeding taxonomies on test1…"
$compose run --rm wpcli sh -lc "wp --url='${SITE1_URL}' term create category 'Κατηγορία' --slug='utf-katigoria' || true"
$compose run --rm wpcli sh -lc "wp --url='${SITE1_URL}' term create post_tag '标签' --slug='utf-biaoqian' || true"
$compose run --rm wpcli sh -lc "wp --url='${SITE1_URL}' term create post_tag 'ключ' --slug='utf-klyuch' || true"

info "Creating multilingual post on test1…"
POST_ID=$($compose run --rm wpcli sh -lc "wp --url='${SITE1_URL}' post create --post_type=post --post_status=publish --post_title=$(printf %q "${POST_TITLE}") --post_content=$(printf %q "$(cat test/content.txt)") --porcelain")
info "Created post ID: ${POST_ID}"

info "Assigning terms to post…"
$compose run --rm wpcli sh -lc "wp --url='${SITE1_URL}' post term set ${POST_ID} category utf-katigoria"
$compose run --rm wpcli sh -lc "wp --url='${SITE1_URL}' post term set ${POST_ID} post_tag utf-biaoqian utf-klyuch"

info "Exporting the post JSON via plugin class…"
$compose run --rm wpcli sh -lc "wp --url='${SITE1_URL}' --user='${ADMIN_USER}' eval-file /workspace/wpcli-export.php ${POST_ID}" > "${EXPORT_PATH_HOST}"

info "Importing the JSON into test2…"
IMPORTED_ID=$($compose run --rm wpcli sh -lc "wp --url='${SITE2_URL}' --user='${ADMIN_USER}' eval-file /workspace/wpcli-import.php /workspace/tmp/export.json" < "${EXPORT_PATH_HOST}")
info "Imported post ID: ${IMPORTED_ID}"

info "Verifying import…"
TITLE=$($compose run --rm wpcli sh -lc "wp --url='${SITE2_URL}' post get ${IMPORTED_ID} --field=post_title")
CONTENT=$($compose run --rm wpcli sh -lc "wp --url='${SITE2_URL}' post get ${IMPORTED_ID} --field=post_content")
TAGS=$($compose run --rm wpcli sh -lc "wp --url='${SITE2_URL}' term list post_tag --object_id=${IMPORTED_ID} --field=slug --format=csv || true")
CATS=$($compose run --rm wpcli sh -lc "wp --url='${SITE2_URL}' term list category --object_id=${IMPORTED_ID} --field=slug --format=csv || true")

echo "Title: ${TITLE}"
echo "Tags: ${TAGS}"
echo "Categories: ${CATS}"

fail=0

[[ "${TITLE}" == Imported:* ]] || { err "Title not prefixed with 'Imported:'"; fail=1; }
grep -q "こんにちは世界" <<<"${CONTENT}" || { err "Japanese text missing"; fail=1; }
grep -q "你好" <<<"${CONTENT}" || { err "Chinese text missing"; fail=1; }
grep -q "Привет" <<<"${CONTENT}" || { err "Russian text missing"; fail=1; }
grep -q "مرحبا" <<<"${CONTENT}" || { err "Arabic text missing"; fail=1; }
grep -q "Γειά" <<<"${CONTENT}" || { err "Greek text missing"; fail=1; }
grep -q "😀" <<<"${CONTENT}" || { err "Emoji missing"; fail=1; }
grep -q "utf-katigoria" <<<"${CATS}" || { err "Category not set"; fail=1; }
grep -q "utf-biaoqian" <<<"${TAGS}" || { err "Tag utf-biaoqian not set"; fail=1; }
grep -q "utf-klyuch" <<<"${TAGS}" || { err "Tag utf-klyuch not set"; fail=1; }

if [[ $fail -ne 0 ]]; then
  err "Verification failed"
  exit 1
fi

info "Verification passed. Export/Import works."
