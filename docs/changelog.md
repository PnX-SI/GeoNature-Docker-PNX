# CHANGELOG

## 0.1.6 (2023-10-16)

### Correction

- config TH non prise en compte (`TAXHUB_SETTINGS` passe en chemin absolu: `/dist/config/config.py`)
- ajout d'un paramètre `TAXHUB_UPLOAD_CONFIG` (=`static/media`)
## 0.1.5 (2023-10-12)

### Correction

- config UH non prise en compte

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

