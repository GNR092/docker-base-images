FROM cm2network/steamcmd@sha256:45f6515d6c4dcde659c9ad6872bdbeacd1bf5c4e7f241829c4d2f28fb5eda581 AS builder
USER root
RUN mkdir -p /steamlib && \
    cp -r /usr/lib32/* /steamlib
RUN find /steamlib -type f -name '[A-Z]*.so' -delete
#RUN ldd /home/steam/steamcmd/linux32/steamcmd | awk '/=>/ {print $3}' | xargs -I '{}' cp -v '{}' /steamlib

# Imagen base de Alpine
FROM alpine:3.22

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

#COPY i386-linux-gnu/* /lib/
COPY --from=builder /steamlib/* /lib

# Actualizar paquetes del sistema e instalar dependencias principales
RUN apk update && \
    apk --no-cache add \
		bash \
		busybox-suid \
		shadow \
        curl \
        wget \
        libgcc \
        libstdc++ \
		ca-certificates \
        musl-locales \
        sudo && \
	update-ca-certificates 2>/dev/null || true && \
    rm -rf /var/lib/apt/lists/*

RUN addgroup -S -g 1000 gnr092 && \
    adduser -D -h /app -u 1000 -G gnr092 -s /bin/false gnr092 && \
    usermod -a -G gnr092,users gnr092 && \
    mkdir -p /app /steamcmd && \
    chown -R gnr092:gnr092 /app /steamcmd

# Establecer variables de entorno predeterminadas
ENV LANGUAGE=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV TERM=xterm
ENV TZ=Etc/UTC
ENV PGID=1000
ENV PUID=1000
ENV CHOWN_DIRS="/app,/steamcmd"
ENV ENABLE_PASSWORDLESS_SUDO="false"

USER gnr092
WORKDIR /steamcmd
ARG STEAMCMD_SHA256=cebf0046bfd08cf45da6bc094ae47aa39ebf4155e5ede41373b579b8f1071e7c
RUN curl -fsSL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" -o /tmp/steamcmd.tar.gz \
    && echo "${STEAMCMD_SHA256}  /tmp/steamcmd.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/steamcmd.tar.gz \
    && rm -f /tmp/steamcmd.tar.gz \
    && ./steamcmd.sh +quit
USER root
RUN ln -s "/steamcmd/linux64/steamclient.so" "/usr/lib/steamclient.so"   
WORKDIR /

# Agregar script de inicialización de imagen base
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Se establece el punto de entrada principal en nuestro script de inicialización
ENTRYPOINT ["/entrypoint.sh"]

# Establecer el comando predeterminado para ejecutar
CMD ["/bin/bash"]
