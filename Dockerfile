# Stage 1: Base - Common foundation for all stages
FROM node:20-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

# Install essential utilities
RUN apk add --no-cache bash git

WORKDIR /app
RUN chown -R node:node /app

# Stage 2: Dependencies - Install all dependencies (dev + prod)
FROM base AS dependencies
COPY --chown=node:node package.json pnpm-lock.yaml ./
USER node
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile

# Stage 3: Development - Full development environment with hot-reload
FROM dependencies AS development
COPY --chown=node:node . .
USER node
EXPOSE 3000
CMD ["pnpm", "run", "start:dev"]

# Stage 4: Build - Compile TypeScript to JavaScript
FROM dependencies AS build
COPY . .
RUN pnpm run build

# Stage 5: Production Dependencies - Install only production dependencies
FROM base AS prod-dependencies
COPY package.json pnpm-lock.yaml ./
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --prod --frozen-lockfile

# Stage 6: Production - Minimal production image
FROM node:20-alpine AS production
ENV NODE_ENV=production
WORKDIR /app
COPY --from=prod-dependencies /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY package.json ./
EXPOSE 3000
CMD ["node", "dist/main.js"]
