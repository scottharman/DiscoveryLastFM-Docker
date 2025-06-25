# DiscoveryLastFM Docker

[![Docker Pulls](https://img.shields.io/docker/pulls/mrrobotogit/discoverylastfm)](https://hub.docker.com/r/mrrobotogit/discoverylastfm)
[![Docker Image Size](https://img.shields.io/docker/image-size/mrrobotogit/discoverylastfm/latest)](https://hub.docker.com/r/mrrobotogit/discoverylastfm)
[![Multi-Architecture](https://img.shields.io/badge/arch-amd64%20%7C%20arm64-blue)](https://hub.docker.com/r/mrrobotogit/discoverylastfm)

Automated music discovery integration for Last.fm and music management systems (Lidarr/Headphones).

## 🚀 Quick Start

### Docker Run with Lidarr (Recommended)
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

### Docker Run with Headphones
```bash
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

### Docker Compose (Lidarr Example)
```yaml
version: '3.8'
services:
  discoverylastfm:
    image: mrrobotogit/discoverylastfm:latest
    container_name: discoverylastfm
    environment:
      - LASTFM_USERNAME=your_username
      - LASTFM_API_KEY=your_api_key
      # For Lidarr:
      - MUSIC_SERVICE=lidarr
      - LIDARR_API_KEY=your_lidarr_key
      - LIDARR_ENDPOINT=http://lidarr:8686
      # For Headphones (alternative):
      # - MUSIC_SERVICE=headphones
      # - HP_API_KEY=your_headphones_key
      # - HP_ENDPOINT=http://headphones:8181
    volumes:
      - discoverylastfm_config:/app/config
      - discoverylastfm_logs:/app/logs
    restart: unless-stopped

volumes:
  discoverylastfm_config:
  discoverylastfm_logs:
```

## 📋 Environment Variables

### Required
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

### Headphones Configuration
| Variable | Description | Default |
|----------|-------------|---------|
| `HP_API_KEY` | Headphones API key | Required |
| `HP_ENDPOINT` | Headphones server URL | `http://headphones:8181` |

### Operation Modes
| Variable | Description | Default | Options |
|----------|-------------|---------|---------|
| `DISCOVERY_MODE` | Operation mode | `cron` | `sync`, `cron`, `daemon`, `test` |
| `CRON_SCHEDULE` | Cron schedule | `0 3 * * *` | Cron expression |
| `DRY_RUN` | Test mode (no changes) | `false` | `true`, `false` |

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Last.fm API   │────│ DiscoveryLastFM │────│  Lidarr/Headphones  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🎯 Operation Modes

### One-time Sync
```bash
docker run --rm \
  -e DISCOVERY_MODE=sync \
  -e LASTFM_USERNAME=your_username \
  -e LASTFM_API_KEY=your_api_key \
  -e MUSIC_SERVICE=lidarr \
  -e LIDARR_API_KEY=your_key \
  -e LIDARR_ENDPOINT=http://lidarr:8686 \
  mrrobotogit/discoverylastfm:latest
```

### Scheduled (Cron)
```bash
docker run -d \
  -e DISCOVERY_MODE=cron \
  -e CRON_SCHEDULE="0 3 * * *" \
  # ... other config
  mrrobotogit/discoverylastfm:latest
```

### Continuous (Daemon)
```bash
docker run -d \
  -e DISCOVERY_MODE=daemon \
  -e SLEEP_HOURS=6 \
  # ... other config
  mrrobotogit/discoverylastfm:latest
```

## 🔧 Management

### View Logs
```bash
docker logs discoverylastfm -f
```

### Health Check
```bash
docker exec discoverylastfm /usr/local/bin/health-check
```

### Update Image
```bash
docker pull mrrobotogit/discoverylastfm:latest
docker stop discoverylastfm
docker rm discoverylastfm
# Run new container with same config
```

## 🏷️ Available Tags

| Tag | Description | Architecture |
|-----|-------------|--------------|
| `latest` | Latest stable release | `amd64`, `arm64` |
| `v2.1.0` | Current stable version | `amd64`, `arm64` |
| `main` | Development branch | `amd64`, `arm64` |

## 📖 Full Documentation

For complete setup guides, advanced configuration, and troubleshooting:

**🔗 [Full Documentation on GitHub](https://github.com/MrRobotoGit/DiscoveryLastFM-Docker)**

## 🔗 Links

- **Source Code**: [DiscoveryLastFM](https://github.com/MrRobotoGit/DiscoveryLastFM)
- **Docker Repository**: [GitHub](https://github.com/MrRobotoGit/DiscoveryLastFM-Docker)
- **Issues & Support**: [GitHub Issues](https://github.com/MrRobotoGit/DiscoveryLastFM-Docker/issues)

## 📄 License

MIT License - see [LICENSE](https://github.com/MrRobotoGit/DiscoveryLastFM-Docker/blob/main/LICENSE) for details.