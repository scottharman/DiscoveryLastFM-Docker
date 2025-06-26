# Claude Code Configuration

## Project Authors
- **Main Author**: MrRobotoGit
- **Contributors**: See individual pull request authors

## Commit Guidelines
- NO references to Claude or AI assistance in commit messages
- NO "Co-Authored-By: Claude" in commits
- Authors should be actual human contributors only
- Use standard conventional commit format

## Docker Commands
- Use `docker compose` (modern syntax) instead of `docker-compose`
- Test commands: `npm test` or check package.json for test scripts
- Lint commands: Check package.json or README for linting setup

## Repository Structure
- Main application: DiscoveryLastFM integration
- Docker setup: Simplified configuration (DiscoveryLastFM + Redis)
- CI/CD: GitHub Actions with Docker Hub sync