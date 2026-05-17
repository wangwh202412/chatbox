# syntax=docker/dockerfile:1

FROM node:22-alpine AS builder

WORKDIR /app

RUN apk add --no-cache bash git python3 make g++
RUN corepack enable

COPY . .

RUN pnpm install --frozen-lockfile || pnpm install
RUN pnpm run build:web

FROM nginx:alpine

RUN printf 'server {\
    listen 8070;\
    server_name _;\
    root /usr/share/nginx/html;\
    index index.html;\
    location / {\
        try_files $uri $uri/ /index.html;\
    }\
}' > /etc/nginx/conf.d/default.conf

COPY --from=builder /app/release/app/dist/renderer /usr/share/nginx/html

EXPOSE 8070

CMD ["nginx", "-g", "daemon off;"]
