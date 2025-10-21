#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

compose="docker compose -f test/docker-compose.yml"
PLUGIN_DIR=/var/www/html/wp-content/plugins/nr-post-exporter

echo "[INFO] Ensuring containers are up…"
$compose up -d db wordpress

echo "[INFO] Installing Composer (ephemeral) and running install + dump-autoload …"
$compose run --rm --user 0:0 wpcli sh -lc 'set -e; cd '"${PLUGIN_DIR}"'; \
curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php || wget -q -O /tmp/composer-setup.php https://getcomposer.org/installer; \
php /tmp/composer-setup.php --install-dir=/tmp --filename=composer.phar --quiet; \
php /tmp/composer.phar install --prefer-dist --no-interaction --no-progress; \
php /tmp/composer.phar dump-autoload -o; \
rm -f /tmp/composer-setup.php /tmp/composer.phar'

echo "[DONE] Composer autoloads rebuilt."

