#!/bin/bash

# Function to create necessary directories
create_directories() {
    echo "Creating necessary directories..."
    mkdir -p /var/www/html
}

# Function to clean up existing files
clean_up() {
    echo "Removing existing files in /var/www/html..."
    cd /var/www/html
    rm -rf *
}

# Function to download and set up WP-CLI
setup_wp_cli() {
    echo "Downloading and setting up WP-CLI..."
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
}

# Function to download WordPress core
download_wordpress() {
    echo "Downloading WordPress core..."
    wp core download --allow-root
}

# Function to configure WordPress
configure_wordpress() {
    echo "Configuring WordPress..."
    cd /var/www/html
    
    # Copy the template wp-config.php
    if [ -f /wp-config.php ]; then
        cp /wp-config.php wp-config.php
    else
        # Use the downloaded sample
        mv wp-config-sample.php wp-config.php
    fi

    # Update wp-config.php with database credentials
    sed -i "s/database_name_here/${db_name}/g" wp-config.php
    sed -i "s/username_here/${db_user}/g" wp-config.php
    sed -i "s/password_here/${db_pwd}/g" wp-config.php
    sed -i "s/localhost/${DB_HOST}/g" wp-config.php
}

# Function to install WordPress core
install_wordpress() {
    echo "Installing WordPress..."
    if ! wp core is-installed --allow-root; then
        wp core install --url=https://$DOMAIN_NAME/ --title=$WP_TITLE --admin_user=$WP_ADMIN_USR --admin_password=$WP_ADMIN_PWD --admin_email=$WP_ADMIN_EMAIL --skip-email --allow-root
    fi

    # Keep URLs in sync when DOMAIN_NAME changes in .env
    wp option update home "https://$DOMAIN_NAME" --allow-root
    wp option update siteurl "https://$DOMAIN_NAME" --allow-root
}

# Function to create a new WordPress user
create_wordpress_user() {
    echo "Creating new WordPress user..."
    if ! wp user get $WP_USR --allow-root >/dev/null 2>&1; then
        wp user create $WP_USR $WP_EMAIL --role=author --user_pass=$WP_PWD --allow-root
    fi
}

# Function to install and activate a WordPress theme
install_theme() {
    echo "Installing and activating the Astra theme..."
    wp theme install twentytwentytwo --activate --allow-root

}

# Function to update all WordPress plugins
update_plugins() {
    echo "Updating all WordPress plugins..."
    wp plugin update --all --allow-root
}

# Function to configure PHP-FPM
configure_php_fpm() {
    echo "Configuring PHP-FPM..."
    # Find installed PHP-FPM version
    PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
    echo "Found PHP version: $PHP_VERSION"
    
    PHP_FPM_CONF="/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"
    if [ -f "$PHP_FPM_CONF" ]; then
        sed -i 's/listen = \/run\/php\/php[0-9.]*-fpm.sock/listen = 9000/g' "$PHP_FPM_CONF"
    fi
    
    mkdir -p /run/php
}

# Function to start PHP-FPM
start_php_fpm() {
    echo "Starting PHP-FPM..."
    PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
    PHP_FPM="/usr/sbin/php-fpm${PHP_VERSION}"
    
    if [ ! -f "$PHP_FPM" ]; then
        # Try generic php-fpm
        PHP_FPM=$(which php-fpm)
    fi
    
    if [ -z "$PHP_FPM" ] || [ ! -f "$PHP_FPM" ]; then
        echo "ERROR: PHP-FPM not found"
        exit 1
    fi
    
    exec "$PHP_FPM" -F
}

# Execute functions
create_directories
clean_up
setup_wp_cli
download_wordpress
configure_wordpress
install_wordpress
create_wordpress_user
install_theme
update_plugins
configure_php_fpm
start_php_fpm

echo "WordPress installation and setup complete."
