# ─────────────────────────────────────────────
# Stage 1: Build
# ─────────────────────────────────────────────
FROM node:22-bookworm AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 make g++ pkg-config \
        libgtk-3-dev libnotify-dev libnss3 libxss1 libxtst-dev \
        libatspi2.0-dev libdrm-dev libgbm-dev libasound2-dev \
        libglib2.0-dev libxrandr-dev libcups2-dev \
        ca-certificates xz-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --prefer-offline

COPY . .
RUN npm run build:unpack

# Normalise arch-specific output dir to dist/app
RUN set -e; \
    SRC="$(find dist -maxdepth 1 -type d \
           \( -name 'linux-unpacked' -o -name 'linux-*-unpacked' \) \
           -print -quit)"; \
    [ -n "$SRC" ] || { echo "ERROR: linux-unpacked not found"; ls dist/; exit 1; }; \
    mv "$SRC" dist/app

# ─────────────────────────────────────────────
# Stage 2: Runtime
# Uses jlesage/baseimage-gui which bundles:
#   - TigerVNC server  (port 5900)
#   - noVNC + nginx    (port 5800, single HTTP port)
#   - openbox
#   - s6-overlay       (process supervision)
# App just needs to provide /startapp.sh
# ─────────────────────────────────────────────
FROM jlesage/baseimage-gui:debian-12-v4

# Electron / Chromium runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        libgtk-3-0 libnotify4 libnss3 libxss1 libxtst6 \
        libatspi2.0-0 libdrm2 libgbm1 libasound2 \
        libglib2.0-0 libxrandr2 libcups2 \
        libxdamage1 libxfixes3 libxcomposite1 libxkbcommon0 \
        libx11-xcb1 libxcb-dri3-0 libxcb1 libxshmfence1 \
        libatk1.0-0 libatk-bridge2.0-0 \
        fonts-liberation ca-certificates xdotool \
    && rm -rf /var/lib/apt/lists/*

# App binary
COPY --from=builder /app/dist/app /app

# The baseimage-gui convention: /startapp.sh is exec'd inside the X session
COPY docker/startapp.sh /startapp.sh
RUN chmod +x /startapp.sh

# openbox autostart: maximize the app window when it appears
RUN mkdir -p /etc/xdg/openbox
COPY docker/openbox-autostart /etc/xdg/openbox/autostart

# Run as root so the app can write to /root/.chat2api
# (baseimage-gui respects USER_ID=0)
ENV USER_ID=0
ENV GROUP_ID=0

# Pre-create the data dir the app writes to
RUN mkdir -p /root/.chat2api /root/.pki/nssdb

# Persist user data — map this volume to keep config across restarts
VOLUME ["/root/.chat2api"]

# Metadata consumed by baseimage-gui
ENV APP_NAME="Chat2API"
ENV DISPLAY_WIDTH=1440
ENV DISPLAY_HEIGHT=900

# 5800 = noVNC web UI (HTTP), 5900 = raw VNC, 8080 = Chat2API proxy API
EXPOSE 5800 5900 8080
