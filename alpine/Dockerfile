# Imagen base de Alpine
FROM alpine:3.20

USER root

# Instala las dependencias necesarias y
# Descarga la versión más reciente de Gosu
ENV GOSU_VERSION=1.17
RUN set -eux; \
    \
    apk add --no-cache --virtual .gosu-deps\
            ca-certificates \
            dpkg \
            gnupg \
            ; \
    \
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
    \
    # Verifica la firma
    export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
    \
    # Limpiar dependencias de búsquedaqueda
	apk del --no-network .gosu-deps; \
    \
    # Haz que Gosu sea ejecutable
    chmod +x /usr/local/bin/gosu; \
    # Verifica que funciona
    gosu --version; \
	gosu nobody true

# Actualizar paquetes del sistema e instalar dependencias principales
RUN apk update && \
	apk --no-cache upgrade && \
    apk --no-cache add \
		bash \
		busybox-suid \
		shadow \
        curl \
        wget \
		ca-certificates \
        sudo && \
	update-ca-certificates 2>/dev/null || true

RUN addgroup -S -g 1000 gnr092 && \
    adduser -D -h /app -u 1000 -G gnr092 -s /bin/false gnr092 && \
    usermod -a -G gnr092,users gnr092 && \
    mkdir -p /app && \
    chown -R gnr092:gnr092 /app


# Establecer variables de entorno predeterminadas
ENV LANGUAGE=en_US.UTF-8
ENV LANG=en_US.utf8ls
ENV TERM=xterm
ENV TZ=Etc/UTC
ENV PGID=1000
ENV PUID=1000
ENV CHOWN_DIRS="/app"
ENV ENABLE_PASSWORDLESS_SUDO="false"

# Add base image initialization script
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Se establece el punto de entrada principal en nuestro script de inicialización
ENTRYPOINT ["/entrypoint.sh"]

# Establecer el comando predeterminado para ejecutar
CMD ["/bin/bash"]
