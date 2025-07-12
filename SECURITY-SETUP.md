# Claude Code Development Environment - Secure Setup Guide

## Overview

This guide explains how to set up the Claude Code development environment with proper secret management. All sensitive credentials are externalized to environment variables and never committed to git.

## 🔒 Security Features

- **No hardcoded secrets** in Docker images or git repository
- **Environment-based configuration** using `.env.host` file  
- **Automatic validation** of required environment variables
- **Git protection** for secret files via `.gitignore`
- **Fail-fast behavior** if secrets are missing or invalid

## 📋 Prerequisites

- Docker and Docker Compose installed
- Access to Supabase project (or local Supabase setup)
- OpenSSL for generating secure secrets

## 🚀 Quick Setup

### 1. Create Environment File

Copy the example environment file and customize it:

```bash
cd .claude
cp .env.host.example .env.host
```

### 2. Generate Secure Secrets

Generate secure secrets for your environment:

```bash
# Generate JWT secret (32+ characters)
openssl rand -hex 32

# Generate NextAuth secret  
openssl rand -base64 32
```

### 3. Configure Secrets

Edit `.env.host` and replace the example values:

```bash
# Open your editor
nano .env.host  # or vim, code, etc.
```

**Required Variables to Update:**
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` - Get from Supabase Dashboard > Settings > API
- `SUPABASE_SERVICE_ROLE_KEY` - Get from Supabase Dashboard > Settings > API  
- `JWT_SECRET` - Use the generated value from step 2
- `NEXTAUTH_SECRET` - Use the generated value from step 2

### 4. Source Environment

Load the environment variables:

```bash
# Make sure you're in the .claude directory
source .env.host

# Verify variables are loaded
echo $JWT_SECRET
```

### 5. Start Container

Start the development environment:

```bash
docker-compose up --build
```

## 📁 File Structure

```
.claude/
├── .env.template          # Template showing all required variables
├── .env.host.example      # Example with safe demo values  
├── .env.host             # YOUR SECRETS (gitignored)
├── docker-compose.yml    # Uses environment variables
├── entrypoint.sh         # Validates environment
└── SECURITY-SETUP.md     # This file
```

## 🔍 Environment Variables Reference

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase API URL | `http://host.docker.internal:54321` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase public key | `eyJhbGciOiJ...` |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service key | `eyJhbGciOiJ...` |
| `DATABASE_URL` | PostgreSQL connection | `postgresql://...` |
| `DIRECT_URL` | Direct DB connection | `postgresql://...` |
| `JWT_SECRET` | JWT signing secret | `abc123...` (32+ chars) |
| `NEXTAUTH_SECRET` | NextAuth secret | `def456...` |
| `NEXTAUTH_URL` | App URL | `http://localhost:3000` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `S3_ACCESS_KEY` | Storage access key | _(empty)_ |
| `S3_SECRET_KEY` | Storage secret key | _(empty)_ |
| `S3_REGION` | Storage region | `local` |
| `SUPABASE_STUDIO_URL` | Studio URL | `http://host.docker.internal:54323` |
| `INBUCKET_URL` | Email testing URL | `http://host.docker.internal:54324` |

## 🛡️ Security Best Practices

### Do ✅

- **Always use `.env.host`** for sensitive credentials
- **Generate unique secrets** for each environment  
- **Use strong, random secrets** (32+ characters for JWT)
- **Source environment** before running Docker Compose
- **Keep `.env.host` private** and never commit it

### Don't ❌

- **Never commit secrets** to git repository
- **Don't use example values** in production
- **Don't skip environment validation** errors
- **Don't share `.env.host`** files between developers
- **Don't use short JWT secrets** (< 32 characters)

## 🔧 Troubleshooting

### Missing Environment Variables

If you see this error:
```
❌ Missing required environment variables:
  - JWT_SECRET
  - NEXTAUTH_SECRET
```

**Solution:**
1. Ensure `.env.host` file exists and has all required variables
2. Source the environment: `source .env.host`  
3. Verify variables are loaded: `echo $JWT_SECRET`

### JWT Secret Too Short

If you see:
```
❌ JWT_SECRET must be at least 32 characters long
```

**Solution:**
Generate a proper secret: `openssl rand -hex 32`

### Container Fails to Start

**Check logs:**
```bash
docker-compose logs claude-dev
```

**Common issues:**
- Environment not sourced
- Invalid variable values
- Missing required variables

### Environment Not Loaded

If variables aren't loading:

```bash
# Check if file exists
ls -la .env.host

# Check file contents (be careful not to expose secrets)
head -5 .env.host

# Source explicitly
source ./.env.host

# Verify specific variable
echo $NEXT_PUBLIC_SUPABASE_URL
```

## 🔄 Development Workflow

### Daily Development

```bash
# Start development session
cd .claude
source .env.host
docker-compose up

# SSH into container
ssh dev@localhost -p 2222
# Password: dev

# Inside container
claude  # Start Claude Code
```

### Updating Secrets

```bash
# Edit environment file
nano .env.host

# Rebuild container with new environment
source .env.host
docker-compose down
docker-compose up --build
```

### Team Setup

Each developer should:
1. Copy `.env.host.example` to `.env.host`
2. Get credentials from team lead or infrastructure
3. Update their local `.env.host` file  
4. Never commit their `.env.host` file

## 📚 Additional Resources

- [Environment Variables Template](/.env.template)
- [Example Configuration](/.env.host.example)  
- [Docker Compose Configuration](/docker-compose.yml)
- [Supabase Documentation](https://supabase.com/docs)
- [NextAuth Documentation](https://next-auth.js.org)

## 🆘 Getting Help

If you encounter issues:

1. **Check the troubleshooting section** above
2. **Verify all prerequisites** are installed
3. **Review container logs** for specific errors
4. **Ensure environment variables** are properly sourced

For additional support, refer to the main project documentation.