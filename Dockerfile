FROM node:18-alpine AS deps
WORKDIR /app
RUN apk add --no-cache python3 make g++
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

FROM node:18-alpine AS runtime
ENV NODE_ENV=production \
    PORT=8000 \
    DATABASE_STORAGE=/data/dev.sqlite
WORKDIR /app
RUN apk add --no-cache tini \
    && addgroup -S nodejs -g 1001 \
    && adduser -S nodejs -u 1001 -G nodejs \
    && mkdir -p /data \
    && chown -R nodejs:nodejs /data
COPY --chown=nodejs:nodejs --from=deps /app/node_modules ./node_modules
COPY --chown=nodejs:nodejs . .
USER nodejs
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD wget -qO- "http://127.0.0.1:${PORT}/health/live" || exit 1
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "index.js"]
