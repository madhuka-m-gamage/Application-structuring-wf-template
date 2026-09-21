# ==============================================================================
# Multi-Stage Secure Dockerfile for Background Event Worker Service
# Base: Node.js 20 Alpine
# Security: Runs as unprivileged 'appuser' (UID 10001)
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage 1: Build & Dependency Isolation
# ------------------------------------------------------------------------------
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package manifests
COPY package*.json ./

# Install production dependencies cleanly
RUN npm ci --omit=dev || npm install --omit=dev

# Copy source files
COPY . .

# ------------------------------------------------------------------------------
# Stage 2: Hardened Runtime Container
# ------------------------------------------------------------------------------
FROM node:20-alpine AS runner

WORKDIR /app

# Environment defaults
ENV NODE_ENV=production \
    PORT=8080 \
    HOST=0.0.0.0

# Create dedicated non-root application user and group
RUN addgroup -g 10001 -S appgroup && \
    adduser -u 10001 -S appuser -G appgroup

# Copy dependencies and code with non-root ownership
COPY --from=builder --chown=appuser:appgroup /app /app

# Switch to non-root execution context
USER appuser

# Expose HTTP port for Cloud Run Pub/Sub Push Subscription
EXPOSE 8080

# Native healthcheck probe invoking /healthz
HEALTHCHECK --interval=15s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:8080/healthz || exit 1

# Start worker service
CMD ["node", "src/index.js"]
