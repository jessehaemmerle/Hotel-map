# 🏨 Hotel Mapping Application - Docker Deployment

This guide will help you deploy the Hotel Mapping Application using Docker containers.

## 📋 Prerequisites

- Docker (version 20.10+)
- Docker Compose (version 2.0+)
- Git

## 🚀 Quick Start

### 1. Clone and Setup

```bash
# Clone the repository
git clone <your-repo-url>
cd hotel-mapping-app

# Copy environment file
cp .env.example .env
```

### 2. Configure Environment

Edit the `.env` file with your configuration:

```bash
# Required: Get your Mapbox token from https://account.mapbox.com/access-tokens/
MAPBOX_ACCESS_TOKEN=pk.your_actual_mapbox_token_here

# Security: Change in production
JWT_SECRET=your-super-secret-jwt-key-change-in-production

# Backend URL (adjust for your domain)
REACT_APP_BACKEND_URL=http://localhost:8001
```

### 3. Deploy

#### Development Environment
```bash
# Make deploy script executable
chmod +x deploy.sh

# Deploy development environment
./deploy.sh dev
```

#### Production Environment
```bash
# Deploy production environment
./deploy.sh prod
```

## 🌐 Access Your Application

### Development
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8001
- **API Documentation**: http://localhost:8001/docs
- **MongoDB**: localhost:27017

### Production
- **Application**: http://localhost (redirects to HTTPS)
- **HTTPS**: https://localhost (configure SSL certificates)

## 📚 Available Commands

```bash
# Deploy development environment
./deploy.sh dev

# Deploy production environment  
./deploy.sh prod

# View logs
./deploy.sh logs

# Check service health
./deploy.sh health

# Stop all services
./deploy.sh stop

# Clean up (remove all containers/images)
./deploy.sh cleanup
```

## 🔧 Manual Docker Commands

### Development

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Rebuild and restart
docker-compose up --build -d
```

### Production

```bash
# Start production services
docker-compose -f docker-compose.prod.yml up -d

# View logs
docker-compose -f docker-compose.prod.yml logs -f

# Stop services
docker-compose -f docker-compose.prod.yml down
```

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Frontend    │    │     Backend     │    │    MongoDB      │
│   (React App)   │────│   (FastAPI)     │────│   (Database)    │
│   Port: 3000    │    │   Port: 8001    │    │   Port: 27017   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                        │                        │
         └────────────────────────┼────────────────────────┘
                                  │
                        ┌─────────────────┐
                        │     Network     │
                        │  hotel-network  │
                        └─────────────────┘
```

## 🔒 Production Deployment

### SSL/HTTPS Configuration

For production, configure SSL certificates:

1. **Obtain SSL certificates** (Let's Encrypt, commercial CA)
2. **Place certificates** in `./ssl/` directory:
   ```
   ssl/
   ├── cert.pem
   └── key.pem
   ```
3. **Uncomment SSL configuration** in `nginx-prod.conf`
4. **Update domain name** in nginx configuration

### Environment Variables for Production

```bash
# Production .env file
MAPBOX_ACCESS_TOKEN=pk.your_actual_token
JWT_SECRET=very-secure-random-string-min-32-chars
REACT_APP_BACKEND_URL=https://yourdomain.com
MONGO_ROOT_USER=admin
MONGO_ROOT_PASSWORD=secure-database-password
```

### Reverse Proxy Setup

The production setup includes Nginx as a reverse proxy that:
- Serves the React frontend
- Proxies API requests to the backend
- Handles SSL termination
- Provides rate limiting
- Adds security headers

## 🐛 Troubleshooting

### Common Issues

1. **Port conflicts**
   ```bash
   # Check what's using the ports
   lsof -i :3000
   lsof -i :8001
   lsof -i :27017
   ```

2. **Permission errors**
   ```bash
   # Fix permissions for deploy script
   chmod +x deploy.sh
   ```

3. **Container startup issues**
   ```bash
   # Check logs
   docker-compose logs backend
   docker-compose logs frontend
   docker-compose logs mongodb
   ```

4. **Database connection issues**
   ```bash
   # Check MongoDB status
   docker-compose exec mongodb mongosh --eval "db.adminCommand('ping')"
   ```

### Service Health Checks

```bash
# Check if all containers are running
docker-compose ps

# Test backend API
curl http://localhost:8001/api/hotels

# Test frontend
curl http://localhost:3000

# Check database
docker-compose exec mongodb mongosh hotel_mapping --eval "db.hotels.countDocuments()"
```

## 📊 Monitoring

### View Real-time Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f mongodb
```

### Container Statistics

```bash
# Resource usage
docker stats

# Container information
docker-compose ps
```

## 🔄 Updates and Maintenance

### Update Application

```bash
# Pull latest changes
git pull

# Rebuild and restart
docker-compose up --build -d
```

### Database Backup

```bash
# Backup MongoDB
docker-compose exec mongodb mongodump --out /data/backup

# Copy backup from container
docker cp hotel-mapping-mongodb:/data/backup ./backup
```

### Database Restore

```bash
# Copy backup to container
docker cp ./backup hotel-mapping-mongodb:/data/restore

# Restore MongoDB
docker-compose exec mongodb mongorestore /data/restore
```

## 🌍 Scaling

### Horizontal Scaling

```bash
# Scale backend instances
docker-compose up -d --scale backend=3

# Scale with load balancer (requires additional configuration)
docker-compose -f docker-compose.scale.yml up -d
```

## 📝 Configuration Files

- `docker-compose.yml` - Development environment
- `docker-compose.prod.yml` - Production environment
- `Dockerfile.backend` - Backend container definition
- `Dockerfile.frontend` - Frontend container definition
- `nginx.conf` - Development Nginx configuration
- `nginx-prod.conf` - Production Nginx configuration
- `mongo-init.js` - MongoDB initialization script
- `.env.example` - Environment variables template

## 🆘 Support

If you encounter issues:

1. Check the logs: `./deploy.sh logs`
2. Verify environment variables in `.env`
3. Ensure Mapbox token is valid
4. Check that ports 3000, 8001, and 27017 are available
5. Verify Docker and Docker Compose versions

## 🔐 Security Best Practices

1. **Change default passwords** in production
2. **Use strong JWT secrets** (min 32 characters)
3. **Enable SSL/HTTPS** for production
4. **Configure firewall** to restrict access
5. **Regular security updates** for Docker images
6. **Monitor logs** for suspicious activity
7. **Backup database** regularly

## 📈 Performance Optimization

1. **Enable gzip compression** (configured in Nginx)
2. **Use Redis** for session storage (optional)
3. **Implement CDN** for static assets
4. **Database indexing** (already configured)
5. **Container resource limits** in production