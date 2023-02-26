#!/usr/bin/env bash

set -e

# omada controller dependency and package installer script for versions 4.x and 5.x

# set default variables

OMADA_DIR="/opt/tplink/EAPController"
ARCH="${ARCH:-}"
OMADA_VER="${OMADA_VER:-}"
OMADA_TAR="${OMADA_TAR:-}"
OMADA_URL="${OMADA_URL:-}"
OMADA_MAJOR_VER="$(echo "${OMADA_VER}" | awk -F '.' '{print $1}')"
OMADA_MAJOR_MINOR_VER="${OMADA_VER%.*}"

# function to exit on error w/message
die() { echo -e "$@" 2>&1; exit 1; }

echo "**** Selecting packages based on the architecture and version ****"
# common package dependencies
PKGS=(
  gosu
  net-tools
  openjdk-8-jre-headless
  tzdata
  wget
)

# add specific package for mongodb
case "${ARCH}" in
amd64|arm64|"")
  PKGS+=( mongodb-server-core )
  ;;
armv7l)
  PKGS+=( mongodb )
  ;;
*)
  die "${ARCH}: unsupported ARCH"
  ;;
esac

echo "ARCH=${ARCH}"
echo "OMADA_VER=${OMADA_VER}"
echo "OMADA_TAR=${OMADA_TAR}"
echo "OMADA_URL=${OMADA_URL}"
echo "PKGS=( ${PKGS[*]} )"

echo "**** Install Dependencies ****"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install --no-install-recommends -y "${PKGS[@]}"

echo "**** Download Omada Controller ****"
cd /tmp
wget -nv "${OMADA_URL}"

echo "**** Extract and Install Omada Controller ****"

# in the 4.4.3, 4.4.6, and 4.4.8 builds, they removed the directory. this case statement will handle variations in the build
case "${OMADA_VER}" in
  4.4.3|4.4.6|4.4.8)
    echo "version ${OMADA_VER}"
    mkdir "Omada_SDN_Controller_${OMADA_VER}"
    cd "Omada_SDN_Controller_${OMADA_VER}"
    tar zxvf "../${OMADA_TAR}"
    rm -f "../${OMADA_TAR}"
    ;;
  *)
    echo "not version 4.4.3/4.4.6/4.4.8"
    tar zxvf "${OMADA_TAR}"
    rm -f "${OMADA_TAR}"
    cd Omada_SDN_Controller_*
    ;;
esac

# make sure tha the install directory exists
mkdir "${OMADA_DIR}" -vp

# starting with 5.0.x, the installation has no webapps directory; these values are pulled from the install.sh
case "${OMADA_MAJOR_VER}" in
  5)
    NAMES=( bin properties lib install.sh uninstall.sh )
    ;;
  *)
    NAMES=( bin properties keystore lib webapps install.sh uninstall.sh )
    ;;
esac

# copy over the files to the destination
for NAME in "${NAMES[@]}"
do
  cp "${NAME}" "${OMADA_DIR}" -r
done

# symlink to home assistant data dir
ln -s /data "${OMADA_DIR}"

# symlink for mongod
ln -sf "$(which mongod)" "${OMADA_DIR}/bin/mongod"
chmod 755 "${OMADA_DIR}"/bin/*

echo "**** Setup omada User Account ****"
groupadd -g 508 omada
useradd -u 508 -g 508 -d "${OMADA_DIR}" omada
mkdir "${OMADA_DIR}/logs" "${OMADA_DIR}/work"
chown -R omada:omada "${OMADA_DIR}/data" "${OMADA_DIR}/logs" "${OMADA_DIR}/work"

# for v5.1 & above, create backup of data/html directory in case it is missing (to be extracted at runtime)
if [ -d /opt/tplink/EAPController/data/html ]
then
  # create backup
  cd /opt/tplink/EAPController/data
  tar zcvf ../data-html.tar.gz html
fi

echo "**** Cleanup ****"
rm -rf /tmp/* /var/lib/apt/lists/*
