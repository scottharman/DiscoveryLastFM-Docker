# Synology Docker Setup Instructions

Since Synology Docker doesn't automatically show environment variables from docker-compose files, you need to add them manually.

## Step 1: Build the Image

1. Download the repository files to your Synology:
   - `docker-compose.synology.yml`
   - `Dockerfile` 
   - `.env.example`
   - All source files needed for build

2. Open Synology Docker, go to **Image** tab
3. Click **Add** → **Add from Folder**
4. Select the folder containing all the files
5. Build will create the image with bash included

## Step 2: Create Container Manually

1. Go to **Image** tab
2. Select the built image
3. Click **Launch**
4. Click **Advanced Settings**
5. Go to **Environment** tab
6. Add these variables one by one:

### Required Environment Variables

| Variable Name | Value to Enter |
|---------------|----------------|
| `LASTFM_USERNAME` | `your_lastfm_username` |
| `LASTFM_API_KEY` | `your_lastfm_api_key` |
| `MUSIC_SERVICE` | `lidarr` |
| `LIDARR_API_KEY` | `your_lidarr_api_key` |
| `AUTO_UPDATE_ENABLED` | `true` |
| `UPDATE_CHECK_INTERVAL_HOURS` | `24` |

### Optional Environment Variables

| Variable Name | Default Value | Description |
|---------------|---------------|-------------|
| `DISCOVERY_MODE` | `cron` | Operation mode |
| `CRON_SCHEDULE` | `0 3 * * *` | Daily at 3 AM |
| `DRY_RUN` | `false` | Test mode |
| `DEBUG` | `false` | Debug logging |
| `LIDARR_ENDPOINT` | `http://lidarr:8686` | Lidarr server URL |
| `RECENT_MONTHS` | `3` | Months to analyze |
| `MIN_PLAYS` | `20` | Minimum plays per artist |

### If Using Headphones Instead

| Variable Name | Value to Enter |
|---------------|----------------|
| `MUSIC_SERVICE` | `headphones` |
| `HP_API_KEY` | `your_headphones_api_key` |
| `HP_ENDPOINT` | `http://headphones:8181` |

## Step 3: Configure Volumes

In the **Volume** tab, add these mount points:

| Container Path | Mount Type | Description |
|----------------|------------|-------------|
| `/app/config` | Docker Volume | Configuration files |
| `/app/logs` | Docker Volume | Log files |
| `/app/cache` | Docker Volume | Cache data |

## Step 4: Network Settings

- **Port Settings**: Add port `8080:8080` for health checks
- **Links**: If you have Lidarr/Headphones containers, link them

## Step 5: Start Container

1. Click **Apply** to save settings
2. Start the container
3. Check logs to verify it's working

## Notes

- Replace `your_*` placeholders with your actual credentials
- Get Last.fm API key from: https://www.last.fm/api/account/create
- Get Lidarr API key from: Settings > General > Security