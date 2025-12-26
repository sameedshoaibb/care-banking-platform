# I have used node:20.19.6-alpine because it is small and secure and also have the corepack pre-installed, which is required to run the application
FROM node:20.19.6-alpine AS build
WORKDIR /app

# Enable corepack which is package manager and install a fixed pnpm version
RUN corepack enable && corepack install -g pnpm@9.14.4 

# Copy dependency files first and then install dependencies
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --dev

# Copy source files, build and prune to remove dev dependencies
COPY src ./src
COPY tsconfig.json ./
RUN pnpm build && pnpm prune --prod


# Production stage
FROM node:20.19.6-alpine
WORKDIR /app
ENV NODE_ENV=production

# Create non-root user
RUN addgroup -S appuser && adduser -S appuser -G appuser

# Copy Build Artifacts
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./
COPY config.json ./
COPY start.sh ./

# Give ownership to user and make start.sh executable
RUN chown -R appuser:appuser /app && chmod +x start.sh
USER appuser
EXPOSE 4000
HEALTHCHECK CMD wget -q --spider http://localhost:4000/health || exit 1
CMD ["./start.sh"]