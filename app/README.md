# Geonature > app

## How to build this Dockerfile ?

Just be sure you are in this directory, and then:

```bash
GEONATURE_IMAGE_NAME="geonature:<yourversion"
docker build --force-rm -t $GEONATURE_IMAGE_NAME .
```

You have to change `<yourversion>` with a valid version number...

If you have a private Docker registry, you can also push it.
