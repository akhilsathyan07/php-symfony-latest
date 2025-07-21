# Use an official PHP 8.2 image with Apache
FROM php:8.2-apache

# Set environment to production
ENV APP_ENV=prod

# Install required PHP extensions for Symfony and PHP XML
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libicu-dev \
    libxml2-dev \
    git \
    unzip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd intl pdo pdo_mysql opcache xml \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Composer (PHP package manager)
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Enable Apache mod_rewrite for Symfony
RUN a2enmod rewrite

# Set the working directory to the Symfony project directory
WORKDIR /var/www/html

# Copy the Symfony project files into the container
COPY . .

# Copy the info.php file into the container for testing PHP
RUN mkdir -p /var/www/html/public/app/policy-terms
COPY ./info.php /var/www/html/public/app/policy-terms/info.php

# Set the correct file permissions for Symfony
RUN chown -R www-data:www-data /var/www/html

# Ensure var directory exists and has proper permissions
RUN mkdir -p /var/www/html/var && chmod -R 775 /var/www/html/var

# Copy custom Apache config for Symfony
COPY ./config/000-default.conf /etc/apache2/sites-available/000-default.conf

# Clear Symfony cache before installing
RUN rm -rf var/cache/*

# Install dependencies with Composer (exclude dev)
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Set final permissions
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 775 /var/www/html/var

# Expose port 80
EXPOSE 80

# Start Apache in the foreground
CMD ["apache2-foreground"]

