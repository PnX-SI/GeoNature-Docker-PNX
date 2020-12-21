# Geonature > db

## How to build this Dockerfile ?

Just be sure you are in this directory, and then:

```bash
docker build --force-rm -t kartoza/postgis::11.0-2.5 .
```

If you have a private Docker registry, you can also push it.

## Why don't we use the image from dockerhub?

The image from DockerHub is not stable, and the creator (kartoza) just reuse the tags from time to time (so with the same image name/tags, we have different behaviour). To avoir that, we (in BRGM) have just froozen a version at a moment of a time and saved it to our internal registry.

## Why don't we create a clean/fresh image?

Well... just by lack of time... But it's in the pipe.
