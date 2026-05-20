<?php
/**
 * Plugin Name: BigData Shop
 * Description: Custom shop with full behavioral tracking → PostgreSQL
 * Version: 2.0
 */
// Disable WordPress version check that breaks PG4WP
add_filter('pre_site_transient_update_core', '__return_null');
add_filter('pre_transient_update_core', '__return_null');

register_activation_hook(__FILE__, 'bigdata_create_tables');

function bigdata_create_tables() {
    global $wpdb;

    $wpdb->query("CREATE TABLE IF NOT EXISTS shop_products (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255),
        description TEXT,
        price DECIMAL(10,2),
        category VARCHAR(100),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )");

    $wpdb->query("CREATE TABLE IF NOT EXISTS product_interactions (
        id SERIAL PRIMARY KEY,
        product_id INTEGER,
        product_name VARCHAR(255),
        user_session VARCHAR(255),
        hover_seconds INTEGER DEFAULT 0,
        action_type VARCHAR(50),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )");

    $count = $wpdb->get_var("SELECT COUNT(*) FROM shop_products");
    if ($count == 0) {
        $wpdb->query("INSERT INTO shop_products (name, description, price, category) VALUES
            ('Laptop Pro', 'High performance laptop 16GB RAM', 1200.00, 'Electronics'),
            ('Ecran 4K', '4K monitor 27 inch IPS', 450.00, 'Electronics'),
            ('Clavier Mecanique', 'Mechanical keyboard RGB backlit', 120.00, 'Accessories'),
            ('Souris Sans Fil', 'Wireless mouse 2.4GHz', 45.00, 'Accessories'),
            ('Casque Audio', 'Noise cancelling headphones', 200.00, 'Audio'),
            ('Webcam HD', '1080p webcam with microphone', 80.00, 'Accessories'),
            ('SSD 1TB', 'NVMe SSD 1TB 3500MB/s', 90.00, 'Storage'),
            ('Hub USB-C', '7-in-1 USB-C hub', 35.00, 'Accessories')
        ");
    }
}

// REST API
add_action('rest_api_init', function() {
    register_rest_route('bigdata/v1', '/interaction', [
        'methods' => 'POST',
        'callback' => 'bigdata_save_interaction',
        'permission_callback' => '__return_true'
    ]);
});

function bigdata_save_interaction($request) {
    global $wpdb;
    $data = $request->get_json_params();

    $wpdb->insert('product_interactions', [
        'product_id'    => intval($data['product_id']),
        'product_name'  => sanitize_text_field($data['product_name']),
        'user_session'  => sanitize_text_field($data['session_id']),
        'hover_seconds' => intval($data['hover_seconds']),
        'action_type'   => sanitize_text_field($data['action_type'])
    ]);

    return ['status' => 'saved'];
}

// Shop shortcode
add_shortcode('bigdata_shop', 'bigdata_render_shop');

function bigdata_render_shop() {
    global $wpdb;
    $products = $wpdb->get_results("SELECT * FROM shop_products ORDER BY category");
    $session_id = uniqid('user_');

    ob_start();
    ?>
    <style>
        #bigdata-shop { font-family: Arial, sans-serif; }
        .product-grid { display: flex; flex-wrap: wrap; gap: 20px; padding: 20px 0; }
        .product-card {
            border: 1px solid #ddd;
            border-radius: 8px;
            padding: 15px;
            width: 200px;
            cursor: pointer;
            transition: all 0.3s;
            position: relative;
        }
        .product-card:hover { box-shadow: 0 4px 15px rgba(0,0,0,0.2); transform: translateY(-2px); }
        .product-card.interested { border-color: #f90; background: #fffbf0; }
        .product-price { color: #27ae60; font-weight: bold; font-size: 1.2em; }
        .product-category { font-size: 0.8em; color: #888; }
        .interaction-badge {
            position: absolute; top: 5px; right: 5px;
            background: #f90; color: white;
            border-radius: 10px; padding: 2px 6px;
            font-size: 0.7em; display: none;
        }
        #stats-panel { background: #f5f5f5; padding: 15px; border-radius: 8px; margin-top: 20px; }
        #stats-panel h3 { margin-top: 0; }
        .stat-item { display: flex; justify-content: space-between; padding: 5px 0; border-bottom: 1px solid #ddd; }
    </style>

    <div id="bigdata-shop">
        <h2>Our Products</h2>
        <div class="product-grid">
        <?php foreach($products as $p): ?>
            <div class="product-card"
                 data-product-id="<?= $p->id ?>"
                 data-product-name="<?= esc_attr($p->name) ?>">
                <span class="interaction-badge">👁 Interested</span>
                <h3><?= esc_html($p->name) ?></h3>
                <p><?= esc_html($p->description) ?></p>
                <p class="product-price"><?= number_format($p->price, 2) ?> TND</p>
                <p class="product-category"><?= esc_html($p->category) ?></p>
            </div>
        <?php endforeach; ?>
        </div>

        <div id="stats-panel">
            <h3>📊 Your Session Stats</h3>
            <div id="stats-list"></div>
        </div>
    </div>

    <script>
    const SESSION_ID = '<?= $session_id ?>';
    const API_URL = '<?= rest_url('bigdata/v1/interaction') ?>';
    const sessionStats = {};

    function sendInteraction(card, seconds, action) {
        const productId = card.dataset.productId;
        const productName = card.dataset.productName;

        fetch(API_URL, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                product_id: productId,
                product_name: productName,
                session_id: SESSION_ID,
                hover_seconds: seconds,
                action_type: action
            })
        });

        // Update session stats
        if (!sessionStats[productName]) {
            sessionStats[productName] = { views: 0, hovers: 0, clicks: 0, total_seconds: 0 };
        }
        if (action === 'view') sessionStats[productName].views++;
        if (action === 'hover' || action === 'interested') {
            sessionStats[productName].hovers++;
            sessionStats[productName].total_seconds += seconds;
        }
        if (action === 'click') sessionStats[productName].clicks++;

        updateStatsPanel();
    }

    function updateStatsPanel() {
        const list = document.getElementById('stats-list');
        list.innerHTML = Object.entries(sessionStats)
            .filter(([k, v]) => v.hovers > 0 || v.clicks > 0)
            .sort((a, b) => b[1].total_seconds - a[1].total_seconds)
            .map(([name, s]) => `
                <div class="stat-item">
                    <span>${name}</span>
                    <span>👁 ${s.hovers} hovers | ⏱ ${s.total_seconds}s | 🖱 ${s.clicks} clicks</span>
                </div>
            `).join('');
    }

    document.querySelectorAll('.product-card').forEach(card => {
        // Track view on load
        sendInteraction(card, 0, 'view');

        let hoverStart = null;
        let interestedTimer = null;

        card.addEventListener('mouseenter', () => {
            hoverStart = Date.now();
            interestedTimer = setTimeout(() => {
                card.classList.add('interested');
                card.querySelector('.interaction-badge').style.display = 'block';
                sendInteraction(card, 10, 'interested');
            }, 10000);
        });

        card.addEventListener('mouseleave', () => {
            if (hoverStart) {
                const seconds = Math.floor((Date.now() - hoverStart) / 1000);
                clearTimeout(interestedTimer);
                if (seconds >= 3) sendInteraction(card, seconds, 'hover');
                hoverStart = null;
            }
        });

        card.addEventListener('click', () => {
            sendInteraction(card, 0, 'click');
        });
    });
    </script>
    <?php
    return ob_get_clean();
}