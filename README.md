# docker-base-images

Imágenes base Docker para entornos Alpine/Ubuntu, servidores SteamCMD y stacks PHP-FPM para aplicaciones web (Laravel/CodeIgniter 4).

---

## Estructura

```
├── alpine/                  # Alpine 3.20 + gosu + utilidades
├── alpine-3.20-gosu/        # Alpine 3.20 + gosu (mínima)
├── alpine-steamcmd/         # Alpine 3.20 + SteamCMD (multi-stage)
├── ubuntu-steamcmd/         # Ubuntu 24.10 + Node 20 + SteamCMD
├── weblvl/                  # PHP 8.3-FPM para Laravel (MySQL/PostgreSQL)
└── webmb/                   # PHP 8.3-FPM para CI4 (MySQL/PostgreSQL + GhostPDL)
```

---

## Imágenes

### alpine

Imagen base Alpine con gosu para ejecución no-root dinámica.

| Atributo | Valor |
|----------|-------|
| Base | `alpine:3.20` |
| Usuario | `gnr092` (UID/GID 1000) |
| Entrypoint | `entrypoint.sh` con `PUID`, `PGID`, `CHOWN_DIRS`, `ENABLE_PASSWORDLESS_SUDO` |
| Scripts | `build.sh`, `run.sh`, `push.sh` |

```bash
docker build -t __NAMESPACE__/base:alpine alpine/
```

### alpine-3.20-gosu

Imagen mínima con solo gosu, sin usuario personalizado ni entrypoint.

| Atributo | Valor |
|----------|-------|
| Base | `alpine:3.20` |
| Gosu | 1.17 |
| Uso | Base para imágenes que necesitan gosu pero no utilidades extras |

```bash
docker build -t __NAMESPACE__/base:alpine-gosu alpine-3.20-gosu/
```

### alpine-steamcmd

Alpine con SteamCMD listo para servidores de juego.

| Atributo | Valor |
|----------|-------|
| Base | `alpine:3.20` (multi-stage desde `cm2network/steamcmd`) |
| Usuario | `gnr092` (UID/GID 1000) |
| SteamCMD | Instalado y verificado + `steamclient.so` en `/usr/lib` |
| Entrypoint | Mismo que `alpine/` (`PUID`, `PGID`, `CHOWN_DIRS`) |

```bash
docker build -t __NAMESPACE__/steamcmd:alpine alpine-steamcmd/
```

### ubuntu-steamcmd

Ubuntu con SteamCMD, Node.js 20 y toolchain de desarrollo.

| Atributo | Valor |
|----------|-------|
| Base | `ubuntu:24.10` |
| Usuario | `docker` (UID 1001 / GID 999) |
| Node.js | 20 LTS + npm |
| SteamCMD | Instalado + symlinks para SDK32/SDK64 |
| Entrypoint | Mismo patrón (`PUID`, `PGID`, `CHOWN_DIRS`) |

```bash
docker build -t __NAMESPACE__/steamcmd:ubuntu ubuntu-steamcmd/
```

### weblvl

PHP-FPM para aplicaciones Laravel, con extensiones comunes y Redis.

| Atributo | Valor |
|----------|-------|
| Base | `php:8.3.8-fpm-alpine3.20` (multi-stage con Composer) |
| Extensiones | `pdo_mysql`, `mbstring`, `exif`, `pcntl`, `bcmath`, `gd`, `zip`, `intl`, `gmp`, `posix`, `opcache`, `redis` |
| Entrypoint | `entrypoint.sh` con `PUID`/`PGID`, Composer, caches de Laravel |
| Puertos | 9000 |

**Variantes:**
| Dockerfile | Base de datos |
|------------|---------------|
| `Dockerfile` | MySQL (`pdo_mysql`) |
| `Dockerfile.pgsql` | PostgreSQL (`pdo_pgsql`, `pgsql`) |

**Configuraciones incluidas:**
- `nginx.conf.example` — Template Nginx con placeholders (`__DOMAIN__`, `__ROOT__`, `__PHP_SERVICE__`)
- `zz-custom.conf` — Pool PHP-FPM con carga tardía (prefijo `zz-`)
- `opcache-custom.ini` — OPcache con JIT para PHP 8.1+

Ver `weblvl/README.md` para detalles de uso.

```bash
docker build -f weblvl/Dockerfile -t __NAMESPACE__/weblvl:latest weblvl/
docker build -f weblvl/Dockerfile.pgsql -t __NAMESPACE__/weblvl-pgsql:latest weblvl/
```

### webmb

PHP-FPM para CodeIgniter 4, con extensiones MySQL/PostgreSQL y GhostPDL.

| Atributo | Valor |
|----------|-------|
| Base | `php:8.3.8-fpm-alpine3.20` |
| Extensiones | `mysqli`, `pdo_mysql`, `mbstring`, `exif`, `pcntl`, `gd`, `opcache`, `zip`, `bcmath`, `intl`, `soap` |
| Usuario | `nobody` (UID/GID configurable vía `PUID`/`PGID`) |
| Puertos | 9000 |

**Variantes:**
| Dockerfile | DB | GhostPDL |
|------------|----|----------|
| `Dockerfile` | MySQL | No |
| `Dockerfile.gspt` | MySQL | Sí (`gs --version`) |
| `Dockerfile.postgresql` | PostgreSQL | Sí (`gs --version`) |

**Scripts de build:**
| Script | Acción |
|--------|--------|
| `scripts/build-webmbgs.sh` | Build `Dockerfile.gspt` |
| `scripts/build-and-push-webmbgs.sh` | Build + push de GhostPDL |
| `scripts/build-webmb-postgresql.sh` | Build `Dockerfile.postgresql` |

**Variables de entorno para scripts:**
| Variable | Default |
|----------|---------|
| `IMAGE_NAME` | `gnr092/webmbgs` |
| `IMAGE_TAG` | `latest` |
| `GSPDL_VERSION` | `10.07.0` |
| `DOCKERFILE` | `Dockerfile.gspt` |
| `CONTEXT_DIR` | `.` |

**Configuraciones incluidas:**
- `nginx.conf.example` — Template Nginx con CSP para CI4
- `zz-custom.conf` — Pool PHP-FPM optimizado para CI4
- `opcache-custom.ini` — OPcache con JIT

Ver `webmb/README.md` para detalles.

```bash
cd webmb
./scripts/build-webmbgs.sh
./scripts/build-webmb-postgresql.sh
```

Build manual:
```bash
docker build -f webmb/Dockerfile -t __NAMESPACE__/webmb:latest webmb/
docker build -f webmb/Dockerfile.gspt -t __NAMESPACE__/webmbgs:latest webmb/
docker build -f webmb/Dockerfile.postgresql -t __NAMESPACE__/webmb-postgresql:latest webmb/
```

---

## Repositorio

| Atributo | Valor |
|----------|-------|
| Rama activa | `main` |
| Remoto | `git@github.com:__NAMESPACE__/docker-base-images.git` |
| Tags | Ninguno |

---

## Atribución

Basado en [Didstopia/docker-base-images](https://github.com/Didstopia/docker-base-images) (MIT).

---

## Licencia

MIT. Ver [`LICENCE.md`](LICENCE.md).
