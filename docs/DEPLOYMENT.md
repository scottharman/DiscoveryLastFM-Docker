# DiscoveryLastFM Deployment Guide 🚀

This guide covers various deployment scenarios for DiscoveryLastFM Docker containers.

## Table of Contents

- [Quick Deployment](#quick-deployment)
- [Platform-Specific Deployments](#platform-specific-deployments)
- [Production Deployments](#production-deployments)
- [Cloud Deployments](#cloud-deployments)
- [Network Attached Storage (NAS)](#network-attached-storage-nas)
- [Kubernetes Deployments](#kubernetes-deployments)
- [Maintenance & Updates](#maintenance--updates)

## Quick Deployment

### One-Liner Deployment
```bash
curl -sSL https://raw.githubusercontent.com/MrRobotoGit/DiscoveryLastFM-Docker/main/scripts/setup-docker.sh | bash -s -- --mode automated
```

### Manual Quick Start
```bash
# Download and configure
curl -O https://raw.githubusercontent.com/MrRobotoGit/DiscoveryLastFM-Docker/main/docker-compose.yml
curl -O https://raw.githubusercontent.com/MrRobotoGit/DiscoveryLastFM-Docker/main/.env.example
cp .env.example .env

# Edit configuration
nano .env

# Deploy
docker-compose up -d
```

## Platform-Specific Deployments

### Raspberry Pi (ARM64)

#### Requirements
- Raspberry Pi 4+ (4GB+ RAM recommended)
- Raspberry Pi OS 64-bit
- Docker & Docker Compose installed

#### Optimized Configuration
```yaml
# docker-compose.override.yml for Raspberry Pi
version: '3.8'

services:
  discoverylastfm:
    image: mrrobotogit/discoverylastfm:latest
    platform: linux/arm64
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '2.0'
        reservations:
          memory: 256M
          cpus: '0.5'
    environment:
      # Reduced discovery parameters for Pi
      - MAX_SIMILAR_PER_ART=15
      - MAX_POP_ALBUMS=3
      - RECENT_MONTHS=2
      - CACHE_TTL_HOURS=48

  lidarr:
    platform: linux/arm64
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '2.0'

  redis:
    platform: linux/arm64
    command: redis-server --maxmemory 128mb --maxmemory-policy allkeys-lru
    deploy:
      resources:
        limits:
          memory: 128M
          cpus: '0.5'
```

#### Installation Script for Pi
```bash
#!/bin/bash
# pi-setup.sh

# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker pi

# Install Docker Compose
sudo apt install -y docker-compose

# Deploy DiscoveryLastFM
git clone https://github.com/MrRobotoGit/DiscoveryLastFM-Docker.git
cd DiscoveryLastFM-Docker

# Use Pi-optimized configuration
cp docker-compose.yml docker-compose.yml.backup
cp examples/raspberry-pi/docker-compose.pi.yml docker-compose.yml

# Configure
cp .env.example .env
echo "Please edit .env with your configuration:"
nano .env

# Deploy
docker-compose up -d

echo "DiscoveryLastFM deployed! Access Lidarr at http://$(hostname -I | awk '{print $1}'):8686"
```

### Intel/AMD 64-bit Servers

#### High-Performance Configuration
```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  discoverylastfm:
    image: mrrobotogit/discoverylastfm:latest
    platform: linux/amd64
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '4.0'
        reservations:
          memory: 512M
          cpus: '1.0'
      restart_policy:
        condition: on-failure
        max_attempts: 3
    environment:
      # Aggressive discovery settings
      - MAX_SIMILAR_PER_ART=50
      - MAX_POP_ALBUMS=10
      - RECENT_MONTHS=6
      - MIN_PLAYS=10
      - DISCOVERY_MODE=daemon
      - SLEEP_HOURS=2

  lidarr:
    image: lscr.io/linuxserver/lidarr:latest
    deploy:
      resources:
        limits:
          memory: 4G
          cpus: '4.0'

  redis:
    image: redis:7-alpine
    command: redis-server --maxmemory 1gb --maxmemory-policy allkeys-lru
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '2.0'
```

### Windows (Docker Desktop)

#### Prerequisites
```powershell
# Install Docker Desktop for Windows
# Enable WSL2 integration
# Allocate resources in Docker Desktop settings
```

#### Windows-Specific Configuration
```yaml
# docker-compose.windows.yml
version: '3.8'

services:
  discoverylastfm:
    image: mrrobotogit/discoverylastfm:latest
    volumes:
      # Windows path mapping
      - type: bind
        source: C:\DiscoveryLastFM\config
        target: /app/config
      - type: bind
        source: C:\DiscoveryLastFM\logs
        target: /app/logs
      - type: bind
        source: D:\Music
        target: /music

  lidarr:
    volumes:
      - type: bind
        source: C:\Lidarr\config
        target: /config
      - type: bind
        source: D:\Music
        target: /music
      - type: bind
        source: D:\Downloads
        target: /downloads
```

### macOS (Docker Desktop)

#### macOS Configuration
```yaml
# docker-compose.macos.yml
version: '3.8'

services:
  discoverylastfm:
    image: mrrobotogit/discoverylastfm:latest
    volumes:
      # macOS path mapping
      - type: bind
        source: /Users/username/DiscoveryLastFM/config
        target: /app/config
      - type: bind
        source: /Users/username/DiscoveryLastFM/logs
        target: /app/logs
      - type: bind
        source: /Users/username/Music
        target: /music
```

## Production Deployments

### High Availability Setup

#### Load Balanced Configuration
```yaml
# docker-compose.ha.yml
version: '3.8'

services:
  # Primary discovery instance
  discoverylastfm-primary:
    image: mrrobotogit/discoverylastfm:latest
    environment:
      - DISCOVERY_MODE=cron
      - CRON_SCHEDULE=0 3 * * *
      - INSTANCE_ID=primary
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.role == manager

  # Secondary discovery instance (different schedule)
  discoverylastfm-secondary:
    image: mrrobotogit/discoverylastfm:latest
    environment:
      - DISCOVERY_MODE=cron
      - CRON_SCHEDULE=0 15 * * *
      - INSTANCE_ID=secondary
      - RECENT_MONTHS=1  # Quick discoveries
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.role != manager

  # Load balancer
  haproxy:
    image: haproxy:alpine
    ports:
      - "8080:8080"
    volumes:
      - ./haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.role == manager

  # Redis cluster
  redis-master:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.role == manager

  redis-replica:
    image: redis:7-alpine
    command: redis-server --replicaof redis-master 6379
    deploy:
      replicas: 2
```

#### HAProxy Configuration
```
# haproxy.cfg
global
    daemon
    maxconn 256

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend discoverylastfm_frontend
    bind *:8080
    default_backend discoverylastfm_backend

backend discoverylastfm_backend
    balance roundrobin
    option httpchk GET /health
    server primary discoverylastfm-primary:8080 check
    server secondary discoverylastfm-secondary:8080 check backup
```

### Monitoring & Observability

#### Prometheus Stack
```yaml
# docker-compose.monitoring.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/dashboards:/etc/grafana/provisioning/dashboards
      - ./grafana/datasources:/etc/grafana/provisioning/datasources

  alertmanager:
    image: prom/alertmanager:latest
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml

volumes:
  prometheus_data:
  grafana_data:
```

#### Logging Stack (ELK)
```yaml
# docker-compose.logging.yml
version: '3.8'

services:
  elasticsearch:
    image: elasticsearch:7.17.0
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data

  logstash:
    image: logstash:7.17.0
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf

  kibana:
    image: kibana:7.17.0
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200

volumes:
  elasticsearch_data:
```

## Cloud Deployments

### AWS ECS Deployment

#### Task Definition
```json
{
  "family": "discoverylastfm",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::ACCOUNT:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "discoverylastfm",
      "image": "mrrobotogit/discoverylastfm:latest",
      "essential": true,
      "environment": [
        {"name": "DISCOVERY_MODE", "value": "daemon"},
        {"name": "SLEEP_HOURS", "value": "6"}
      ],
      "secrets": [
        {
          "name": "LASTFM_API_KEY",
          "valueFrom": "arn:aws:secretsmanager:region:account:secret:lastfm-api-key"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/discoverylastfm",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

#### CloudFormation Template
```yaml
# cloudformation-template.yml
AWSTemplateFormatVersion: '2010-09-09'
Resources:
  ECSCluster:
    Type: AWS::ECS::Cluster
    Properties:
      ClusterName: discoverylastfm-cluster

  TaskDefinition:
    Type: AWS::ECS::TaskDefinition
    Properties:
      Family: discoverylastfm
      Cpu: 256
      Memory: 512
      NetworkMode: awsvpc
      RequiresCompatibilities:
        - FARGATE
      ExecutionRoleArn: !Ref TaskExecutionRole
      ContainerDefinitions:
        - Name: discoverylastfm
          Image: mrrobotogit/discoverylastfm:latest
          Essential: true
          Environment:
            - Name: DISCOVERY_MODE
              Value: daemon

  Service:
    Type: AWS::ECS::Service
    Properties:
      Cluster: !Ref ECSCluster
      TaskDefinition: !Ref TaskDefinition
      DesiredCount: 1
      LaunchType: FARGATE
      NetworkConfiguration:
        AwsvpcConfiguration:
          SecurityGroups:
            - !Ref SecurityGroup
          Subnets:
            - subnet-12345678
            - subnet-87654321
```

### Google Cloud Run

#### Deployment Configuration
```yaml
# cloudrun-service.yml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: discoverylastfm
  annotations:
    run.googleapis.com/ingress: internal
spec:
  template:
    metadata:
      annotations:
        autoscaling.knative.dev/maxScale: "1"
        autoscaling.knative.dev/minScale: "0"
    spec:
      containerConcurrency: 1
      containers:
      - image: mrrobotogit/discoverylastfm:latest
        env:
        - name: DISCOVERY_MODE
          value: "sync"
        - name: LASTFM_API_KEY
          valueFrom:
            secretKeyRef:
              key: api-key
              name: lastfm-secrets
        resources:
          limits:
            cpu: 1000m
            memory: 512Mi
```

#### Deployment Script
```bash
#!/bin/bash
# deploy-cloudrun.sh

# Set project and region
gcloud config set project your-project-id
gcloud config set run/region us-central1

# Create secrets
echo "your-lastfm-api-key" | gcloud secrets create lastfm-api-key --data-file=-

# Deploy service
gcloud run deploy discoverylastfm \
  --image mrrobotogit/discoverylastfm:latest \
  --platform managed \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 0 \
  --max-instances 1 \
  --set-env-vars DISCOVERY_MODE=sync \
  --update-secrets LASTFM_API_KEY=lastfm-api-key:latest

# Schedule with Cloud Scheduler
gcloud scheduler jobs create http discoverylastfm-schedule \
  --schedule="0 3 * * *" \
  --uri="https://discoverylastfm-xxx-uc.a.run.app" \
  --http-method=POST
```

### Azure Container Instances

#### ARM Template
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "resources": [
    {
      "type": "Microsoft.ContainerInstance/containerGroups",
      "apiVersion": "2021-09-01",
      "name": "discoverylastfm-group",
      "location": "[resourceGroup().location]",
      "properties": {
        "containers": [
          {
            "name": "discoverylastfm",
            "properties": {
              "image": "mrrobotogit/discoverylastfm:latest",
              "resources": {
                "requests": {
                  "cpu": 0.5,
                  "memoryInGb": 0.5
                }
              },
              "environmentVariables": [
                {
                  "name": "DISCOVERY_MODE",
                  "value": "daemon"
                },
                {
                  "name": "SLEEP_HOURS",
                  "value": "6"
                }
              ]
            }
          }
        ],
        "osType": "Linux",
        "restartPolicy": "Always"
      }
    }
  ]
}
```

## Network Attached Storage (NAS)

### Synology NAS

#### DSM Docker Configuration
```yaml
# docker-compose.synology.yml
version: '3.8'

services:
  discoverylastfm:
    image: mrrobotogit/discoverylastfm:latest
    container_name: discoverylastfm
    hostname: discoverylastfm
    restart: unless-stopped
    environment:
      - PUID=1026  # Synology Docker user
      - PGID=100   # Synology users group
      - TZ=Europe/Rome
      - DISCOVERY_MODE=cron
      - CRON_SCHEDULE=0 3 * * *
    volumes:
      - /volume1/docker/discoverylastfm/config:/app/config
      - /volume1/docker/discoverylastfm/logs:/app/logs
      - /volume1/music:/music
    networks:
      - media

  lidarr:
    image: lscr.io/linuxserver/lidarr:latest
    container_name: lidarr
    environment:
      - PUID=1026
      - PGID=100
      - TZ=Europe/Rome
    volumes:
      - /volume1/docker/lidarr/config:/config
      - /volume1/music:/music
      - /volume1/downloads:/downloads
    ports:
      - 8686:8686
    networks:
      - media

networks:
  media:
    external: true
```

#### Installation Script for Synology
```bash
#!/bin/bash
# synology-setup.sh

# Enable SSH on Synology and run this script

# Create directory structure
sudo mkdir -p /volume1/docker/discoverylastfm/{config,logs}
sudo mkdir -p /volume1/docker/lidarr/config

# Set permissions
sudo chown -R 1026:100 /volume1/docker/discoverylastfm
sudo chown -R 1026:100 /volume1/docker/lidarr

# Create docker network
docker network create media

# Download compose file
curl -o /volume1/docker/docker-compose.yml \
  https://raw.githubusercontent.com/MrRobotoGit/DiscoveryLastFM-Docker/main/examples/nas-synology/docker-compose.synology.yml

# Start services
cd /volume1/docker
docker-compose up -d

echo "Setup complete! Access Lidarr at http://your-nas-ip:8686"
```

### QNAP NAS

#### Container Station Configuration
```yaml
# docker-compose.qnap.yml
version: '3.8'

services:
  discoverylastfm:
    image: mrrobotogit/discoverylastfm:latest
    container_name: discoverylastfm
    restart: unless-stopped
    environment:
      - PUID=1000  # QNAP admin user
      - PGID=1000  # QNAP administrators group
      - TZ=Europe/Rome
    volumes:
      - /share/Container/discoverylastfm/config:/app/config
      - /share/Container/discoverylastfm/logs:/app/logs
      - /share/Music:/music
    networks:
      - qnap-media

networks:
  qnap-media:
    driver: bridge
```

### Unraid

#### Unraid Template
```xml
<?xml version="1.0"?>
<Container version="2">
  <Name>DiscoveryLastFM</Name>
  <Repository>mrrobotogit/discoverylastfm:latest</Repository>
  <Registry>https://hub.docker.com/r/mrrobotogit/discoverylastfm</Registry>
  <Network>bridge</Network>
  <MyIP/>
  <Shell>bash</Shell>
  <Privileged>false</Privileged>
  <Support>https://github.com/MrRobotoGit/DiscoveryLastFM-Docker</Support>
  <Project>https://github.com/MrRobotoGit/DiscoveryLastFM</Project>
  <Overview>Automated music discovery integration for Last.fm and music managers</Overview>
  <Category>MediaApp:Music</Category>
  <WebUI/>
  <TemplateURL/>
  <Icon>https://raw.githubusercontent.com/MrRobotoGit/DiscoveryLastFM-Docker/main/icon.png</Icon>
  <ExtraParams>--restart=unless-stopped</ExtraParams>
  <PostArgs/>
  <CPUset/>
  <DateInstalled></DateInstalled>
  <DonateText/>
  <DonateLink/>
  <Description>Automated music discovery integration for Last.fm and music managers</Description>
  <Networking>
    <Mode>bridge</Mode>
  </Networking>
  <Data>
    <Volume>
      <HostDir>/mnt/user/appdata/discoverylastfm/config</HostDir>
      <ContainerDir>/app/config</ContainerDir>
      <Mode>rw</Mode>
    </Volume>
    <Volume>
      <HostDir>/mnt/user/appdata/discoverylastfm/logs</HostDir>
      <ContainerDir>/app/logs</ContainerDir>
      <Mode>rw</Mode>
    </Volume>
    <Volume>
      <HostDir>/mnt/user/music</HostDir>
      <ContainerDir>/music</ContainerDir>
      <Mode>ro</Mode>
    </Volume>
  </Data>
  <Environment>
    <Variable>
      <Value>discoverylastfm</Value>
      <Name>CONTAINER_NAME</Name>
      <Mode/>
    </Variable>
    <Variable>
      <Value>99</Value>
      <Name>PUID</Name>
      <Mode/>
    </Variable>
    <Variable>
      <Value>100</Value>
      <Name>PGID</Name>
      <Mode/>
    </Variable>
    <Variable>
      <Value>cron</Value>
      <Name>DISCOVERY_MODE</Name>
      <Mode/>
    </Variable>
  </Environment>
  <Labels/>
  <Config Name="Config" Target="/app/config" Default="/mnt/user/appdata/discoverylastfm/config" Mode="rw" Description="" Type="Path" Display="always" Required="true" Mask="false">/mnt/user/appdata/discoverylastfm/config</Config>
  <Config Name="Logs" Target="/app/logs" Default="/mnt/user/appdata/discoverylastfm/logs" Mode="rw" Description="" Type="Path" Display="always" Required="true" Mask="false">/mnt/user/appdata/discoverylastfm/logs</Config>
</Container>
```

## Kubernetes Deployments

### Basic Kubernetes Deployment

#### Namespace and ConfigMap
```yaml
# k8s-namespace.yml
apiVersion: v1
kind: Namespace
metadata:
  name: discoverylastfm

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: discoverylastfm-config
  namespace: discoverylastfm
data:
  DISCOVERY_MODE: "cron"
  CRON_SCHEDULE: "0 3 * * *"
  MUSIC_SERVICE: "lidarr"
  DEBUG: "false"
```

#### Secrets
```yaml
# k8s-secrets.yml
apiVersion: v1
kind: Secret
metadata:
  name: discoverylastfm-secrets
  namespace: discoverylastfm
type: Opaque
data:
  lastfm-username: <base64-encoded-username>
  lastfm-api-key: <base64-encoded-api-key>
  lidarr-api-key: <base64-encoded-lidarr-key>
```

#### Deployment
```yaml
# k8s-deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: discoverylastfm
  namespace: discoverylastfm
spec:
  replicas: 1
  selector:
    matchLabels:
      app: discoverylastfm
  template:
    metadata:
      labels:
        app: discoverylastfm
    spec:
      containers:
      - name: discoverylastfm
        image: mrrobotogit/discoverylastfm:latest
        envFrom:
        - configMapRef:
            name: discoverylastfm-config
        env:
        - name: LASTFM_USERNAME
          valueFrom:
            secretKeyRef:
              name: discoverylastfm-secrets
              key: lastfm-username
        - name: LASTFM_API_KEY
          valueFrom:
            secretKeyRef:
              name: discoverylastfm-secrets
              key: lastfm-api-key
        - name: LIDARR_API_KEY
          valueFrom:
            secretKeyRef:
              name: discoverylastfm-secrets
              key: lidarr-api-key
        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
          requests:
            memory: "256Mi"
            cpu: "100m"
        volumeMounts:
        - name: config-volume
          mountPath: /app/config
        - name: logs-volume
          mountPath: /app/logs
        livenessProbe:
          exec:
            command:
            - /usr/local/bin/health-check
            - quick
          initialDelaySeconds: 30
          periodSeconds: 60
        readinessProbe:
          exec:
            command:
            - /usr/local/bin/health-check
            - config
          initialDelaySeconds: 10
          periodSeconds: 30
      volumes:
      - name: config-volume
        persistentVolumeClaim:
          claimName: discoverylastfm-config-pvc
      - name: logs-volume
        persistentVolumeClaim:
          claimName: discoverylastfm-logs-pvc
```

#### Persistent Volume Claims
```yaml
# k8s-pvc.yml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: discoverylastfm-config-pvc
  namespace: discoverylastfm
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: discoverylastfm-logs-pvc
  namespace: discoverylastfm
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

#### CronJob Alternative
```yaml
# k8s-cronjob.yml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: discoverylastfm-cronjob
  namespace: discoverylastfm
spec:
  schedule: "0 3 * * *"  # Daily at 3 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: discoverylastfm
            image: mrrobotogit/discoverylastfm:latest
            env:
            - name: DISCOVERY_MODE
              value: "sync"
            envFrom:
            - configMapRef:
                name: discoverylastfm-config
            - secretRef:
                name: discoverylastfm-secrets
          restartPolicy: OnFailure
```

### Helm Chart

#### Chart Structure
```
discoverylastfm-chart/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   └── ingress.yaml
└── charts/
```

#### Chart.yaml
```yaml
apiVersion: v2
name: discoverylastfm
description: A Helm chart for DiscoveryLastFM
type: application
version: 1.0.0
appVersion: "2.1.0"
```

#### values.yaml
```yaml
image:
  repository: mrrobotogit/discoverylastfm
  tag: latest
  pullPolicy: IfNotPresent

replicaCount: 1

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 256Mi

config:
  discoveryMode: cron
  cronSchedule: "0 3 * * *"
  musicService: lidarr
  debug: false

secrets:
  lastfmUsername: ""
  lastfmApiKey: ""
  lidarrApiKey: ""

persistence:
  enabled: true
  storageClass: ""
  accessMode: ReadWriteOnce
  size: 5Gi

service:
  type: ClusterIP
  port: 8080

ingress:
  enabled: false
  className: ""
  annotations: {}
  hosts: []
  tls: []
```

## Maintenance & Updates

### Automated Updates

#### Watchtower Configuration
```yaml
# Automatic container updates
watchtower:
  image: containrrr/watchtower:latest
  environment:
    - WATCHTOWER_POLL_INTERVAL=86400  # Daily checks
    - WATCHTOWER_CLEANUP=true
    - WATCHTOWER_INCLUDE_RESTARTING=true
    - WATCHTOWER_NOTIFICATIONS=slack
    - WATCHTOWER_NOTIFICATION_SLACK_HOOK_URL=https://hooks.slack.com/...
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
```

#### Renovate Bot (for Git-based deployments)
```json
{
  "extends": ["config:base"],
  "docker": {
    "fileMatch": ["docker-compose.*\\.ya?ml$"],
    "major": {"enabled": false},
    "minor": {"enabled": true},
    "patch": {"enabled": true}
  },
  "schedule": ["before 6am on monday"]
}
```

### Backup Strategies

#### Volume Backup Script
```bash
#!/bin/bash
# backup.sh

BACKUP_DIR="/backups/discoverylastfm"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup Docker volumes
docker run --rm \
  -v discoverylastfm_config:/source/config:ro \
  -v discoverylastfm_logs:/source/logs:ro \
  -v "$BACKUP_DIR":/backup \
  alpine \
  tar czf "/backup/discoverylastfm_backup_$DATE.tar.gz" -C /source .

# Keep only last 30 days of backups
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete

echo "Backup completed: discoverylastfm_backup_$DATE.tar.gz"
```

#### Kubernetes Backup with Velero
```bash
# Install Velero
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.5.0 \
  --bucket velero-backups \
  --secret-file ./credentials-velero

# Schedule backup
velero schedule create discoverylastfm-daily \
  --schedule="0 3 * * *" \
  --include-namespaces discoverylastfm \
  --ttl 720h
```

### Rolling Updates

#### Zero-Downtime Updates
```bash
#!/bin/bash
# rolling-update.sh

# Pull new image
docker-compose pull discoverylastfm

# Create backup before update
./backup.sh

# Rolling update with health check
docker-compose up -d --no-deps discoverylastfm

# Wait for health check
timeout 60s bash -c 'until [ "$(docker inspect --format="{{.State.Health.Status}}" discoverylastfm)" = "healthy" ]; do sleep 2; done'

if [ $? -eq 0 ]; then
  echo "Update successful"
  # Cleanup old image
  docker image prune -f
else
  echo "Update failed, rolling back"
  docker-compose down
  docker-compose up -d
fi
```

This deployment guide covers most scenarios you'll encounter when deploying DiscoveryLastFM. Choose the approach that best fits your infrastructure and requirements.