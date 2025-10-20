<?php
// Usage: wp eval-file /workspace/wpcli-import.php <input_path> [--url=...] [--user=...]

use Nikolareljin\WpPostExporter\Post\Import;

if (!defined('ABSPATH')) {
    exit(1);
}

if (!isset($args) || count($args) < 1) {
    fwrite(STDERR, "Usage: wp eval-file wpcli-import.php <input_path>\n");
    exit(1);
}

$in = $args[0];
$json = '';
if ($in === '-' || !is_readable($in)) {
    // Try STDIN
    $stdin = fopen('php://stdin', 'r');
    if ($stdin) {
        $json = stream_get_contents($stdin);
        fclose($stdin);
    }
    if ($json === '' || $json === false) {
        fwrite(STDERR, "Input file not readable: {$in}\n");
        exit(1);
    }
} else {
    $json = file_get_contents($in);
}
if ($json === false) {
    fwrite(STDERR, "Failed to read input file: {$in}\n");
    exit(1);
}

try {
    $full = json_decode($json, true, 30, JSON_THROW_ON_ERROR);
} catch (\Throwable $e) {
    fwrite(STDERR, "Invalid JSON: {$e->getMessage()}\n");
    exit(1);
}

$author_id = get_current_user_id();

$post_data = Import::get_post_data_set($full);
$post_data['post_author'] = $author_id;

// Normalize and decode content like the plugin does.
$tmp = $post_data['post_content'];
$tmp = Import::process_json($tmp);
$tmp = Import::normalize_encoding($tmp);
$post_data['post_content'] = $tmp;

if (isset($full['post_meta'])) {
    $post_data['meta_input'] = $full['post_meta'];
}

$initial_post_data = Import::get_post_data_set($post_data);
if (!empty($full['revisions'])) {
    $ordered = Import::order_revisions($full['revisions']);
    $initial_post_data = Import::get_post_data_set($ordered[0] ?? $post_data);
}

$initial_post_data['post_parent'] = 0;
$initial_post_data['post_author'] = $author_id;

$post_id = wp_insert_post($initial_post_data, false, false);
if (is_wp_error($post_id) || !$post_id) {
    fwrite(STDERR, "Failed to insert initial post\n");
    exit(1);
}
wp_save_post_revision($post_id);

// Apply revisions if present.
if (!empty($full['revisions'])) {
    $revs = array_reverse($full['revisions']);
    foreach ($revs as $rev) {
        $post_meta = $rev['post_meta'] ?? null;
        unset($rev['post_meta']);

        $rev_tmp = $rev['post_content'] ?? '';
        $rev_tmp = Import::process_json($rev_tmp);
        $rev_tmp = Import::normalize_encoding($rev_tmp);
        $rev['post_content'] = $rev_tmp;

        unset($rev['post_parent']);
        unset($rev['post_type']);
        $rev['ID'] = $post_id;
        $rev['post_author'] = $author_id;

        if (isset($post_meta)) {
            $rev['meta_input'] = $post_meta;
        }

        wp_update_post($rev, true);
        wp_save_post_revision($post_id);

        global $wpdb;
        $table = $wpdb->prefix . 'posts';
        $wpdb->update(
            $table,
            [
                'post_date' => $rev['post_date'] ?? current_time('mysql'),
                'post_date_gmt' => $rev['post_date_gmt'] ?? current_time('mysql', 1),
                'post_modified' => $rev['post_modified'] ?? current_time('mysql'),
                'post_modified_gmt' => $rev['post_modified_gmt'] ?? current_time('mysql', 1),
            ],
            [
                'post_parent' => $post_id,
                'post_type' => 'revision',
                'post_status' => 'inherit',
            ]
        );
    }
}

// Update final post and add prefix to title to match plugin behavior.
$post_data['ID'] = $post_id;
$post_data['post_title'] = 'Imported: ' . ($post_data['post_title'] ?? '');
wp_update_post($post_data);
wp_save_post_revision($post_id);

// Terms
if (!empty($full['terms']) && is_array($full['terms'])) {
    foreach ($full['terms'] as $taxonomy => $slugs) {
        if (empty($slugs) || !taxonomy_exists($taxonomy)) {
            continue;
        }
        $term_ids = [];
        foreach ((array) $slugs as $slug) {
            $existing = get_term_by('slug', $slug, $taxonomy);
            if ($existing && !is_wp_error($existing)) {
                $term_ids[] = (int) $existing->term_id;
                continue;
            }
            $inserted = wp_insert_term($slug, $taxonomy, ['slug' => $slug]);
            if (!is_wp_error($inserted)) {
                $term_ids[] = (int) ($inserted['term_id'] ?? 0);
            }
        }
        if (!empty($term_ids)) {
            wp_set_object_terms($post_id, $term_ids, $taxonomy, false);
        }
    }
}

echo (int) $post_id; echo "\n";
