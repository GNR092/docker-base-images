## docker-base-images

Repositorio con imágenes base Docker para entornos Alpine/Ubuntu, servidores SteamCMD y stacks PHP-FPM para aplicaciones web (Laravel/CodeIgniter).

## Estructura principal

- `alpine/`: imagen base Alpine con `gosu`, utilidades base y `entrypoint.sh`.
- `alpine-3.20-gosu/`: imagen mínima Alpine 3.20 enfocada en `gosu`.
- `alpine-steamcmd/`: imagen Alpine con SteamCMD y compatibilidad de librerías 32/64 bits.
- `ubuntu-steamcmd/`: variante Ubuntu con SteamCMD, Node.js/npm y toolchain adicional.
- `weblvl/`: imágenes PHP-FPM 8.3 para web (MySQL y PostgreSQL) con extensiones comunes + Redis.
- `webmb/`: imágenes PHP-FPM 8.3 para CodeIgniter con variantes MySQL, PostgreSQL y soporte GhostPDL.

## Dockerfiles relevantes

- `alpine/Dockerfile`
- `alpine-3.20-gosu/Dockerfile`
- `alpine-steamcmd/Dockerfile`
- `ubuntu-steamcmd/Dockerfile`
- `weblvl/Dockerfile`
- `weblvl/Dockerfile.pgsql`
- `webmb/Dockerfile`
- `webmb/Dockerfile.gspt`
- `webmb/Dockerfile.postgresql`

## Variantes webmb

- `webmb/Dockerfile`: base MySQL/MariaDB.
- `webmb/Dockerfile.gspt`: MySQL/MariaDB + GhostPDL/Ghostscript (`GSPDL_VERSION`, build sin X/GTK).
- `webmb/Dockerfile.postgresql`: PostgreSQL + GhostPDL/Ghostscript.

## Scripts de build (webmb)

- `webmb/scripts/build-webmbgs.sh`: build de `Dockerfile.gspt`.
- `webmb/scripts/build-and-push-webmbgs.sh`: build + push de variante GhostPDL.
- `webmb/scripts/build-webmb-postgresql.sh`: build de `Dockerfile.postgresql`.

### Variables soportadas por scripts

- `IMAGE_NAME`
- `IMAGE_TAG`
- `GSPDL_VERSION`
- `DOCKERFILE`
- `CONTEXT_DIR`

### Uso rápido

```bash
cd webmb
./scripts/build-webmbgs.sh
./scripts/build-webmb-postgresql.sh
```

### Builds manuales (sin script)

```bash
docker build -f webmb/Dockerfile -t gnr092/webmb:latest webmb
docker build -f webmb/Dockerfile.gspt -t gnr092/webmbgs:latest webmb
docker build -f webmb/Dockerfile.postgresql -t gnr092/webmb-postgresql:latest webmb
```

## Créditos y Licencia

Este proyecto utiliza código basado en el repositorio de Didstopia para la administración de servidores:

- **Repositorio original**: [Didstopia/docker-base-images](https://github.com/Didstopia/docker-base-images)
- **Licencia del código original**: MIT

### Licencia del Proyecto

Este proyecto está licenciado bajo la Licencia MIT. Consulta el archivo [`LICENSE`](https://github.com/GNR092/docker-base-images/blob/main/LICENCE.md) para más detalles.

### Atribución

El código del script se basa en el repositorio de Didstopia y ha sido modificado para adaptarse a las necesidades del proyecto actual.

Copyright (c) 2024 GNR092
