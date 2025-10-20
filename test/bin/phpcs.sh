#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

compose="docker compose -f test/docker-compose.yml"

PLUGIN_DIR=/var/www/html/wp-content/plugins/wp-post-exporter

echo "[INFO] Ensuring containers are up…"
$compose up -d db wordpress

echo "[INFO] Running Composer install inside wpcli container (as root)…"
$compose run --rm --user 0:0 wpcli sh -lc 'set -e; cd '"${PLUGIN_DIR}"'; \
curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php || wget -q -O /tmp/composer-setup.php https://getcomposer.org/installer; \
php /tmp/composer-setup.php --install-dir=/tmp --filename=composer.phar --quiet; \
php /tmp/composer.phar install --prefer-dist --no-interaction --no-progress; \
rm -f /tmp/composer-setup.php /tmp/composer.phar'

echo "[INFO] Running PHPCS (using project phpcs.xml)…"
$compose run --rm --user 0:0 wpcli sh -lc 'cd '"${PLUGIN_DIR}"' && vendor/bin/phpcbf -p -s -d memory_limit=512M . || true'
$compose run --rm wpcli sh -lc 'cd '"${PLUGIN_DIR}"' && vendor/bin/phpcs -p -s -d memory_limit=512M .'
