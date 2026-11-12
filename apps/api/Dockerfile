# ==========================================
# Stage 1: Build the NestJS API application
# ==========================================
FROM node:24.22.1-alpine AS builder

WORKDIR /app

RUN npm install -g --allow-scripts=pnpm pnpm@12.16.1

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/api/package.json ./apps/api/
COPY apps/web/package.json ./apps/web/

RUN pnpm install --frozen-lockfile --runtime-on-fail=ignore

COPY apps/api/ ./apps/api/

# Build backend
RUN pnpm --filter @cloud-computing/api build

# ==========================================
# Stage 2: Production runtime for API
# ==========================================
FROM node:24.22.1-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

RUN npm install -g --allow-scripts=pnpm pnpm@12.16.1

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/api/package.json ./apps/api/
COPY apps/web/package.json ./apps/web/

RUN pnpm install --prod --frozen-lockfile --runtime-on-fail=ignore --filter @cloud-computing/api

COPY --from=builder /app/apps/api/dist ./apps/api/dist

# Create empty web dist directory so ServeStaticModule doesn't error when imported
RUN mkdir -p /app/apps/web/dist

WORKDIR /app/apps/api

USER node

EXPOSE 3000

CMD ["node", "dist/main.js"]
