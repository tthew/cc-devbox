# Multi-stage build optimized for Apple Silicon M4 Pro
# =======================================================

# Build stage for heavy dependencies
FROM --platform=linux/arm64 ubuntu:24.04 AS builder

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set timezone
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install build dependencies in a single layer for better caching
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    ca-certificates \
    gnupg \
    lsb-release \
    build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Install Node.js 20 LTS for ARM64
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Install global npm packages with aggressive caching
RUN npm install -g npm@latest pnpm@latest tsx@latest \
    && npm cache clean --force

# Download and install ARM64 binaries
RUN curl -LsSf https://github.com/dandavison/delta/releases/download/0.17.0/delta-0.17.0-aarch64-unknown-linux-gnu.tar.gz | tar -xz \
    && mv delta-0.17.0-aarch64-unknown-linux-gnu/delta /usr/local/bin/ \
    && rm -rf delta-0.17.0-aarch64-unknown-linux-gnu

# Runtime stage - lightweight
FROM --platform=linux/arm64 ubuntu:24.04 AS runtime

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set timezone
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Copy built binaries from builder stage
COPY --from=builder /usr/local/bin/delta /usr/local/bin/

# Install only essential runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core system tools
    curl \
    wget \
    git \
    openssh-server \
    sudo \
    vim \
    nano \
    # Development tools
    python3 \
    python3-pip \
    ca-certificates \
    jq \
    zsh \
    fzf \
    # Network tools
    dnsutils \
    iproute2 \
    # System utilities
    tree \
    less \
    # Lightweight DNS for domain filtering
    dnsmasq \
    iptables \
    # Cleanup in same layer
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* /var/tmp/*

# Install Node.js 20 LTS with cleanup
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* /var/tmp/*

# Install global npm packages directly in runtime stage
RUN npm install -g npm@latest pnpm@latest tsx@latest \
    && npm cache clean --force

# Install AWS CLI via pip3 (simpler and more reliable than binary installer)
RUN pip3 install --no-cache-dir awscli --break-system-packages \
    && aws --version

# Install GitHub CLI with cleanup
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && apt-get clean \
    && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

# Install delta for better git diffs (Claude Code recommendation)
RUN curl -LsSf https://github.com/dandavison/delta/releases/download/0.17.0/delta-0.17.0-aarch64-unknown-linux-gnu.tar.gz | tar -xz \
    && mv delta-0.17.0-aarch64-unknown-linux-gnu/delta /usr/local/bin/ \
    && rm -rf delta-0.17.0-aarch64-unknown-linux-gnu

# Create development user (following Claude Code patterns)
RUN useradd -m -s /bin/zsh dev \
    && echo "dev:dev" | chpasswd \
    && usermod -aG sudo dev \
    && echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && chmod 755 /home/dev \
    && chown -R dev:dev /home/dev \
    && mkdir -p /home/dev/.local/share \
    && chown -R dev:dev /home/dev/.local

# Configure SSH
RUN mkdir /var/run/sshd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
    && echo 'Port 22' >> /etc/ssh/sshd_config

# Set up SSH keys for dev user
USER dev
WORKDIR /home/dev
RUN mkdir -p .ssh \
    && chmod 700 .ssh \
    && ssh-keygen -t rsa -b 4096 -f .ssh/id_rsa -N "" \
    && cat .ssh/id_rsa.pub >> .ssh/authorized_keys \
    && chmod 600 .ssh/authorized_keys

# Configure git with direct .gitconfig creation
RUN echo '[user]' > ~/.gitconfig \
    && echo '    name = Matt Richards' >> ~/.gitconfig \
    && echo '    email = m@tthew.berlin' >> ~/.gitconfig \
    && echo '[init]' >> ~/.gitconfig \
    && echo '    defaultBranch = main' >> ~/.gitconfig \
    && echo '[push]' >> ~/.gitconfig \
    && echo '    default = simple' >> ~/.gitconfig \
    && echo '[pull]' >> ~/.gitconfig \
    && echo '    rebase = false' >> ~/.gitconfig \
    && echo '[safe]' >> ~/.gitconfig \
    && echo '    directory = /workspace' >> ~/.gitconfig \
    && echo '    directory = *' >> ~/.gitconfig \
    && echo '[alias]' >> ~/.gitconfig \
    && echo '    st = status -s' >> ~/.gitconfig \
    && echo '    diff = diff --word-diff' >> ~/.gitconfig \
    && echo '    branch = branch -ra' >> ~/.gitconfig \
    && echo '    grep = grep -Ii' >> ~/.gitconfig \
    && echo '    ls = log --pretty=format:"%C(green)%h\\ %C(yellow)[%ad]%Cred%d\\ %Creset%s%Cblue\\ [%cn]" --decorate --date=relative' >> ~/.gitconfig \
    && echo '    ll = log --pretty=format:"%C(yellow)%h%Cred%d\\ %Creset%s%Cblue\\ [%cn]" --decorate --numstat' >> ~/.gitconfig

# Configure npm global directory (Claude Code will be installed in entrypoint for persistent home)
RUN mkdir -p ~/.npm-global \
    && npm config set prefix ~/.npm-global \
    && echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc \
    && echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc \
    && npm cache clean --force

# Note: Gemini CLI installation can be added later when specific package is identified

# Note: uv will be installed in entrypoint for persistent home directory

# Configure shell history persistence (Claude Code pattern)
RUN mkdir -p ~/.local/share/zsh ~/.local/share/bash \
    && echo 'export HISTFILE=~/.local/share/zsh/history' >> ~/.zshrc \
    && echo 'export HISTSIZE=10000' >> ~/.zshrc \
    && echo 'export SAVEHIST=10000' >> ~/.zshrc \
    && echo 'export HISTFILE=~/.local/share/bash/history' >> ~/.bashrc \
    && echo 'export HISTSIZE=10000' >> ~/.bashrc \
    && echo 'export HISTFILESIZE=10000' >> ~/.bashrc

# Set up ZSH as default shell with enhanced configuration
RUN echo '# Basic ZSH setup for Claude Code development' >> ~/.zshrc \
    && echo 'autoload -U compinit && compinit' >> ~/.zshrc \
    && echo 'autoload -U colors && colors' >> ~/.zshrc \
    && echo 'setopt HIST_IGNORE_DUPS' >> ~/.zshrc \
    && echo 'setopt HIST_FIND_NO_DUPS' >> ~/.zshrc \
    && echo 'setopt SHARE_HISTORY' >> ~/.zshrc \
    && echo 'setopt AUTO_CD' >> ~/.zshrc \
    && echo 'setopt AUTO_PUSHD' >> ~/.zshrc \
    && echo 'setopt PUSHD_IGNORE_DUPS' >> ~/.zshrc

# Add paths to environment
ENV PATH="/home/dev/.npm-global/bin:/home/dev/.local/bin:$PATH"

# Switch back to root for system configuration
USER root

# Ensure home directory is writable
RUN chown -R dev:dev /home/dev && chmod -R u+w /home/dev

# Switch back to root for system configuration
USER root

# Create workspace directory with proper ownership
RUN mkdir -p /workspace && chown -R dev:dev /workspace
WORKDIR /workspace

# Copy startup scripts
COPY --chown=dev:dev scripts/ /home/dev/scripts/
RUN chmod +x /home/dev/scripts/*

# Install Supabase CLI (configured for host services)
RUN curl -fsSL https://cli.supabase.com/install.sh | bash

# Add Supabase to PATH for all users
ENV PATH="/usr/local/bin:$PATH"

# Configure Supabase CLI to use host services
RUN echo '#!/bin/bash\nsupabase "$@" --project-ref host --db-url postgresql://postgres:postgres@host.docker.internal:54322/postgres' > /usr/local/bin/supabase-host && chmod +x /usr/local/bin/supabase-host

# Clean up package cache before Playwright installation
RUN apt-get clean && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

# Install only essential browser dependencies for ARM compatibility (Ubuntu 24.04 updated packages)
RUN apt-get update && apt-get install -y \
    chromium-browser \
    firefox \
    xvfb \
    libgtk-3-0 \
    libgdk-pixbuf2.0-0 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libasound2t64 \
    libatk1.0-0 \
    libdrm2 \
    libxss1 \
    && apt-get clean \
    && apt-get autoremove -y \
    && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set environment variables for Playwright to use system browsers
ENV PLAYWRIGHT_BROWSERS_PATH=/usr/bin
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

# Configure development environment optimized for M4 Pro
ENV NODE_ENV=development
ENV NEXT_TELEMETRY_DISABLED=1
ENV CONTAINER_ENV=development
ENV TERM=xterm-256color
ENV SHELL=/bin/zsh
# M4 Pro optimization: increase memory limit and enable experimental features
ENV NODE_OPTIONS="--max-old-space-size=8192 --experimental-wasm-modules --experimental-worker"
ENV UV_THREADPOOL_SIZE=16
ENV TZ=${TZ:-UTC}
# Performance optimizations
ENV npm_config_cache=/workspace/.npm-cache
ENV PNPM_HOME=/workspace/.pnpm
ENV NPM_CONFIG_UPDATE_NOTIFIER=false
ENV NPM_CONFIG_FUND=false
ENV NPM_CONFIG_AUDIT=false

# Create log directories and set permissions, final cleanup
RUN mkdir -p /workspace/logs && \
    chown -R dev:dev /workspace/logs && \
    apt-get clean && \
    rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache

# Create entrypoint script and DNS whitelist configuration
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY whitelist.conf /etc/dnsmasq.d/whitelist.conf
COPY whitelist /usr/local/bin/whitelist
COPY manage-whitelist.sh /usr/local/bin/manage-whitelist.sh
RUN chmod +x /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/whitelist && \
    chmod +x /usr/local/bin/manage-whitelist.sh

# Expose ports
EXPOSE 22 3000 3001

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]