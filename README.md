## Imágenes disponibles

- `webmb/Dockerfile`: Imagen base para CodeIgniter con MariaDB/MySQL.
- `webmb/Dockerfile.gspt`: Variante con soporte GhostPDL/Ghostscript para generación de PDF.
- `webmb/Dockerfile.postgresql`: Variante PostgreSQL con soporte GhostPDL/Ghostscript.

## Scripts de build (webmb)

- `webmb/scripts/build-webmbgs.sh`: Build de imagen GhostPDL (`Dockerfile.gspt`).
- `webmb/scripts/build-and-push-webmbgs.sh`: Build + push de imagen GhostPDL.
- `webmb/scripts/build-webmb-postgresql.sh`: Build de imagen PostgreSQL con GhostPDL (`Dockerfile.postgresql`).

### Uso rápido

```bash
cd webmb
./scripts/build-webmbgs.sh
./scripts/build-webmb-postgresql.sh
```

Se pueden sobreescribir variables en ambos scripts:

- `IMAGE_NAME`
- `IMAGE_TAG`
- `GSPDL_VERSION`
- `DOCKERFILE`
- `CONTEXT_DIR`

## Créditos y Licencia

Este proyecto utiliza código basado en el repositorio de Didstopia para la administración de servidores:

- **Repositorio original**: [Didstopia/docker-base-images](https://github.com/Didstopia/docker-base-images)
- **Licencia del código original**: MIT

### Licencia del Proyecto

Este proyecto está licenciado bajo la Licencia MIT. Consulta el archivo [`LICENSE`](https://github.com/GNR092/docker-base-images/blob/main/LICENCE.md) para más detalles.

### Atribución

El código del script se basa en el repositorio de Didstopia y ha sido modificado para adaptarse a las necesidades del proyecto actual.

Copyright (c) 2024 GNR092
