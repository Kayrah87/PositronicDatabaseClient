# Positronic Database Client

A comprehensive Laravel 12 dockerized database management application with support for multiple database types, queue management, and modern development tools.

![Laravel Version](https://img.shields.io/badge/Laravel-12.x-red.svg)
![PHP Version](https://img.shields.io/badge/PHP-8.4-blue.svg)
![Docker](https://img.shields.io/badge/Docker-enabled-blue.svg)

## Features

- **Multi-Database Support**: MySQL, PostgreSQL, SQLite, SQL Server, MongoDB
- **Modern Laravel 12**: Latest Laravel framework with Livewire integration
- **Docker Environment**: Complete containerized development environment
- **SSL Security**: Self-signed certificates with HTTPS support
- **Queue Management**: Laravel Horizon for queue monitoring and management
- **Real-time Monitoring**: Laravel Pulse for application insights
- **Development Tools**: PHP 8.4, Node.js, NVM, comprehensive tooling
- **Network Flexibility**: Container-to-container communication capabilities

## Architecture

### Services
- **Laravel App**: Main application with PHP-FPM
- **Nginx**: Web server with SSL termination (port 8098:80, 8099:443)
- **MySQL**: Database server (port 3309:3306)
- **Redis**: Cache and queue backend
- **Queue Worker**: Laravel queue processing
- **Scheduler**: Laravel task scheduling
- **Horizon**: Queue dashboard (port 8100:8080)

### Storage
All persistent data is stored in `~/.positronic/data/` including:
- MySQL database files
- Application logs and storage
- Nginx logs
- Redis data

## Quick Start

### Prerequisites
- Docker and Docker Compose
- At least 4GB of available RAM
- Ports 8098, 8099, 3309, 6379, 8100 available

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Kayrah87/PositronicDatabaseClient.git
   cd PositronicDatabaseClient
   ```

2. **Create environment file**
   ```bash
   cp .env.example .env
   ```

3. **Configure environment variables** (edit `.env` file)
   ```bash
   # Update database credentials
   DB_PASSWORD=your_secure_password
   MYSQL_ROOT_PASSWORD=your_root_password
   
   # Configure other settings as needed
   ```

4. **Build and start the containers**
   ```bash
   docker-compose up -d --build
   ```

5. **Install dependencies and set up Laravel**
   ```bash
   docker-compose exec app composer install
   docker-compose exec app php artisan key:generate
   docker-compose exec app php artisan migrate
   ```

6. **Build frontend assets**
   ```bash
   docker-compose exec app npm install
   docker-compose exec app npm run build
   ```

### Access Points

- **Main Application**: https://localhost:8098
- **Horizon Dashboard**: http://localhost:8100
- **MySQL Database**: localhost:3309
- **Redis**: localhost:6379

## Configuration

### Environment Variables

The application is highly configurable through environment variables. Key configurations include:

#### Application
- `APP_NAME`: Application name
- `APP_ENV`: Environment (local, staging, production)
- `APP_DEBUG`: Debug mode
- `APP_URL`: Application URL

#### Docker Services
- `APP_PORT`: Application port mapping
- `MYSQL_HOST_PORT`: MySQL host port
- `NGINX_HTTP_PORT`: HTTP port
- `NGINX_HTTPS_PORT`: HTTPS port
- `DATA_STORAGE_PATH`: Data storage location

#### Database Connections
- **MySQL**: Primary database connection
- **PostgreSQL**: Secondary database support
- **SQL Server**: Enterprise database support
- **MongoDB**: NoSQL database support
- **SQLite**: File-based database support

### SSL Configuration

The application includes self-signed SSL certificates for development. For production:

1. Replace certificates in `docker/ssl/`
2. Update certificate paths in environment variables
3. Restart nginx service

## Database Management

### Supported Databases

1. **MySQL 8.0+**
   - Full DDL/DML support
   - Connection pooling
   - Performance monitoring

2. **PostgreSQL 12+**
   - Advanced query capabilities
   - JSON/JSONB support
   - Full-text search

3. **SQLite 3+**
   - Embedded database
   - Development/testing
   - File-based storage

4. **SQL Server 2019+**
   - Enterprise features
   - T-SQL support
   - Advanced analytics

5. **MongoDB 4.4+**
   - Document database
   - Aggregation pipelines
   - GridFS support

### Connection Management

Configure additional database connections in your `.env` file:

```env
# PostgreSQL Connection
PGSQL_HOST=your_postgres_host
PGSQL_PORT=5432
PGSQL_DATABASE=your_database
PGSQL_USERNAME=your_username
PGSQL_PASSWORD=your_password

# MongoDB Connection
MONGO_HOST=your_mongo_host
MONGO_PORT=27017
MONGO_DATABASE=your_database
MONGO_USERNAME=your_username
MONGO_PASSWORD=your_password
```

## Queue Management

Laravel Horizon provides a beautiful dashboard for monitoring Redis queues:

- **Access**: http://localhost:8100
- **Features**: Job monitoring, failed job management, throughput metrics
- **Configuration**: Configured for Redis-based queues

### Queue Workers

Multiple queue workers run automatically:
- Main queue worker with retry logic
- Failed job handling
- Automatic restart on failure

## Development

### Local Development

```bash
# Start services
docker-compose up -d

# Watch for file changes
docker-compose exec app npm run dev

# Run database migrations
docker-compose exec app php artisan migrate

# Seed database
docker-compose exec app php artisan db:seed

# Clear caches
docker-compose exec app php artisan optimize:clear
```

### Debugging

- **Laravel Debugbar**: Enabled in development
- **Xdebug**: Configured for PHP debugging
- **Logs**: Available in `storage/logs/` and `~/.positronic/data/`

### Testing

```bash
# Run tests
docker-compose exec app php artisan test

# Run with coverage
docker-compose exec app php artisan test --coverage
```

## Production Deployment

### Security Checklist

- [ ] Change all default passwords
- [ ] Replace self-signed certificates with valid SSL certificates
- [ ] Set `APP_ENV=production` and `APP_DEBUG=false`
- [ ] Configure proper backup strategies
- [ ] Set up monitoring and alerting
- [ ] Review and harden nginx configuration
- [ ] Configure proper firewall rules

### Performance Optimization

- [ ] Enable PHP OPcache
- [ ] Configure Redis for session storage
- [ ] Set up database query caching
- [ ] Configure CDN for static assets
- [ ] Implement database connection pooling

## Backup and Recovery

### Database Backups

Automated backup configuration with Laravel Backup package:

```bash
# Manual backup
docker-compose exec app php artisan backup:run

# Schedule backups (runs automatically)
docker-compose exec app php artisan schedule:list
```

### Data Recovery

```bash
# Restore from backup
docker-compose exec app php artisan backup:restore
```

## Monitoring

### Laravel Pulse

Laravel Pulse provides real-time application monitoring:
- Performance metrics
- Database query monitoring
- Cache performance
- Queue processing stats

### Logs

Log files are available in:
- Application: `storage/logs/laravel.log`
- Nginx: `~/.positronic/data/nginx/logs/`
- MySQL: `~/.positronic/data/mysql/`
- Queue: `storage/logs/queue.log`

## Troubleshooting

### Common Issues

1. **Port Already in Use**
   ```bash
   # Check port usage
   netstat -tulpn | grep :8098
   
   # Update ports in .env file
   NGINX_HTTP_PORT=8099
   ```

2. **Database Connection Issues**
   ```bash
   # Check MySQL container
   docker-compose logs mysql
   
   # Test connection
   docker-compose exec app php artisan tinker
   ```

3. **SSL Certificate Issues**
   ```bash
   # Regenerate certificates
   docker-compose exec app openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
     -keyout /etc/ssl/private/positronic.key \
     -out /etc/ssl/certs/positronic.crt
   ```

### Performance Issues

1. **Memory Usage**
   ```bash
   # Check container memory usage
   docker stats
   
   # Increase PHP memory limit in docker/php/php.ini
   memory_limit = 1024M
   ```

2. **Database Performance**
   ```bash
   # Monitor MySQL performance
   docker-compose exec mysql mysqladmin -u root -p processlist
   
   # Check slow queries
   docker-compose exec mysql mysql -u root -p -e "SHOW VARIABLES LIKE 'slow_query_log';"
   ```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, please open an issue on the GitHub repository or contact the development team.

## Acknowledgments

- Laravel Framework Team
- Docker Community
- Open Source Database Communities
- Contributors and Testers

---

**Positronic Database Client** - Comprehensive Database Management Solution