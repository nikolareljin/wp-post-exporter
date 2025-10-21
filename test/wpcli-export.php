<?php
// Usage: wp eval-file /workspace/wpcli-export.php <post_id> [--url=...] [--user=...]

use Nikolareljin\NrPostExporter\Post\Export;

if (!defined('ABSPATH')) {
    exit(1);
}

if (!isset($args) || count($args) < 1) {
    fwrite(STDERR, "Usage: wp eval-file wpcli-export.php <post_id>\n");
    exit(1);
}

$post_id = (int) $args[0];

$post = get_post($post_id);
if (!$post instanceof WP_Post) {
    fwrite(STDERR, "Post not found: {$post_id}\n");
    exit(1);
}

$data = Export::export_post($post, true);
$json = wp_json_encode($data);
if ($json === false) {
    fwrite(STDERR, "Failed to encode JSON for post {$post_id}\n");
    exit(1);
}
echo $json;
echo "\n";
