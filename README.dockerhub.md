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

# Configure environment
cp .env.example .env
nano .env  # Add your Last.fm and Lidarr/Headphones credentials

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

| Variable | Description | Example |
|----------|-------------|---------|
| `LASTFM_USERNAME` | Your Last.fm username | `john_doe` |
| `LASTFM_API_KEY` | Last.fm API key ([Get here](https://www.last.fm/api/account/create)) | `abc123def456...` |
| `MUSIC_SERVICE` | Music service (`lidarr` or `headphones`) | `lidarr` |

### Lidarr Configuration
| Variable | Description | Default |
|----------|-------------|---------|
| `LIDARR_API_KEY` | Lidarr API key | Required |
| `LIDARR_ENDPOINT` | Lidarr server URL | `http://lidarr:8686` |
| `LIDARR_ROOT_FOLDER` | Music library path | `/music` |

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

### v2.1.0 Auto-Update Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `AUTO_UPDATE_ENABLED` | Enable auto-update checking | `false` |
| `UPDATE_CHECK_INTERVAL_HOURS` | Check interval in hours | `24` |
| `BACKUP_RETENTION_DAYS` | Backup retention in days | `7` |
| `ALLOW_PRERELEASE_UPDATES` | Include pre-releases | `false` |
| `GITHUB_TOKEN` | GitHub API token (optional) | `` |

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