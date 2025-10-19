<?php

namespace Nikolareljin\WpPostExporter\Post;

class Export {

    public function __construct() {
        self::init();
    }

    public static function init() {
        add_action( 'admin_init', [ __CLASS__, 'add_export_link' ] );
    }

    /**
     * Sets export links in the admin dashboard for public post types.
     *
     * @return void
     */
    public static function add_export_link() {
        $post_types = get_post_types([
            'public' => true,
        ]);

        foreach ( $post_types as $post_type ) {
            add_filter( 'post_row_actions', [ __CLASS__, 'add_export_link_to_post_row_actions' ], 10, 2 );
            add_filter( 'page_row_actions', [ __CLASS__, 'add_export_link_to_post_row_actions' ], 10, 2 );

            // Define custom action for post types.
            add_action( 'admin_post_wp_post_exporter_export', [ __CLASS__, 'export_post_link_action' ] );
        }
    }

    /**
     * Defines export link content to post row actions.
     *
     * @param array   $actions Actions.
     * @param \WP_Post $post   Post.
     * @return array
     */
    public static function add_export_link_to_post_row_actions( $actions, $post ) {
        $actions['export'] = sprintf(
            '<a href="%s" target="_blank" rel="noopener noreferrer">%s</a>',
            esc_url( self::get_export_link( $post ) ),
            esc_html__( 'Export', 'wp-post-exporter' )
        );

        return $actions;
    }

    /**
     * Get export link.
     *
     * @param \WP_Post $post Post.
     * @return string
     */
    public static function get_export_link( $post ) {
        return add_query_arg( [
            'action' => 'wp_post_exporter_export',
            'post'   => $post->ID,
        ], admin_url( 'admin-post.php' ) );
    }

    /**
     * Returns Blog Path for multisite; empty string for single site.
     *
     * @return string
     */
    private static function get_site_name() {
        $blog_name = '';
        if ( is_multisite() ) {
            // get blog URL and strip the base URL and leave the path only
            $blog_name = str_replace( network_home_url(), '', get_bloginfo( 'url' ) );
        }

        return $blog_name;
    }

    /**
     * Export single post or page using the admin.php?action=export&post=<post_id> link.
     * Outputs a JSON file for download.
     *
     * @return void
     */
    public static function export_post_link_action() {
        if ( ! isset( $_GET['action'] ) || 'wp_post_exporter_export' !== $_GET['action'] ) {
            return;
        }

        if ( ! isset( $_GET['post'] ) ) {
            return;
        }

        $post      = get_post( (int) $_GET['post'] );
        $site_name = self::get_site_name();

        if ( ! $post instanceof \WP_Post ) {
            return;
        }

        $export = self::export_post( $post );

        // Current date in format YYYY-mm-dd_HH-ii-ss
        $current_date = date( 'Y-m-d--H-i-s' );

        $filename = sprintf(
            '%s-%s-%s.%s.json',
            $post->post_type,
            $post->ID,
            $site_name,
            $current_date
        );

        @header( 'Content-Type: application/json' );
        @header( 'Content-Disposition: attachment; filename="' . $filename . '"' );
        @header( 'Pragma: no-cache' );
        @header( 'Expires: 0' );

        echo wp_json_encode( $export );

        exit;
    }

    /**
     * Export a single post.
     * Includes normalization to avoid double-encoded UTF-8 content in JSON payloads.
     *
     * @param \WP_Post $post           Post to export.
     * @param bool     $with_revisions Export with revisions.
     * @return array
     */
    public static function export_post( $post, $with_revisions = true ) {
        if ( ! isset( $_GET['post'] ) && ! ( $post instanceof \WP_Post ) ) {
            return [];
        }

        if ( ! $post instanceof \WP_Post ) {
            $post = get_post( (int) $_GET['post'] );
        }

        if ( ! $post instanceof \WP_Post ) {
            return [];
        }

        $export = [
            'post_title'        => self::normalize_utf8( $post->post_title ),
            'post_content'      => self::normalize_utf8( $post->post_content ),
            'post_excerpt'      => $post->post_excerpt,
            'post_status'       => $post->post_status,
            'post_type'         => $post->post_type,
            'post_date'         => $post->post_date,
            'post_date_gmt'     => $post->post_date_gmt,
            'post_modified'     => $post->post_modified,
            'post_modified_gmt' => $post->post_modified_gmt,
            'post_parent'       => $post->post_parent,
            'post_author'       => $post->post_author,
            'menu_order'        => $post->menu_order,
            'comment_status'    => $post->comment_status,
            'ping_status'       => $post->ping_status,
            'post_password'     => $post->post_password,
            'post_name'         => $post->post_name,
            'post_mime_type'    => $post->post_mime_type,
            'guid'              => $post->guid,
            'pinged'            => $post->pinged,
            'to_ping'           => $post->to_ping,
            'filter'            => $post->filter,
            'post_meta'         => self::export_post_meta( $post->ID ),
            'terms'             => self::export_post_terms( $post->ID ),
        ];
        if ( $with_revisions ) {
            $export['revisions'] = self::export_post_revisions( $post->ID );
        }

        return $export;
    }

    /**
     * Normalize content for UTF-8 encoding by encoding to HTML entities.
     * Prevents double-encoded characters when later JSON-encoded and re-imported.
     * Applies recursively for arrays.
     *
     * @param mixed $value Value to normalize.
     * @return mixed
     */
    public static function normalize_utf8( $value ) {
        if ( is_array( $value ) ) {
            foreach ( $value as $key => $val ) {
                $value[ $key ] = self::normalize_utf8( $val );
            }
            return $value;
        }

        if ( is_string( $value ) ) {
            return htmlentities( $value, ENT_QUOTES, 'UTF-8' );
        }

        return $value;
    }

    /**
     * Export post meta.
     *
     * @param int $post_id Post ID
     * @return array
     */
    public static function export_post_meta( $post_id ) {
        $meta = get_post_meta( $post_id );

        $export = [];
        foreach ( $meta as $key => $value ) {
            $export[ $key ] = self::normalize_utf8( $value[0] );
        }

        return $export;
    }

    /**
     * Export post terms.
     *
     * @param int $post_id Post ID
     * @return array
     */
    public static function export_post_terms( $post_id ) {
        $export = [];

        $taxonomies = get_object_taxonomies( get_post_type( $post_id ) );
        foreach ( $taxonomies as $taxonomy ) {
            try {
                // Get terms for the post.
                $terms = get_the_terms( $post_id, $taxonomy );
            } catch ( \Exception $e ) {
                error_log( 'WP Post Exporter - Export terms: ' . $e->getMessage() );
                $terms = [];
            }

            if ( is_array( $terms ) ) {
                foreach ( $terms as $term ) {
                    $export[ $term->taxonomy ][] = $term->slug;
                }
            }
        }

        return $export;
    }

    /**
     * Exports all post revisions for a given post.
     *
     * @param int $post_id
     * @return array
     */
    public static function export_post_revisions( $post_id ) {
        $revisions = wp_get_post_revisions( $post_id );

        $export = [];
        if ( is_array( $revisions ) ) {
            foreach ( $revisions as $revision ) {
                $export[] = self::export_post( $revision, false );
            }
        }

        return $export;
    }
}
