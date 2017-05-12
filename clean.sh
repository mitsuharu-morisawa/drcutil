#!/usr/bin/env bash

source config.sh

cd $SRC_DIR/OpenRTM-aist
make maintainer-clean
rm -rf $SRC_DIR/openhrp3/$BUILD_SUBDIR
rm -rf $SRC_DIR/HRP2/$BUILD_SUBDIR
rm -rf $SRC_DIR/HRP2KAI/$BUILD_SUBDIR
rm -rf $SRC_DIR/HRP5P/$BUILD_SUBDIR
rm -rf $SRC_DIR/hrpsys-base/$BUILD_SUBDIR
rm -rf $SRC_DIR/hrpsys-private/$BUILD_SUBDIR
rm -rf $SRC_DIR/hrpsys-humanoid/$BUILD_SUBDIR
rm -rf $SRC_DIR/state-observation/$BUILD_SUBDIR
rm -rf $SRC_DIR/hrpsys-state-observation/$BUILD_SUBDIR
rm -rf $SRC_DIR/hmc2/$BUILD_SUBDIR
rm -rf $SRC_DIR/choreonoid/$BUILD_SUBDIR
rm -rf $SRC_DIR/sch-core/$BUILD_SUBDIR
rm -rf $SRC_DIR/trap-fpe/$BUILD_SUBDIR
rm -rf $SRC_DIR/savedbg/$BUILD_SUBDIR
