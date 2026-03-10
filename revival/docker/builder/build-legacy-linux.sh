#!/usr/bin/env bash
set -euo pipefail

SRC_ROOT="${WORKSPACE_ROOT:-/workspace}"
BUILD_ROOT="/tmp/dswork"
MAKE_JOBS="${MAKE_JOBS:-$(nproc)}"
BUILD_SCOPE="${BUILD_SCOPE:-full}"
CCACHE_DIR="${CCACHE_DIR:-/ccache}"
CXX_BASE_FLAGS="${CXX_BASE_FLAGS:--fpermissive -DMEDUSA_DISABLE_LUA_JIT_MODULE -w -I/usr/include/mariadb}"

mkdir -p "${CCACHE_DIR}"
export CCACHE_DIR
export CCACHE_BASEDIR="${SRC_ROOT}"
export CCACHE_MAXSIZE="${CCACHE_MAXSIZE:-10G}"

rm -rf "${BUILD_ROOT}"
mkdir -p "${BUILD_ROOT}"
cp -a "${SRC_ROOT}/." "${BUILD_ROOT}/"

cd "${BUILD_ROOT}"

ln -sfn medusa Medusa
ln -sfn gamecq GameCQ
ln -sfn darkspace DarkSpace
ln -sfn Gcqs gamecq/GCQS

mkdir -p /home/builder/work/Trunk
ln -sfn "${BUILD_ROOT}/medusa" /home/builder/work/Trunk/Medusa
ln -sfn "${BUILD_ROOT}/gamecq" /home/builder/work/Trunk/GameCQ
ln -sfn "${BUILD_ROOT}/darkspace" /home/builder/work/Trunk/DarkSpace

reset_release_outputs() {
  local paths=(
    "${BUILD_ROOT}/medusa/Bin"
    "${BUILD_ROOT}/gamecq/Bin"
    "${BUILD_ROOT}/darkspace/Bin"
    "/home/builder/work/Trunk/Medusa/Bin"
    "/home/builder/work/Trunk/Medusa/ReleaseLinux/obj"
    "${BUILD_ROOT}/medusa/Network/ReleaseLinux/obj"
    "${BUILD_ROOT}/medusa/GCQ/ReleaseLinux/obj"
    "${BUILD_ROOT}/medusa/Render3D/ReleaseLinux/obj"
    "${BUILD_ROOT}/medusa/World/ReleaseLinux/obj"
    "${BUILD_ROOT}/gamecq/GCQDB/ReleaseLinux/obj"
    "${BUILD_ROOT}/gamecq/Gcqs/ReleaseLinux/obj"
    "${BUILD_ROOT}/gamecq/MetaServer/ReleaseLinux/obj"
    "${BUILD_ROOT}/gamecq/ProcessServer/ReleaseLinux/obj"
    "${BUILD_ROOT}/gamecq/MirrorServer/ReleaseLinux/obj"
    "${BUILD_ROOT}/darkspace/DarkSpace/ReleaseLinux/obj"
    "${BUILD_ROOT}/darkspace/DarkSpaceServer/ReleaseLinux/obj"
  )

  for path in "${paths[@]}"; do
    rm -rf "${path}"
  done

  mkdir -p "${BUILD_ROOT}/medusa/Bin" "${BUILD_ROOT}/gamecq/Bin" "${BUILD_ROOT}/darkspace/Bin"
  mkdir -p /home/builder/work/Trunk/Medusa/Bin
  mkdir -p /home/builder/work/Trunk/Medusa/ReleaseLinux/obj
}

mkdir -p /home/builder/work/Trunk/Medusa/Medusa/ReleaseLinux
ln -sfn /home/builder/work/Trunk/Medusa/ReleaseLinux/obj /home/builder/work/Trunk/Medusa/Medusa/ReleaseLinux/obj
reset_release_outputs

# Replace bundled legacy 32-bit mysql client libs with host-arch MariaDB compatibility symlink.
MYSQL_LIB_DIR="${BUILD_ROOT}/gamecq/ThirdParty/mysql/x86-Linux/lib"
rm -f "${MYSQL_LIB_DIR}/libmysqlclient.a" "${MYSQL_LIB_DIR}/libmysqlclient.so" "${MYSQL_LIB_DIR}/libmysql.so"
ln -s /usr/lib/x86_64-linux-gnu/libmysqlclient.so "${MYSQL_LIB_DIR}/libmysqlclient.so"

# Replace bundled legacy 32-bit LuaJIT static libs with host-arch lua5.1 shared lib symlink.
LUA_LIB_DIR="${BUILD_ROOT}/medusa/ThirdParty/LuaJIT/bin"
rm -f "${LUA_LIB_DIR}/liblua51.a" "${LUA_LIB_DIR}/liblua51D.a" "${LUA_LIB_DIR}/liblua51.so"
ln -s /usr/lib/x86_64-linux-gnu/liblua5.1.so "${LUA_LIB_DIR}/liblua51.so"

hydrate_prebuilt_bins() {
  local source_dir="$1"
  local target_dir="$2"
  shift 2

  mkdir -p "${target_dir}"
  for file in "$@"; do
    if [[ ! -f "${source_dir}/${file}" ]]; then
      echo "Missing prebuilt dependency for incremental build: ${source_dir}/${file}" >&2
      exit 1
    fi
    cp -f "${source_dir}/${file}" "${target_dir}/"
  done
}

build_release() {
  local dir="$1"
  echo "==> Building ${dir} (jobs=${MAKE_JOBS})"
  make -s -C "${dir}" -j"${MAKE_JOBS}" BUILD_CONFIGURATION=ReleaseLinux CXX="ccache g++ ${CXX_BASE_FLAGS}"
}

case "${BUILD_SCOPE}" in
  full)
    build_release medusa/Medusa
    build_release medusa/Network
    build_release medusa/GCQ
    build_release medusa/Render3D
    build_release medusa/World

    build_release gamecq/GCQDB
    build_release gamecq/Gcqs
    build_release gamecq/MetaServer
    build_release gamecq/ProcessServer
    build_release gamecq/MirrorServer

    build_release darkspace/DarkSpace
    build_release darkspace/DarkSpaceServer
    ;;
  core)
    build_release medusa/Medusa
    build_release medusa/Network
    build_release medusa/GCQ
    build_release medusa/Render3D
    build_release medusa/World

    build_release gamecq/GCQDB
    build_release gamecq/Gcqs
    build_release gamecq/MetaServer
    build_release gamecq/ProcessServer
    build_release gamecq/MirrorServer
    ;;
  server)
    hydrate_prebuilt_bins "${BUILD_ROOT}/medusa/out/server-bootstrap/Release" "${BUILD_ROOT}/medusa/Bin" \
      libMedusa.so libNetwork.so libGCQ.so

    build_release gamecq/GCQDB
    build_release gamecq/Gcqs
    build_release gamecq/MetaServer
    build_release gamecq/ProcessServer
    build_release gamecq/MirrorServer
    ;;
  meta)
    hydrate_prebuilt_bins "${BUILD_ROOT}/medusa/out/server-bootstrap/Release" "${BUILD_ROOT}/medusa/Bin" \
      libMedusa.so libNetwork.so libGCQ.so
    hydrate_prebuilt_bins "${BUILD_ROOT}/gamecq/out/server-bootstrap/Release" "${BUILD_ROOT}/gamecq/Bin" \
      libGCQS.so

    build_release gamecq/GCQDB
    build_release gamecq/MetaServer
    ;;
  *)
    echo "Unsupported BUILD_SCOPE: ${BUILD_SCOPE}" >&2
    exit 1
    ;;
esac

mkdir -p medusa/out/server-bootstrap/Release
mkdir -p gamecq/out/server-bootstrap/Release
mkdir -p darkspace/out/server-bootstrap/Release

cp -f gamecq/Bin/libGCQDB.so gamecq/out/server-bootstrap/Release/

if [[ "${BUILD_SCOPE}" != "meta" ]]; then
  cp -f gamecq/Bin/libGCQS.so gamecq/out/server-bootstrap/Release/
fi

cp -f gamecq/Bin/MetaServer gamecq/out/server-bootstrap/Release/

if [[ "${BUILD_SCOPE}" != "meta" ]]; then
  cp -f gamecq/Bin/ProcessServer gamecq/out/server-bootstrap/Release/
  cp -f gamecq/Bin/MirrorServer gamecq/out/server-bootstrap/Release/
fi

if [[ "${BUILD_SCOPE}" == "full" || "${BUILD_SCOPE}" == "core" ]]; then
  cp -f medusa/Bin/libMedusa.so medusa/out/server-bootstrap/Release/
  cp -f medusa/Bin/libNetwork.so medusa/out/server-bootstrap/Release/
  cp -f medusa/Bin/libGCQ.so medusa/out/server-bootstrap/Release/
  cp -f medusa/Bin/libRender3D.so medusa/out/server-bootstrap/Release/
  cp -f medusa/Bin/libWorld.so medusa/out/server-bootstrap/Release/

fi

if [[ "${BUILD_SCOPE}" == "full" ]]; then
  cp -f darkspace/Bin/libDarkSpace.so darkspace/out/server-bootstrap/Release/
  cp -f darkspace/Bin/DarkSpaceServer darkspace/out/server-bootstrap/Release/
  cp -f /usr/lib/x86_64-linux-gnu/liblua5.1.so* darkspace/out/server-bootstrap/Release/
fi

mkdir -p "${SRC_ROOT}/medusa/out/server-bootstrap/Release"
mkdir -p "${SRC_ROOT}/gamecq/out/server-bootstrap/Release"
mkdir -p "${SRC_ROOT}/darkspace/out/server-bootstrap/Release"

cp -f medusa/out/server-bootstrap/Release/* "${SRC_ROOT}/medusa/out/server-bootstrap/Release/"
cp -f gamecq/out/server-bootstrap/Release/* "${SRC_ROOT}/gamecq/out/server-bootstrap/Release/"
cp -f darkspace/out/server-bootstrap/Release/* "${SRC_ROOT}/darkspace/out/server-bootstrap/Release/"

echo "Legacy Linux build complete."
