# ---------- 阶段 1：构建 Web 前端 ----------
FROM node:20-slim AS builder

WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y python3 make g++ bash git && rm -rf /var/lib/apt/lists/*

# 拷贝项目文件
COPY . .

# 删除 electron / capacitor 等依赖（Web 不需要）
RUN npm pkg delete devDependencies.electron \
    && npm pkg delete devDependencies['@capacitor/android'] \
    && npm pkg delete devDependencies['@capacitor/ios']

# 禁用 postinstall，防止 electron-builder 执行
RUN npm pkg delete scripts.postinstall

# 禁用删除 sourcemaps 的步骤（因为该脚本缺失）
RUN npm pkg delete scripts.delete-sourcemaps

# 安装依赖（忽略可选）
RUN npm install --omit=optional --legacy-peer-deps

# 构建 Web 版本
RUN npm run build:renderer

# ---------- 阶段 2：部署到 Nginx ----------
FROM nginx:stable-alpine

# 覆盖默认配置文件，让 Nginx 监听 8070
RUN sed -i 's/listen\s\+80;/listen 8070;/' /etc/nginx/conf.d/default.conf

# 拷贝构建产物到 Nginx
COPY --from=builder /app/release/app/dist/renderer /usr/share/nginx/html

# 暴露端口
EXPOSE 8070

# 启动 Nginx
CMD ["nginx", "-g", "daemon off;"]
