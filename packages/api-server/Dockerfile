# Multi-stage Dockerfile for pre-built api-server
FROM node:18-alpine AS base

ENV HOST=0.0.0.0
ENV PORT=3000

# Install pnpm globally to match the lock file
RUN npm install -g pnpm

# Create non-root user for security (shared across stages)
RUN addgroup -g 1001 --system api && \
    adduser -u 1001 --system -G api api

# ------------------------------------------------

# Dependencies stage - Install production dependencies
FROM base AS deps
WORKDIR /app

# Copy the entire pre-built dist (which includes package.json and pnpm-lock.yaml)
COPY ./dist ./api/

# Install production dependencies using pnpm to respect the lock file
RUN pnpm --prefix api install --frozen-lockfile --prod

# Change ownership
RUN chown -R api:api .

# ------------------------------------------------

# Production image
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production

# Copy the application with dependencies from deps stage
COPY --from=deps --chown=api:api /app ./

USER api

# Expose port
EXPOSE 3000

# Health check with better timing for startup
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').request('http://localhost:3000/api/health', (res) => process.exit(res.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1)).end()"

# Start the application with proper signal handling
CMD ["node", "api"]

# Add metadata labels for better maintainability
LABEL maintainer="rsschool-devops-course" \
      version="1.0" \
      description="API Server for DevOps Course"
