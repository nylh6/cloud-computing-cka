# ==========================================
# Stage 1: Build the React Frontend application
# ==========================================
FROM node:24.22.1-alpine AS builder

WORKDIR /app

RUN npm install -g --allow-scripts=pnpm pnpm@12.16.1

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/api/package.json ./apps/api/
COPY apps/web/package.json ./apps/web/

RUN pnpm install --frozen-lockfile --runtime-on-fail=ignore

COPY apps/web/ ./apps/web/

# Build frontend production bundle
RUN pnpm --filter @cloud-computing/web build

# ==========================================
# Stage 2: Serve with Nginx
# ==========================================
FROM nginx:1.27-alpine AS runner

# Copy built frontend assets
COPY --from=builder /app/apps/web/dist /usr/share/nginx/html

# Copy custom Nginx configuration with reverse proxy for /api
COPY apps/web/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
