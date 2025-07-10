#!/usr/bin/env sh
# Habilitar el manejo de errores
set -e

# Prepara nuestra ruta lib a LD_Library_Path
#export LD_LIBRARY_PATH="/steamcmd/linux32:$LD_LIBRARY_PATH"

# Establezca la zona horaria actual
echo "Estableciendo zona horaria => ${TZ}"
ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
echo "${TZ}" > /etc/timezone

# Establecer los identificadores de grupo y usuario
echo "Configuración de ID de grupo y usuario"
groupmod -g "${PGID}" gnr092 &> /dev/null || addgroup -g "${PGID}" gnr092
usermod -u "${PUID}" gnr092 &> /dev/null || adduser -u "${PUID}" -G gnr092 gnr092

# Agregue el usuario al grupo tty (soluciona problemas de permisos con /dev/std*, etc.)
usermod -a -G tty gnr092 &> /dev/null

# Cree un enlace simbólico de steamcmd si está disponible
if [ -f "/usr/games/steamcmd" ]; then
  ln -sf "/usr/games/steamcmd" "/usr/local/bin/steamcmd"

  # Crear y/o arreglar permisos para un directorio temporal steacmd
  mkdir -p /tmp/dumps
  chown -R "${PUID}":"${PGID}" /tmp/dumps
fi

if [ "${ENABLE_PASSWORDLESS_SUDO}" = "true" ]; then
  # Agregar el usuario al grupo sudo
  if ! groups gnr092 | grep -q "\bsudo\b"; then
    usermod -a -G sudo gnr092 &> /dev/null
  fi

  # Permitir que los usuarios del grupo sudo ejecuten sudo sin especificar una contraseña
  echo "%sudo ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

  # Manejar los permisos del socket Docker si es necesario
  DOCKER_SOCKET=/var/run/docker.sock
  if [ -S "${DOCKER_SOCKET}" ]; then
    DOCKER_GID=$(stat -c '%g' "${DOCKER_SOCKET}")
    if ! groups gnr092 | grep -q "\b${DOCKER_GID}\b"; then
      addgroup -g "${DOCKER_GID}" dockersocket
      addgroup gnr092 dockersocket
    fi
  fi
fi

# Establecer los permisos correctos
echo "Configuración de permisos para directorios: ${CHOWN_DIRS}"
for path in ${CHOWN_DIRS//,/ }
do
  chown -R gnr092:gnr092 "${path}"
done

echo "

╔═══════════════════════════════════════════╗
║      ____ _   _ ____   ___   ___ ____     ║
║     / ___| \ | |  _ \ / _ \ / _ \___ \    ║
║    | |  _|  \| | |_) | | | | (_) |__) |   ║
║    | |_| | |\  |  _ <| |_| |\__, / __/    ║
║     \____|_| \_|_| \_\\\___/   /_/_____|   ║
║                                           ║
╠═══════════════════════════════════════════╣
║         Imagen Base de GNR092             ║
║         "$(awk -F= '/^PRETTY_NAME=/ {print $2}' /etc/os-release)"              ║
╚═══════════════════════════════════════════╝
"

exec gosu gnr092 "$@"
