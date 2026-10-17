# Image for the pre-built api-server: run `nx build api-server --configuration=production` first
#
# Dependencies are pure JavaScript, so they are installed on the build platform and copied
# into the target image. The target stage has no RUN steps, which keeps multi-arch builds
# off QEMU emulation (node 22 crashes there with SIGILL). Requires BuildKit (Docker 23+ default).
FROM --platform=$BUILDPLATFORM node:22-alpine AS deps
WORKDIR /app

# dist contains main.js, assets and a generated package.json + package-lock.json
COPY ./dist ./api/
RUN npm ci --prefix api --omit=dev && npm cache clean --force

# ------------------------------------------------

FROM node:22-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production \
    HOST=0.0.0.0 \
    PORT=3000

# Numeric non-root user (matches runAsUser in the Helm chart); no passwd entry needed
COPY --from=deps --chown=1001:1001 /app ./

USER 1001:1001

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').request('http://localhost:3000/api/health', (res) => process.exit(res.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1)).end()"

CMD ["node", "api"]

LABEL org.opencontainers.image.source="https://github.com/alexpialetski/rsschool-devops-course-tasks" \
      org.opencontainers.image.description="API Server for RS School DevOps Course"
