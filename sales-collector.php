<?php
/**
 * Plugin Name: Sales Data Collector
 * Description: Saves CF7 form submissions to PostgreSQL
 * Version: 1.0
 */

// Create table on plugin activation
register_activation_hook(__FILE__, 'sales_create_table');

function sales_create_table() {
    global $wpdb;
    $wpdb->query("CREATE TABLE IF NOT EXISTS sales_data (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255),
        email VARCHAR(255),
        product VARCHAR(255),
        quantity INTEGER,
        price DECIMAL(10,2),
        region VARCHAR(100),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )");
}

// Hook into CF7 submission
add_action('wpcf7_mail_sent', 'sales_save_submission');


function sales_save_submission($contact_form) {
    $submission = WPCF7_Submission::get_instance();
    if (!$submission) return;
    
    $data = $submission->get_posted_data();
    global $wpdb;
    
    $wpdb->insert('sales_data', [
        'name'     => sanitize_text_field($data['your-name']),
        'email'    => sanitize_email($data['your-email']),
        'product'  => sanitize_text_field($data['product'][0]),
        'region'   => sanitize_text_field($data['region'][0]),
        'price'    => floatval($data['price']),
        'region'   => sanitize_text_field($data['region']),
    ]);
}
add_filter('wpcf7_skip_mail', '__return_true');