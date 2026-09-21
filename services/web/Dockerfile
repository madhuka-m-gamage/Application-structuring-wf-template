# ==============================================================================
# Multi-Stage Secure Dockerfile for Web Frontend Service
# Base: Node.js 22 Alpine
# Security: Runs as unprivileged 'appuser' (UID 10001)
# ==============================================================================

FROM node:22-alpine AS builder

WORKDIR /app

# Copy package manifests. This service intentionally has no runtime dependencies,
# so support both lockfile-backed builds and the repository template state.
COPY package*.json ./
RUN if [ -f package-lock.json ]; then \
      npm ci --omit=dev --no-audit --no-fund; \
    else \
      npm install --omit=dev --no-audit --no-fund; \
    fi

COPY . .

FROM node:22-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production \
    PORT=3000 \
    HOST=0.0.0.0 \
    API_URL=http://api:8080

RUN addgroup -g 10001 -S appgroup && \
    adduser -u 10001 -S appuser -G appgroup

COPY --from=builder --chown=appuser:appgroup /app /app

USER appuser
EXPOSE 3000

HEALTHCHECK --interval=15s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:3000/healthz || exit 1

CMD ["node", "src/server.js"]
