# Use an official PHP image with Apache
FROM php:8.2-apache

# Enable Apache rewrite module
RUN a2enmod rewrite

# Install PDO and MySQL driver
RUN docker-php-ext-install pdo pdo_mysql

# Copy your application code into the container
# The Dockerfile is in app_backend_laravel, so . refers to app_backend_laravel
# And we want to mount public into the webroot, so we'll adjust the volume in docker-compose
# For now, let's copy everything
COPY . /var/www/html

# Configure Apache to serve from the public directory
# This assumes your entry point is 'public' relative to the mounted volume
# For this structure, we'll keep /var/www/html as the root and access files directly
# Or, modify Apache config to point to /var/www/html/public
# For simplicity, let's adjust docker-compose volume to mount public directly.
# No, let's not make that assumption yet. The PHP scripts are in public directly.
# The volume mount `.:/var/www/html` from `docker-compose.yml` will put `app_backend_laravel` content directly in `/var/www/html`.
# So, the actual public-facing files will be in `/var/www/html/public`.
# We need to ensure Apache serves from `/var/www/html/public`.

# Update Apache's DocumentRoot
RUN sed -i 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/000-default.conf
RUN sed -i 's!/var/www/!/var/www/html/public!g' /etc/apache2/apache2.conf

# Set directory permissions for Apache
RUN chown -R www-data:www-data /var/www/html

# Expose port 80
EXPOSE 80