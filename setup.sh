#!/bin/bash

# Positronic Database Client - Docker Setup Script

set -e

echo "🚀 Starting Positronic Database Client Setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose > /dev/null 2>&1; then
    print_error "docker-compose is not installed. Please install it and try again."
    exit 1
fi

# Create data directories
print_status "Creating data directories..."
mkdir -p ~/.positronic/data/{mysql,app,nginx/logs,redis}

# Check if .env exists
if [ ! -f .env ]; then
    print_status "Creating .env file from .env.example..."
    cp .env.example .env
    
    print_warning "Please edit the .env file to configure your database passwords and other settings."
    echo "Key variables to configure:"
    echo "  - DB_PASSWORD"
    echo "  - MYSQL_ROOT_PASSWORD"
    echo ""
    
    read -p "Press Enter to continue after configuring .env file..."
fi

# Generate app key if not set
if ! grep -q "^APP_KEY=base64:" .env; then
    print_status "Generating Laravel application key..."
    docker-compose run --rm app php artisan key:generate --no-interaction
fi

# Build and start containers
print_status "Building and starting Docker containers..."
docker-compose up -d --build

# Wait for MySQL to be ready
print_status "Waiting for MySQL to be ready..."
timeout=60
counter=0
while ! docker-compose exec mysql mysqladmin ping -h localhost --silent 2>/dev/null; do
    sleep 2
    counter=$((counter+2))
    if [ $counter -gt $timeout ]; then
        print_error "MySQL failed to start within $timeout seconds"
        exit 1
    fi
    echo -n "."
done
echo ""

# Install Composer dependencies
print_status "Installing Composer dependencies..."
docker-compose exec app composer install --no-dev --optimize-autoloader

# Run database migrations
print_status "Running database migrations..."
docker-compose exec app php artisan migrate --force

# Install and build frontend assets
print_status "Installing and building frontend assets..."
docker-compose exec app npm ci --only=production
docker-compose exec app npm run build

# Clear and cache configuration
print_status "Optimizing Laravel configuration..."
docker-compose exec app php artisan config:cache
docker-compose exec app php artisan route:cache
docker-compose exec app php artisan view:cache

# Set correct permissions
print_status "Setting correct file permissions..."
docker-compose exec app chown -R www-data:www-data storage bootstrap/cache
docker-compose exec app chmod -R 775 storage bootstrap/cache

print_status "✅ Setup completed successfully!"
echo ""
echo "🌐 Access points:"
echo "  - Main Application: https://localhost:8098"
echo "  - Horizon Dashboard: http://localhost:8100"
echo "  - MySQL Database: localhost:3309"
echo ""
echo "📋 Next steps:"
echo "  1. Visit https://localhost:8098 to access the application"
echo "  2. Configure additional database connections in the web interface"
echo "  3. Monitor queues at http://localhost:8100"
echo ""
echo "📚 Documentation: See README.md for detailed configuration options"
echo ""
echo "🛠️ Useful commands:"
echo "  - View logs: docker-compose logs -f"
echo "  - Stop services: docker-compose down"
echo "  - Restart services: docker-compose restart"
echo ""

# Show container status
docker-compose ps