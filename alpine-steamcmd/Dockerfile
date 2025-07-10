FROM cm2network/steamcmd:latest AS builder
USER root
RUN mkdir -p /steamlib && \
    cp -r /usr/lib32/* /steamlib
RUN find . -type f -name '[A-Z]*.so' -exec rm {} +
#RUN ldd /home/steam/steamcmd/linux32/steamcmd | awk '/=>/ {print $3}' | xargs -I '{}' cp -v '{}' /steamlib

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

#COPY i386-linux-gnu/* /lib/
COPY --from=builder /steamlib/* /lib

# Actualizar paquetes del sistema e instalar dependencias principales
RUN apk update && \
	apk --no-cache upgrade && \
    apk --no-cache add \
		bash \
		busybox-suid \
		shadow \
        curl \
        wget \
        libgcc \
        libstdc++ \
		ca-certificates \
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
ENV LANG=en_US.utf8ls
ENV TERM=xterm
ENV TZ=Etc/UTC
ENV PGID=1000
ENV PUID=1000
ENV CHOWN_DIRS="/app,/steamcmd"
ENV ENABLE_PASSWORDLESS_SUDO="false"

# Instalar compatibilidad con librerías de 32 bits
RUN wget https://raw.githubusercontent.com/alpinelinux/alpine-chroot-install/v0.14.0/alpine-chroot-install \
&& echo 'ccbf65f85cdc351851f8ad025bb3e65bae4d5b06  alpine-chroot-install' | sha1sum -c \
|| exit 1


USER gnr092
WORKDIR /steamcmd
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - && \
    ./steamcmd.sh +quit
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
