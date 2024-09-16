#!/usr/bin/env bash

# Este script se basa en el repositorio de Didstopia para la administración de servidores
# https://github.com/Didstopia/docker-base-images
# 
# Modificado para el proyecto de GNR092
# Copyright (c) 2024 GNR092
# Licencia MIT - Ver archivo LICENSE para detalles.

# Habilitar manejo de errores y debugging (opcional)
set -ex

# Verificar que las variables de entorno necesarias estén definidas
: "${TZ:?Variable TZ no definida}"
: "${PGID:?Variable PGID no definida}"
: "${PUID:?Variable PUID no definida}"

# Establecer la zona horaria
ln -snf "/usr/share/zoneinfo/${TZ}" "/etc/localtime"
echo "${TZ}" > "/etc/timezone"

# Configurar el GID y UID del usuario 'docker'
if getent group "${PGID}" &> /dev/null; then
  echo "El grupo con GID ${PGID} ya existe, usándolo."
else
  groupmod --non-unique --gid "${PGID}" docker &> /dev/null
fi

if id -u docker &> /dev/null; then
  echo "El usuario 'docker' ya existe, modificando UID y GID."
  usermod --non-unique --uid "${PUID}" --gid "${PGID}" docker &> /dev/null
else
  echo "El usuario 'docker' no existe, creándolo con UID ${PUID} y GID ${PGID}."
  useradd --uid "${PUID}" --gid "${PGID}" --create-home --shell /bin/bash docker &> /dev/null
fi

# Añadir el usuario al grupo tty (corrige problemas de permisos)
usermod -aG tty docker &> /dev/null

# Crear el enlace simbólico de steamcmd si está disponible
if [ -f "/usr/games/steamcmd" ]; then
  ln -sf "/usr/games/steamcmd" "/usr/local/bin/steamcmd"
  mkdir -p /tmp/dumps
  chown -R "${PUID}:${PGID}" /tmp/dumps
fi

# Habilitar sudo sin contraseña si está configurado
if [ "${ENABLE_PASSWORDLESS_SUDO}" = "true" ]; then
  usermod -aG sudo docker &> /dev/null
  sed -i 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

  # Ajustar permisos del socket Docker si es necesario
  DOCKER_SOCKET=/var/run/docker.sock
  if [ -S "${DOCKER_SOCKET}" ]; then
    DOCKER_GID=$(stat -c '%g' "${DOCKER_SOCKET}")
    usermod -aG "${DOCKER_GID}" docker &> /dev/null
  fi
fi

# Ajustar permisos en los directorios especificados
IFS=',' read -ra DIRS <<< "${CHOWN_DIRS}"
for path in "${DIRS[@]}"; do
  echo "Ajustando permisos para ${path}"
  chown -R docker:docker "${path}"
done

# Mostrar un mensaje de bienvenida
cat << 'EOF'

╔═════════════════════════════════════════════════╗
║    _____  _     _     _              _          ║
║   |  __ \(_)   | |   | |            (_)         ║
║   | |  | |_  __| |___| |_ ___  _ __  _  __ _    ║
║   | |  | | |/ _| / __| __/ _ \| |_ \| |/ _| |   ║
║   | |__| | | (_| \__ \ || (_) | |_) | | (_| |   ║
║   |_____/|_|\__|_|___/\__\___/| |__/|_|\__|_|   ║
║                               | |               ║
║                               |_|               ║
╠═════════════════════════════════════════════════╣
║ Usted está utilizando una imagen basada en      ║
║ una imagen mantenida por Didstopia.             ║
║                                                 ║
║ Más información en:                             ║
║ https://github.com/Didstopia/docker-base-images ║
╚═════════════════════════════════════════════════╝

EOF

# Continuar con el comando especificado
exec gosu docker "$@"