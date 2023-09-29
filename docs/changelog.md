# CHANGELOG

## 0.1.4 (2023-09-29)

### Correction

- correction redirection racine -> frontend

## 0.1.3 (2023-09-29)

### Evolutions

- Fichiers `médias` de geonature servis directement par le service `geonature-frontend` (`nginx`)
  - permet d'éviter les timeout sur le chargement d'exports volumineux

### Versions

```
GEONATURE_FRONTEND_IMAGE=ghcr.io/pnx-si/geonature-frontend-extra:2.13.2
GEONATURE_BACKEND_IMAGE=ghcr.io/pnx-si/geonature-backend-extra:2.13.2
USERSHUB_IMAGE=ghcr.io/pnx-si/usershub:2.3.4
TAXHUB_IMAGE=ghcr.io/pnx-si/taxhub:1.12.1
ATLAS_IMAGE=ghcr.io/pnx-si/geonature-atlas:1.60
```

