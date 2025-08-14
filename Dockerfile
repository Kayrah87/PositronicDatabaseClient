# Multi-stage Dockerfile for Positronic Database Client
FROM php:8.4-fpm as base

# Set working directory
WORKDIR /app

# Install system dependencies and development tools
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    gzip \
    unzip \
    vim \
    nano \
    wget \
    openssh-client \
    openssl \
    ca-certificates \
    gnupg \
    lsb-release \
    supervisor \
    cron \
    # Database client libraries
    default-mysql-client \
    postgresql-client \
    sqlite3 \
    # For SQL Server support
    unixodbc \
    unixodbc-dev \
    # For MongoDB support
    libssl-dev \
    libsasl2-dev \
    # Additional utilities
    htop \
    iputils-ping \
    net-tools \
    telnet \
    && rm -rf /var/lib/apt/lists/*

# Install Microsoft SQL Server ODBC Driver
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/debian/12/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql18 mssql-tools18 \
    && echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc

# Install PHP extensions for database connectivity
RUN docker-php-ext-install \
    pdo \
    pdo_mysql \
    pdo_pgsql \
    pdo_sqlite \
    mysqli \
    bcmath \
    ctype \
    fileinfo \
    json \
    mbstring \
    openssl \
    tokenizer \
    xml \
    zip \
    gd

# Install additional PHP extensions via PECL
RUN pecl install mongodb redis xdebug sqlsrv pdo_sqlsrv \
    && docker-php-ext-enable mongodb redis xdebug sqlsrv pdo_sqlsrv

# Install Node Version Manager (NVM) and latest Node.js
ENV NVM_DIR=/root/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install node \
    && nvm use node \
    && nvm alias default node

# Add NVM to PATH
ENV PATH=$NVM_DIR/versions/node/$(cd $NVM_DIR/versions/node && ls | tail -1)/bin:$PATH

# Install Composer
COPY --from=composer:2.8 /usr/bin/composer /usr/bin/composer

# Create application user
RUN groupadd -g 1000 www-data && useradd -u 1000 -ms /bin/bash -g www-data www-data

# Set up directory permissions
RUN mkdir -p /app/storage/logs \
    && mkdir -p /app/storage/framework/{cache,sessions,testing,views} \
    && mkdir -p /app/bootstrap/cache \
    && chown -R www-data:www-data /app \
    && chmod -R 755 /app/storage \
    && chmod -R 755 /app/bootstrap/cache

# Copy application files
COPY --chown=www-data:www-data . /app

# Copy PHP configuration
COPY docker/php/php.ini /usr/local/etc/php/conf.d/custom.ini

# Install Composer dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Install Node.js dependencies
RUN npm ci --only=production

# Build assets
RUN npm run build

# Copy supervisor configuration
COPY docker/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create SSL certificates directory
RUN mkdir -p /etc/ssl/certs /etc/ssl/private

# Generate self-signed SSL certificate
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/positronic.key \
    -out /etc/ssl/certs/positronic.crt \
    -subj "/C=US/ST=Local/L=Local/O=Positronic/OU=Development/CN=localhost"

# Set correct permissions for SSL certificates
RUN chmod 600 /etc/ssl/private/positronic.key \
    && chmod 644 /etc/ssl/certs/positronic.crt

# Expose port 9000 for PHP-FPM
EXPOSE 9000

# Switch to www-data user
USER www-data

# Start supervisor to manage processes
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]