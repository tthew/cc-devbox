# Container Rebuild Instructions

## Issue
Your container is running with the old Squid proxy configuration, which is causing the Playwright HTTPS protocol error. The new DNS-based configuration needs to be built and deployed.

## Solution Steps

### 1. Stop and Remove Old Container
```bash
cd /Users/tthew/Development/cc-devbox
docker-compose down
```

### 2. Rebuild with New Configuration
```bash
# Force rebuild without cache to ensure new configuration is used
docker-compose build --no-cache claude-dev
```

### 3. Start New Container
```bash
docker-compose up -d claude-dev
```

### 4. Verify New Configuration
```bash
# Check container is running with new ports (should NOT show 3128, 8080)
docker ps

# Connect to container
ssh dev@localhost -p 2222
# Password: dev
```

### 5. Test Inside Container
Once connected to the container:
```bash
# Check what services are running (should see dnsmasq, not squid)
ps aux | grep -E "(squid|dnsmasq)"

# Check proxy environment variables (should be empty)
printenv | grep -i proxy

# Test Playwright installation
npx playwright install chromium
```

## Expected Results

### Before Rebuild (Current State)
- Container ports: 3000-3001, 3128, 8080, 2222
- Services: Squid proxy running
- Environment: proxy variables set
- Playwright: Fails with protocol error

### After Rebuild (New State)
- Container ports: 3000-3001, 2222 (no proxy ports)
- Services: dnsmasq DNS server running
- Environment: no proxy variables
- Playwright: Works successfully

## What Changed

1. **Dockerfile**: Removed Squid, added dnsmasq
2. **entrypoint.sh**: Simplified from 450 → 190 lines
3. **Whitelist management**: Simple DNS-based script
4. **Configuration**: 20 lines instead of 248

The new system provides the same security (domain whitelisting) without the complexity and protocol issues of Squid.