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