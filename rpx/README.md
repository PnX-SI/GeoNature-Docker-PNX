# Geonature > rpx

## How to build this Dockerfile ?

Just be sure you are in this directory, and then:

```bash
docker build --force-rm -t nginx:1.17-alpine .
```

If you have a private Docker registry, you can also push it.

## Why don't we use the image from dockerhub?

We use internally a CI/CD mechanism to push the created image to our internal registry, and this Dockerfile is just here for that.
