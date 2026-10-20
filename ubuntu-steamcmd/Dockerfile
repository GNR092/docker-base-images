FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ENV GOSU_VERSION=1.17
ARG NODE_VERSION=20

# Configura locales
RUN apt-get update \
    && apt-get install -y locales \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8

# Instala dependencias básicas y gosu
RUN set -x \
    && apt-get install -y --no-install-recommends curl ca-certificates wget gnupg \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver keyserver.ubuntu.com --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true \
    && apt-get purge -y --auto-remove gnupg \
    && apt-get clean

# Instala Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && node -v

# Instala npm
RUN curl -fsSL https://www.npmjs.com/install.sh | sh \
    && npm -v

# Instala dependencias adicionales
RUN apt-get install -y --no-install-recommends \
    python3-dev \
    jq \
    build-essential \
    && apt-get clean


# Actualiza npm
RUN npm install npm@10 -g

# Instala SteamCMD y librerías necesarias
RUN apt-get update \
    && dpkg --add-architecture i386 \
    && apt-get install -y software-properties-common \
    && add-apt-repository multiverse \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        lib32gcc-s1 \
        libstdc++6 \
        libsdl2-2.0-0:i386 \
        libcurl4-openssl-dev:i386 \
        libgdiplus \
        libc6-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/dumps /tmp/*

# se crea un usuario y un grupo predeterminado (Docker)
# (también establece permisos para el volumen /app)
RUN groupadd \
	--system \
	docker && \
	useradd \
	--create-home \
	--home /app \
	--uid 1001 \
	--gid docker \
	--groups docker,users,staff \
	--shell /bin/false \
	docker && \
	mkdir -p /app && \
	chown -R docker:docker /app

# se crea los directorios necesarios
RUN mkdir -p /steamcmd/ /app/.steam/sdk32 /app/.steam/sdk64 \
	&& chown -R docker:docker /steamcmd/ /app/.steam/sdk32 /app/.steam/sdk64

USER docker

# Instala SteamCMD y verifica su funcionamiento
ARG STEAMCMD_SHA256=c7e382f81d5a44036ebb21fd6aa77f68fb4ac0b6d6f4c209ef389b05eba0f9b8
RUN curl -fsSL https://media.steampowered.com/installer/steamcmd_linux.tar.gz -o /tmp/steamcmd.tar.gz \
    && echo "${STEAMCMD_SHA256}  /tmp/steamcmd.tar.gz" | sha256sum -c - \
    && tar -v -C /steamcmd -xzf /tmp/steamcmd.tar.gz \
    && rm /tmp/steamcmd.tar.gz \
    && chmod +x /steamcmd/steamcmd.sh \
    && set -x && /steamcmd/steamcmd.sh +login anonymous +quit \
    && ln -sf "/steamcmd/linux32/steamclient.so" "/steamcmd/steamservice.so" \
	&& ln -sf "/steamcmd/linux32/steamclient.so" "/app/.steam/sdk32/steamclient.so" \
    && ln -sf "/steamcmd/linux32/steamcmd" "/steamcmd/linux32/steam" \
  	&& ln -sf "/steamcmd/linux64/steamclient.so" "/app/.steam/sdk64/steamclient.so" \
    && ln -sf "/steamcmd/linux64/steamcmd" "/steamcmd/linux64/steam" 


USER root
# Symlink steamclient.so; So misconfigured dedicated servers can find it
RUN ln -sf "/steamcmd/linux64/steamclient.so" "/usr/lib/x86_64-linux-gnu/steamclient.so"
# Establecer variables de entorno predeterminadas
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV TERM=xterm
ENV TZ=Etc/UTC
ENV PGID=999
ENV PUID=1001
ENV CHOWN_DIRS="/app,/steamcmd"
ENV ENABLE_PASSWORDLESS_SUDO="false"

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
# Define el comando por defecto
CMD ["/bin/bash"]
