# DiscoveryLastFM Docker 🐳

[![Docker Pulls](https://img.shields.io/docker/pulls/mrrobotogit/discoverylastfm)](https://hub.docker.com/r/mrrobotogit/discoverylastfm)
[![Docker Image Size](https://img.shields.io/docker/image-size/mrrobotogit/discoverylastfm/latest)](https://hub.docker.com/r/mrrobotogit/discoverylastfm)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/MrRobotoGit/DiscoveryLastFM-Docker/docker-publish.yml)](https://github.com/MrRobotoGit/DiscoveryLastFM-Docker/actions)
[![License](https://img.shields.io/github/license/MrRobotoGit/DiscoveryLastFM-Docker)](LICENSE)

Containerized version of [DiscoveryLastFM](https://github.com/MrRobotoGit/DiscoveryLastFM) - an automated music discovery tool that integrates Last.fm with music management systems (Lidarr/Headphones).

## 🚀 Quick Start

### Option 1: Docker Compose (Recommended)

```bash
# Download the setup files
curl -O https://raw.githubusercontent.com/MrRobotoGit/DiscoveryLastFM-Docker/main/docker-compose.yml
curl -O https://raw.githubusercontent.com/MrRobotoGit/DiscoveryLastFM-Docker/main/.env.example

# Configure your environment
cp .env.example .env
nano .env  # Edit with your credentials

# Start the stack
docker-compose up -d
```

### Option 2: Docker Run

```bash
docker run -d \
  --name discoverylastfm \
  -e LASTFM_USERNAME=your_username \
  -e LASTFM_API_KEY=your_api_key \
  -e MUSIC_SERVICE=lidarr \
  -e LIDARR_API_KEY=your_lidarr_key \
  -e LIDARR_ENDPOINT=http://your-lidarr:8686 \
  -v discoverylastfm_config:/app/config \
  -v discoverylastfm_logs:/app/logs \
  mrrobotogit/discoverylastfm:latest
```

### Option 3: Automated Setup Script

```bash
# Clone the repository
git clone https://github.com/MrRobotoGit/DiscoveryLastFM-Docker.git
cd DiscoveryLastFM-Docker

# Run the automated setup
./scripts/setup-docker.sh
```

## 📋 Features

### ✨ What's Included

- **🎵 DiscoveryLastFM**: Main application for music discovery
- **🎧 Lidarr Integration**: Modern music collection manager
- **📱 Multi-Architecture**: AMD64 and ARM64 (Raspberry Pi) support
- **🔄 Auto-Updates**: Watchtower for automatic container updates
- **📊 Health Monitoring**: Built-in health checks and monitoring
- **🔧 Easy Configuration**: Environment-based configuration
- **📈 Performance Optimized**: Multi-stage build, minimal base image

### 🛠️ Optional Services

- **Lidarr**: Music collection management
- **Redis**: Caching layer for improved performance
- **Portainer**: Container management UI
- **Watchtower**: Automatic updates

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Last.fm API   │────│ DiscoveryLastFM │────│  Lidarr/Headphones  │
└─────────────────┘    └─────────────────┘    └─────────────────┘

```

## 📖 Configuration

### Required Configuration

| Variable | Description | Example |
|----------|-------------|---------|
| `LASTFM_USERNAME` | Your Last.fm username | `john_doe` |
| `LASTFM_API_KEY` | Last.fm API key | `abc123def456...` |
| `MUSIC_SERVICE` | Music service (`lidarr` or `headphones`) | `lidarr` |

### Lidarr Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `LIDARR_API_KEY` | Lidarr API key | Required |
| `LIDARR_ENDPOINT` | Lidarr server URL | `http://lidarr:8686` |
| `LIDARR_ROOT_FOLDER` | Music library path | `/music` |
| `LIDARR_QUALITY_PROFILE_ID` | Quality profile ID | `1` |
| `LIDARR_METADATA_PROFILE_ID` | Metadata profile ID | `1` |

### Headphones Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `HP_API_KEY` | Headphones API key | Required |
| `HP_ENDPOINT` | Headphones server URL | `http://headphones:8181` |

### Discovery Parameters

| Variable | Description | Default | Range |
|----------|-------------|---------|-------|
| `RECENT_MONTHS` | Months of recent plays | `3` | 1-12 |
| `MIN_PLAYS` | Minimum plays per artist | `20` | 1-1000 |
| `SIMILAR_MATCH_MIN` | Similarity threshold | `0.46` | 0.0-1.0 |
| `MAX_SIMILAR_PER_ART` | Max similar artists | `20` | 1-100 |
| `MAX_POP_ALBUMS` | Max albums per artist | `5` | 1-50 |

### Container Operation

| Variable | Description | Default | Options |
|----------|-------------|---------|---------|
| `DISCOVERY_MODE` | Operation mode | `cron` | `sync`, `cron`, `daemon`, `test` |
| `CRON_SCHEDULE` | Cron schedule | `0 3 * * *` | Cron expression |
| `DRY_RUN` | Test mode (no changes) | `false` | `true`, `false` |
| `DEBUG` | Debug logging | `false` | `true`, `false` |

## 🎯 Operation Modes

### Sync Mode (One-time)
```bash
docker run --rm \
  -e DISCOVERY_MODE=sync \
  -e LASTFM_USERNAME=your_username \
  # ... other config
  mrrobotogit/discoverylastfm:latest
```

### Cron Mode (Scheduled)
```yaml
# docker-compose.yml
services:
  discoverylastfm:
    environment:
      - DISCOVERY_MODE=cron
      - CRON_SCHEDULE=0 3 * * *  # Daily at 3 AM
```

### Daemon Mode (Continuous)
```yaml
services:
  discoverylastfm:
    environment:
      - DISCOVERY_MODE=daemon
      - SLEEP_HOURS=6  # Run every 6 hours
```

### Test Mode (Validation)
```bash
docker run --rm \
  -e DISCOVERY_MODE=test \
  # ... config
  mrrobotogit/discoverylastfm:latest
```

## 📦 Docker Compose Profiles

### Default Profile (Full Stack)
```bash
docker-compose up -d
```
Includes: DiscoveryLastFM, Lidarr, Redis, Watchtower

### Development Profile
```bash
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```
Includes: All services + development tools + log viewer

### Minimal Profile
```bash
docker-compose -f docker-compose.minimal.yml up -d
```
Includes: DiscoveryLastFM only

## 🔧 Management Commands

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f discoverylastfm
```

### Health Check
```bash
# Container health
docker-compose exec discoverylastfm /usr/local/bin/health-check

# Service status
docker-compose ps
```

### Update Images
```bash
# Pull latest images
docker-compose pull

# Restart with new images
docker-compose up -d
```

### Configuration Test
```bash
# Test configuration
docker-compose exec discoverylastfm python /app/config/config.py
```

## 🚨 Troubleshooting

### Common Issues

#### Container Won't Start
```bash
# Check logs
docker-compose logs discoverylastfm

# Validate configuration
docker-compose exec discoverylastfm /usr/local/bin/health-check config
```

#### Last.fm Connection Issues
```bash
# Test Last.fm connectivity
docker-compose exec discoverylastfm curl -f "http://ws.audioscrobbler.com/2.0/?method=user.getinfo&user=${LASTFM_USERNAME}&api_key=${LASTFM_API_KEY}&format=json"
```

#### Lidarr Connection Issues
```bash
# Test Lidarr connectivity
docker-compose exec discoverylastfm curl -f -H "X-Api-Key: ${LIDARR_API_KEY}" "${LIDARR_ENDPOINT}/api/v1/system/status"
```

### Debug Mode
```bash
# Enable debug logging
docker-compose exec discoverylastfm sh -c 'export DEBUG=true && python /app/DiscoveryLastFM.py'
```

## 🎛️ Advanced Configuration

### Custom Network
```yaml
networks:
  music_network:
    external: true

services:
  discoverylastfm:
    networks:
      - music_network
```

### Resource Limits
```yaml
services:
  discoverylastfm:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 128M
```

### Custom Volumes
```yaml
services:
  discoverylastfm:
    volumes:
      - /host/path/to/config:/app/config
      - /host/path/to/logs:/app/logs
      - /host/path/to/music:/music:ro
```

## 🔐 Security

### Non-Root User
The container runs as a non-root user (`discoverylastfm:1000`) for security.

### Secrets Management
```yaml
# Using Docker secrets
services:
  discoverylastfm:
    environment:
      - LASTFM_API_KEY_FILE=/run/secrets/lastfm_api_key
    secrets:
      - lastfm_api_key

secrets:
  lastfm_api_key:
    file: ./secrets/lastfm_api_key.txt
```

### Network Security
```yaml
# Restrict network access
services:
  discoverylastfm:
    networks:
      - internal
    # No external ports exposed
```

## 📊 Monitoring

### Health Checks
Built-in health checks monitor:
- Configuration validity
- Service connectivity
- Application files
- Disk space
- Recent activity

### Metrics (Optional)
```yaml
# Enable metrics endpoint
services:
  discoverylastfm:
    ports:
      - "8080:8080"  # Metrics port
    environment:
      - ENABLE_METRICS=true
```

### Log Aggregation
```yaml
# Configure logging driver
services:
  discoverylastfm:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

## 🤖 Automation

### Automatic Updates
Watchtower automatically updates containers when new images are available:

```yaml
watchtower:
  image: containrrr/watchtower
  environment:
    - WATCHTOWER_POLL_INTERVAL=86400  # Check daily
    - WATCHTOWER_CLEANUP=true
```

### Backup Automation
```bash
# Backup script
#!/bin/bash
docker-compose exec discoverylastfm tar czf /tmp/backup.tar.gz /app/config /app/cache
docker cp discoverylastfm:/tmp/backup.tar.gz ./backup-$(date +%Y%m%d).tar.gz
```

## 🏷️ Available Tags

| Tag | Description | Architecture |
|-----|-------------|--------------|
| `latest` | Latest stable release | `amd64`, `arm64` |
| `v2.1.0` | Current stable version | `amd64`, `arm64` |
| `main` | Development branch | `amd64`, `arm64` |
| `security-*` | Security updates | `amd64`, `arm64` |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `docker-compose -f docker-compose.dev.yml up`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [DiscoveryLastFM](https://github.com/MrRobotoGit/DiscoveryLastFM) - Original project
- [Lidarr](https://lidarr.audio/) - Music collection manager
- [Last.fm](https://www.last.fm/) - Music discovery platform

---

**📧 Support**: For issues and support, please open an issue on [GitHub](https://github.com/MrRobotoGit/DiscoveryLastFM-Docker/issues).

**🌟 Star this repo** if you find it useful!
