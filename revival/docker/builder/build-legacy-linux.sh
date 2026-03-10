#!/usr/bin/env bash
set -euo pipefail

SRC_ROOT="${WORKSPACE_ROOT:-/workspace}"
BUILD_ROOT="/tmp/dswork"
MAKE_JOBS="${MAKE_JOBS:-$(nproc)}"
CXX_BASE_FLAGS="${CXX_BASE_FLAGS:--fpermissive -DMEDUSA_DISABLE_LUA_JIT_MODULE -w}"

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

mkdir -p medusa/Bin gamecq/Bin darkspace/Bin
mkdir -p /home/builder/work/Trunk/Medusa/Bin
mkdir -p /home/builder/work/Trunk/Medusa/ReleaseLinux/obj
mkdir -p /home/builder/work/Trunk/Medusa/Medusa/ReleaseLinux
ln -sfn /home/builder/work/Trunk/Medusa/ReleaseLinux/obj /home/builder/work/Trunk/Medusa/Medusa/ReleaseLinux/obj

# Replace bundled legacy 32-bit mysql client libs with host-arch MariaDB compatibility symlink.
MYSQL_LIB_DIR="${BUILD_ROOT}/gamecq/ThirdParty/mysql/x86-Linux/lib"
rm -f "${MYSQL_LIB_DIR}/libmysqlclient.a" "${MYSQL_LIB_DIR}/libmysqlclient.so" "${MYSQL_LIB_DIR}/libmysql.so"
ln -s /usr/lib/x86_64-linux-gnu/libmysqlclient.so "${MYSQL_LIB_DIR}/libmysqlclient.so"

# Replace bundled legacy 32-bit LuaJIT static libs with host-arch lua5.1 shared lib symlink.
LUA_LIB_DIR="${BUILD_ROOT}/medusa/ThirdParty/LuaJIT/bin"
rm -f "${LUA_LIB_DIR}/liblua51.a" "${LUA_LIB_DIR}/liblua51D.a" "${LUA_LIB_DIR}/liblua51.so"
ln -s /usr/lib/x86_64-linux-gnu/liblua5.1.so "${LUA_LIB_DIR}/liblua51.so"

build_release() {
  local dir="$1"
  echo "==> Building ${dir} (jobs=${MAKE_JOBS})"
  make -s -C "${dir}" -j"${MAKE_JOBS}" BUILD_CONFIGURATION=ReleaseLinux CXX="g++ ${CXX_BASE_FLAGS}"
}

# Core medusa libs
build_release medusa/Medusa
build_release medusa/Network
build_release medusa/GCQ
build_release medusa/Render3D
build_release medusa/World

# GameCQ libs and services
build_release gamecq/GCQDB
build_release gamecq/Gcqs
build_release gamecq/MetaServer
build_release gamecq/ProcessServer
build_release gamecq/MirrorServer

# DarkSpace libs and server
build_release darkspace/DarkSpace
build_release darkspace/DarkSpaceServer

mkdir -p medusa/out/server-bootstrap/Release
mkdir -p gamecq/out/server-bootstrap/Release
mkdir -p darkspace/out/server-bootstrap/Release

cp -f medusa/Bin/libMedusa.so medusa/out/server-bootstrap/Release/
cp -f medusa/Bin/libNetwork.so medusa/out/server-bootstrap/Release/
cp -f medusa/Bin/libGCQ.so medusa/out/server-bootstrap/Release/
cp -f medusa/Bin/libRender3D.so medusa/out/server-bootstrap/Release/
cp -f medusa/Bin/libWorld.so medusa/out/server-bootstrap/Release/

cp -f gamecq/Bin/libGCQDB.so gamecq/out/server-bootstrap/Release/
cp -f gamecq/Bin/libGCQS.so gamecq/out/server-bootstrap/Release/
cp -f gamecq/Bin/MetaServer gamecq/out/server-bootstrap/Release/
cp -f gamecq/Bin/ProcessServer gamecq/out/server-bootstrap/Release/
cp -f gamecq/Bin/MirrorServer gamecq/out/server-bootstrap/Release/
cp -f darkspace/Bin/libDarkSpace.so darkspace/out/server-bootstrap/Release/
cp -f darkspace/Bin/DarkSpaceServer darkspace/out/server-bootstrap/Release/
cp -f /usr/lib/x86_64-linux-gnu/liblua5.1.so* darkspace/out/server-bootstrap/Release/

mkdir -p "${SRC_ROOT}/medusa/out/server-bootstrap/Release"
mkdir -p "${SRC_ROOT}/gamecq/out/server-bootstrap/Release"
mkdir -p "${SRC_ROOT}/darkspace/out/server-bootstrap/Release"

cp -f medusa/out/server-bootstrap/Release/* "${SRC_ROOT}/medusa/out/server-bootstrap/Release/"
cp -f gamecq/out/server-bootstrap/Release/* "${SRC_ROOT}/gamecq/out/server-bootstrap/Release/"
cp -f darkspace/out/server-bootstrap/Release/* "${SRC_ROOT}/darkspace/out/server-bootstrap/Release/"

echo "Legacy Linux build complete."
