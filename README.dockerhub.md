# DiscoveryLastFM Docker 🐳

[![Docker Pulls](https://img.shields.io/docker/pulls/mrrobotogit/discoverylastfm)](https://hub.docker.com/r/mrrobotogit/discoverylastfm)
[![Docker Image Size](https://img.shields.io/docker/image-size/mrrobotogit/discoverylastfm/latest)](https://hub.docker.com/r/mrrobotogit/discoverylastfm)

Streamlined Docker container for **DiscoveryLastFM v2.1.0** - automated music discovery that integrates Last.fm with music management systems (Lidarr/Headphones).

> 🎉 **v2.1.0 with Auto-Update System!** GitHub releases monitoring, CLI commands, and simplified Docker setup.

## 🚀 Quick Start

### Docker Compose (Recommended)
```bash
# Download setup files
curl -O https://raw.githubusercontent.com/MrRobotoGit/DiscoveryLastFM-Docker/main/docker-compose.yml
curl -O https://raw.githubusercontent.com/MrRobotoGit/DiscoveryLastFM-Docker/main/.env.example

# Configure environment (REQUIRED variables already have dummy values)
cp .env.example .env
nano .env  # Replace dummy values with your real credentials

# ⚠️ IMPORTANT: These variables are REQUIRED for container startup:
# AUTO_UPDATE_ENABLED=true
# UPDATE_CHECK_INTERVAL_HOURS=24

# Start the stack
docker compose up -d
```

### Docker Run
```bash
# With Lidarr
docker run -d \
  --name discoverylastfm \
  -e LASTFM_USERNAME=your_username \
  -e LASTFM_API_KEY=your_api_key \
  -e MUSIC_SERVICE=lidarr \
  -e LIDARR_API_KEY=your_lidarr_key \
  -e LIDARR_ENDPOINT=http://your-lidarr:8686 \
  -e AUTO_UPDATE_ENABLED=true \
  -e UPDATE_CHECK_INTERVAL_HOURS=24 \
  -v discoverylastfm_config:/app/config \
  -v discoverylastfm_logs:/app/logs \
  mrrobotogit/discoverylastfm:latest

# With Headphones  
docker run -d \
  --name discoverylastfm \
  -e LASTFM_USERNAME=your_username \
  -e LASTFM_API_KEY=your_api_key \
  -e MUSIC_SERVICE=headphones \
  -e HP_API_KEY=your_headphones_key \
  -e HP_ENDPOINT=http://your-headphones:8181 \
  -e AUTO_UPDATE_ENABLED=true \
  -e UPDATE_CHECK_INTERVAL_HOURS=24 \
  -v discoverylastfm_config:/app/config \
  -v discoverylastfm_logs:/app/logs \
  mrrobotogit/discoverylastfm:latest
```

## ✨ What's Included

- **🎵 DiscoveryLastFM v2.1.0**: Main application with auto-update system
- **🚀 Auto-Update**: GitHub releases monitoring with backup and rollback
- **⚡ Redis Cache**: Performance optimization with caching layer
- **📱 Multi-Architecture**: AMD64 and ARM64 (Raspberry Pi) support  
- **🔧 Simple Configuration**: Environment-based setup
- **📊 Health Monitoring**: Built-in health checks
- **🔒 Security**: Non-root user, minimal attack surface

## 📖 Required Configuration

> **⚠️ CRITICAL**: These variables are **REQUIRED** for the container to start. Missing values will cause startup failure.

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `LASTFM_USERNAME` | **YES** | `dummy_username` | Your Last.fm username |
| `LASTFM_API_KEY` | **YES** | `dummy_api_key_replace_with_real_one` | Last.fm API key ([Get here](https://www.last.fm/api/account/create)) |
| `AUTO_UPDATE_ENABLED` | **YES** | `true` | Enable auto-update checking |
| `UPDATE_CHECK_INTERVAL_HOURS` | **YES** | `24` | Update check interval |
| `MUSIC_SERVICE` | **YES** | `lidarr` | Music service (`lidarr` or `headphones`) |

**🚨 Startup Error**: Without these required variables, container fails with:
```
/usr/local/bin/docker-entrypoint.sh: line 270: syntax error near unexpected token 'else'
```

### Lidarr Configuration (if MUSIC_SERVICE=lidarr)
| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `LIDARR_API_KEY` | **YES** | `dummy_lidarr_api_key_replace_with_real_one` | Lidarr API key |
| `LIDARR_ENDPOINT` | NO | `http://lidarr:8686` | Lidarr server URL |
| `LIDARR_ROOT_FOLDER` | NO | `/music` | Music library path |

### Headphones Configuration  
| Variable | Description | Default |
|----------|-------------|---------|
| `HP_API_KEY` | Headphones API key | Required |
| `HP_ENDPOINT` | Headphones server URL | `http://headphones:8181` |

## 🎯 Operation Modes

| Mode | Description | Usage |
|------|-------------|-------|
| `sync` | One-time discovery run | `-e DISCOVERY_MODE=sync` |
| `cron` | Scheduled runs (default) | `-e CRON_SCHEDULE="0 3 * * *"` |
| `daemon` | Continuous background | `-e SLEEP_HOURS=6` |
| `test` | Validation mode | `-e DRY_RUN=true` |

### v2.1.0 Auto-Update Configuration ⚠️ **REQUIRED**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `AUTO_UPDATE_ENABLED` | **YES** | `true` | Enable auto-update checking |
| `UPDATE_CHECK_INTERVAL_HOURS` | **YES** | `24` | Check interval in hours |
| `BACKUP_RETENTION_DAYS` | NO | `7` | Backup retention in days |
| `ALLOW_PRERELEASE_UPDATES` | NO | `false` | Include pre-releases |
| `GITHUB_TOKEN` | NO | `` | GitHub API token (optional) |

## 🔧 Management

### View Logs
```bash
docker logs -f discoverylastfm
```

### Health Check
```bash
docker exec discoverylastfm /usr/local/bin/health-check
```

### Update Image  
```bash
docker pull mrrobotogit/discoverylastfm:latest
docker compose up -d  # Restart with new image
```

### v2.1.0 CLI Commands
```bash
# Check for updates
docker compose exec discoverylastfm python DiscoveryLastFM.py --update-status

# Install updates
docker compose exec discoverylastfm python DiscoveryLastFM.py --update

# List backups
docker compose exec discoverylastfm python DiscoveryLastFM.py --list-backups

# Check version
docker compose exec discoverylastfm python DiscoveryLastFM.py --version

# Clean temporary files
docker compose exec discoverylastfm python DiscoveryLastFM.py --cleanup
```

## 🏷️ Available Tags

| Tag | Description | Architecture |
|-----|-------------|--------------|
| `latest` | Latest stable release (v2.1.0) | `amd64`, `arm64` |
| `v2.1.0` | Current stable version | `amd64`, `arm64` |
| `main` | Development builds | `amd64`, `arm64` |

## 🚨 Common Issues

### Container Won't Start
```bash
# Check logs
docker logs discoverylastfm

# Validate configuration
docker exec discoverylastfm /usr/local/bin/health-check config
```

### macOS/Windows Permission Issues
**Problem**: `chmod: Operation not permitted` or endless restarts

**Solutions**:
```bash
# Use PUID/PGID environment variables
docker run -e PUID=1000 -e PGID=1000 ... mrrobotogit/discoverylastfm

# Or use bind mounts with local directories
mkdir -p ./data/{config,logs,cache}
docker run -v ./data/config:/app/config ... mrrobotogit/discoverylastfm
```

### Service Connection Issues
```bash
# Test Last.fm connectivity
docker exec discoverylastfm curl -f "http://ws.audioscrobbler.com/2.0/?method=user.getinfo&user=${LASTFM_USERNAME}&api_key=${LASTFM_API_KEY}&format=json"

# Test Lidarr connectivity  
docker exec discoverylastfm curl -f -H "X-Api-Key: ${LIDARR_API_KEY}" "${LIDARR_ENDPOINT}/api/v1/system/status"
```

## 🌐 Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Last.fm API   │────│ DiscoveryLastFM │────│ Lidarr/Headphones │
└─────────────────┘    │    + Redis      │    └─────────────────┘
                       └─────────────────┘
```

## 📚 Links

- **GitHub Repository**: [MrRobotoGit/DiscoveryLastFM-Docker](https://github.com/MrRobotoGit/DiscoveryLastFM-Docker)
- **Original Project**: [DiscoveryLastFM](https://github.com/MrRobotoGit/DiscoveryLastFM)
- **Documentation**: [Full README](https://github.com/MrRobotoGit/DiscoveryLastFM-Docker/blob/main/README.md)
- **Issues**: [Report Issues](https://github.com/MrRobotoGit/DiscoveryLastFM-Docker/issues)

## 📄 License

MIT License - see [LICENSE](https://github.com/MrRobotoGit/DiscoveryLastFM-Docker/blob/main/LICENSE) for details.

---

**Maintainer**: Matteo Rancilio (MrRobotoGit)  
**🌟 Star this repo** if you find it useful!