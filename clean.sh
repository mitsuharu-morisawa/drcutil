#!/usr/bin/env bash

source config.sh

cd $SRC_DIR/OpenRTM-aist
make maintainer-clean
rm -rf $SRC_DIR/openhrp3/build
rm -rf $SRC_DIR/HRP2/build
rm -rf $SRC_DIR/HRP2KAI/build
rm -rf $SRC_DIR/HRP5P/build
rm -rf $SRC_DIR/hrpsys-base/build
rm -rf $SRC_DIR/hrpsys-private/build
rm -rf $SRC_DIR/hrpsys-humanoid/build
rm -rf $SRC_DIR/state-observation/build
rm -rf $SRC_DIR/hrpsys-state-observation/build
rm -rf $SRC_DIR/hmc2/build
rm -rf $SRC_DIR/choreonoid/build
rm -rf $SRC_DIR/sch-core/build
rm -rf $SRC_DIR/trap-fpe/build
rm -rf $SRC_DIR/savedbg/build
