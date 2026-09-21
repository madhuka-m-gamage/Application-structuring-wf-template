# ==============================================================================
# Multi-Stage Secure Dockerfile for Web Frontend Service
# Base: Node.js 20 Alpine
# Security: Runs as unprivileged 'appuser' (UID 10001)
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage 1: Build & Asset Optimization
# ------------------------------------------------------------------------------
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package manifests
COPY package*.json ./

# Install dependencies if present
RUN npm ci --omit=dev || npm install --omit=dev

# Copy application and public assets
COPY . .

# ------------------------------------------------------------------------------
# Stage 2: Hardened Runtime Container
# ------------------------------------------------------------------------------
FROM node:20-alpine AS runner

WORKDIR /app

# Environment defaults
ENV NODE_ENV=production \
    PORT=3000 \
    HOST=0.0.0.0 \
    API_URL=http://api:8080

# Create dedicated non-root application user and group
RUN addgroup -g 10001 -S appgroup && \
    adduser -u 10001 -S appuser -G appgroup

# Copy artifacts from builder stage
COPY --from=builder --chown=appuser:appgroup /app /app

# Switch to non-root execution context
USER appuser

# Expose HTTP port
EXPOSE 3000

# Native healthcheck probe invoking /healthz
HEALTHCHECK --interval=15s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:3000/healthz || exit 1

# Start web server
CMD ["node", "src/server.js"]
