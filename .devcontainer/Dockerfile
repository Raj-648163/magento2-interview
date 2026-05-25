FROM php:8.2-apache

ENV APACHE_DOCUMENT_ROOT /var/www/html/pub

RUN apt-get update && apt-get install -y \
    git \
    unzip \
    zip \
    curl \
    vim \
    mariadb-client \
    libzip-dev \
    libicu-dev \
    libxml2-dev \
    libxslt1-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libonig-dev \
    libsodium-dev

RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg

RUN docker-php-ext-install \
    bcmath \
    gd \
    intl \
    mbstring \
    pdo_mysql \
    soap \
    sockets \
    sodium \
    xsl \
    zip

# PHP settings for Magento
RUN { \
    echo 'memory_limit = 2G'; \
    echo 'max_execution_time = 1800'; \
    echo 'max_input_time = 1800'; \
    echo 'upload_max_filesize = 64M'; \
    echo 'post_max_size = 64M'; \
} > /usr/local/etc/php/conf.d/magento.ini

RUN a2enmod rewrite

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
    /etc/apache2/sites-available/*.conf \
    /etc/apache2/apache2.conf \
    /etc/apache2/conf-available/*.conf

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
