#!/bin/bash

generate_ssl_certificate() {
    # Ensure SSL directories exist
    mkdir -p /etc/ssl/private
    mkdir -p /etc/ssl/certs
    
    CERT_FILE="/etc/ssl/certs/nginx-selfsigned.crt"
    KEY_FILE="/etc/ssl/private/nginx-selfsigned.key"
    
    echo "Generating SSL certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$KEY_FILE" \
        -out "$CERT_FILE" \
        -subj "/C=MO/L=BG/O=1337/OU=student/CN=${DOMAIN_NAME}"
    
    echo "SSL certificate created at $CERT_FILE"
}

#ssl secure socket layer , encryption , authentication.

configure_nginx() {
cat <<EOF > /etc/nginx/sites-available/default

server {
    listen 80;
    listen [::]:80;

    server_name www.${DOMAIN_NAME} ${DOMAIN_NAME};

    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name www.${DOMAIN_NAME} ${DOMAIN_NAME};

    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
    
    ssl_protocols TLSv1.3;

    index index.php;
    root /var/www/html;

    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_pass wordpress:9000;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location ^~ /phpmyadmin/ {
        proxy_pass http://phpmyadmin:80/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
        proxy_buffering off;
    }
}
EOF
}

reload_nginx() {
   nginx -g "daemon off;"
}

main() {
    generate_ssl_certificate
    configure_nginx
    reload_nginx
}

main