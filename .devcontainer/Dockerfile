FROM php:8.2-apache

ENV APACHE_DOCUMENT_ROOT /var/www/html/pub

RUN apt-get update && apt-get install -y \
    git \
    unzip \
    zip \
    curl \
    vim \
    libzip-dev \
    libicu-dev \
    libxml2-dev \
    libxslt1-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev

RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg
    
RUN docker-php-ext-install \
    pdo_mysql \
    intl \
    zip \
    soap \
    xsl \
    bcmath \
    sockets \
    gd \
    mbstring \
    simplexml 

RUN a2enmod rewrite

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
    /etc/apache2/sites-available/*.conf \
    /etc/apache2/apache2.conf \
    /etc/apache2/conf-available/*.conf

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
