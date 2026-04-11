# Chat2API Docker 部署说明

通过 Docker 运行 Chat2API，使用浏览器即可访问图形界面，无需安装任何客户端。

## 快速开始

```bash
docker run -d \
  --name chat2api \
  -p 5800:5800 \
  -p 8080:8080 \
  -v chat2api-data:/root/.chat2api \
  yilee01/chat2api:latest
```

浏览器打开 `http://localhost:5800` 即可看到 Chat2API 界面。

---

## 端口说明

| 端口 | 说明 |
|------|------|
| `5800` | 网页 VNC 界面，浏览器直接访问 |
| `5900` | 原始 VNC 协议端口，供 VNC 客户端连接（可选） |
| `8080` | Chat2API 对外提供的 OpenAI 兼容 API |

---

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `VNC_PASSWORD` | 无 | VNC 访问密码，不设置则无需密码 |
| `DISPLAY_WIDTH` | `1440` | 界面宽度（像素） |
| `DISPLAY_HEIGHT` | `900` | 界面高度（像素） |

---

## 数据持久化

应用配置存储在容器内 `/root/.chat2api` 目录，包括：

- `config.json` — 应用配置
- `providers.json` — 服务商设置
- `accounts.json` — 账号凭据（已加密）
- `logs/` — 请求日志

建议挂载该目录以保留配置：

```bash
# 使用 Docker 卷（推荐）
-v chat2api-data:/root/.chat2api

# 或挂载到本机目录
-v /your/local/path:/root/.chat2api
```

---

## 常用启动示例

**本机开发（无密码）**

```bash
docker run -d \
  --name chat2api \
  -p 5800:5800 \
  -p 8080:8080 \
  -v chat2api-data:/root/.chat2api \
  yilee01/chat2api:latest
```

**服务器部署（设置密码）**

```bash
docker run -d \
  --name chat2api \
  -p 5800:5800 \
  -p 8080:8080 \
  -e VNC_PASSWORD=yourpassword \
  -v chat2api-data:/root/.chat2api \
  --restart unless-stopped \
  yilee01/chat2api:latest
```

**使用 Docker Compose**

```yaml
services:
  chat2api:
    image: yilee01/chat2api:latest
    container_name: chat2api
    ports:
      - "5800:5800"
      - "8080:8080"
    environment:
      - VNC_PASSWORD=yourpassword   # 可选
    volumes:
      - chat2api-data:/root/.chat2api
    restart: unless-stopped

volumes:
  chat2api-data:
```

---

## API 使用

Chat2API 启动并配置好服务商后，可通过标准 OpenAI 格式调用：

```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "model": "deepseek-v3",
    "messages": [{"role": "user", "content": "你好"}]
  }'
```

API Key 在 Chat2API 界面的 **API Keys** 页面生成和管理。

---

## 常用命令

```bash
# 查看运行日志
docker logs -f chat2api

# 进入容器 shell
docker exec -it chat2api sh

# 停止容器
docker stop chat2api

# 删除容器（数据卷保留）
docker rm chat2api

# 更新镜像
docker pull yilee01/chat2api:latest
docker stop chat2api && docker rm chat2api
# 重新执行启动命令
```
