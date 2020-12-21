# Automatique Nginx reverse proxy

Based on Jason Wilder's work on Nginx proxy running with docker-gen [Nginx-proxy](https://hub.docker.com/r/jwilder/nginx-proxy).

## Installation

On a Docker server (only standalone, this won't support Swarm or Kubernetes):

```shell
cp nginx-proxy/nginx-proxy.service /etc/systemd/system
systemctl daemon-reload
systemctl enable nginx-proxy --now
```

## Usage

On a Docker service you want to reverse proxy automatically, add an environment variable "`VIRTUAL_HOST`" and add it to the rpx_net network

```yaml
# disclaimer, a lot have been trimmed down from a normal docker-compose.yml file in this example.
# [...]
services:
# [...]
  web:
    image: nexus.brgm.fr:18444/bgrm/mywebimage:my-meaningfull-tag
    environment:
      - "VIRTUAL_HOST=mywebapplication.brgm.fr"
    # [...]
    networks:
      - rpx_net
    # [...]

networks:
  rpx_net:
    external: true
    name: rpx_net
# [...]
```

If the container only exposes one TCP port (or uses standard http/https ports) it will be automatically configured. If the container expose multiple "outlandish" ports, please specify the one that should be used as per the documentation: [Nginx-proxy](https://github.com/nginx-proxy/nginx-proxy).
