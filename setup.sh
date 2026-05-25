#!/bin/bash
# =============================================================================
# Magento 2 Interview Environment — Automated Setup
# Runs automatically on container creation via devcontainer postCreateCommand
# =============================================================================

set -e
cd /var/www/html

MAGENTO_BASE_URL="http://localhost:8080/"
ADMIN_URI="admin_tvvd181"
ADMIN_USER="admin"
ADMIN_PASS="Admin123!"
DB_HOST="db"
DB_NAME="magento"
DB_USER="magento"
DB_PASS="magento"
OS_HOST="opensearch"
OS_PORT="9200"
COMPOSER_AUTH_JSON='{"http-basic":{"repo.magento.com":{"username":"6307ed5eb4a57f01e495ad2219501dc8","password":"45af2bea578484d059cf6ae400e12e28"}}}'

echo "========================================================"
echo "  Magento 2.4.7-p2 Interview Environment Setup"
echo "========================================================"

# ── Step 1: PHP memory limit (fallback in case Dockerfile change not rebuilt) ──
if ! php -r "exit(ini_get('memory_limit') === '2G' ? 0 : 1);" 2>/dev/null; then
    echo "[php] Setting memory_limit = 2G"
    echo "memory_limit = 2G"          > /usr/local/etc/php/conf.d/magento.ini
    echo "max_execution_time = 1800" >> /usr/local/etc/php/conf.d/magento.ini
fi

# ── Step 2: Composer dependencies ───────────────────────────────────────────
if [ ! -d "vendor/magento" ]; then
    echo "[1/6] Installing Composer dependencies (~5 min)..."
    COMPOSER_AUTH="$COMPOSER_AUTH_JSON" \
    composer install --no-interaction --no-progress --optimize-autoloader
else
    echo "[1/6] Vendor directory present — skipping composer install."
fi

# ── Step 3: Wait for MariaDB ─────────────────────────────────────────────────
echo "[2/6] Waiting for database..."
until mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" --ssl=0 -e "SELECT 1" &>/dev/null; do
    echo "  DB not ready, retrying in 3s..."
    sleep 3
done
echo "  Database is ready."

# ── Step 4: Wait for OpenSearch ──────────────────────────────────────────────
echo "[3/6] Waiting for OpenSearch..."
for i in $(seq 1 40); do
    curl -sf "http://${OS_HOST}:${OS_PORT}" > /dev/null 2>&1 && break
    echo "  OpenSearch not ready ($i/40), retrying in 5s..."
    sleep 5
done
curl -sf "http://${OS_HOST}:${OS_PORT}" > /dev/null 2>&1 || { echo "ERROR: OpenSearch unreachable after timeout."; exit 1; }
echo "  OpenSearch is ready."

# ── Step 5: Magento install (only if env.php missing) ────────────────────────
if [ ! -f "app/etc/env.php" ]; then
    echo "[4/6] Running Magento setup:install..."

    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" --ssl=0 \
        -e "DROP DATABASE IF EXISTS ${DB_NAME}; CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

    php -d memory_limit=2G bin/magento setup:install \
        --base-url="$MAGENTO_BASE_URL" \
        --backend-frontname="$ADMIN_URI" \
        --db-host="$DB_HOST" \
        --db-name="$DB_NAME" \
        --db-user="$DB_USER" \
        --db-password="$DB_PASS" \
        --search-engine=opensearch \
        --opensearch-host="$OS_HOST" \
        --opensearch-port="$OS_PORT" \
        --opensearch-enable-auth=0 \
        --admin-firstname=Admin \
        --admin-lastname=User \
        --admin-email=admin@example.com \
        --admin-user="$ADMIN_USER" \
        --admin-password="$ADMIN_PASS" \
        --language=en_US \
        --currency=USD \
        --timezone=Asia/Kolkata \
        --use-rewrites=1

    echo "[5/6] Installing sample data..."
    COMPOSER_AUTH="$COMPOSER_AUTH_JSON" \
    php -d memory_limit=2G bin/magento sampledata:deploy

    php -d memory_limit=2G bin/magento setup:upgrade

    php -d memory_limit=2G bin/magento module:disable \
        Magento_TwoFactorAuth Magento_AdminAdobeImsTwoFactorAuth

    php -d memory_limit=2G bin/magento setup:di:compile

    php -d memory_limit=2G bin/magento setup:static-content:deploy -f en_US

else
    echo "[4/6] Magento already installed — skipping setup:install."
    echo "[5/6] Sample data already present — skipping."
fi

# ── Step 6: Cache flush + permissions ────────────────────────────────────────
echo "[6/6] Flushing caches and setting permissions..."
php -d memory_limit=2G bin/magento cache:flush
chown -R www-data:www-data pub/ var/ generated/ 2>/dev/null || true

echo ""
echo "========================================================"
echo "  SETUP COMPLETE"
echo "  Store : http://localhost:8080/"
echo "  Admin : http://localhost:8080/${ADMIN_URI}"
echo "  Login : ${ADMIN_USER} / ${ADMIN_PASS}"
echo "========================================================"
