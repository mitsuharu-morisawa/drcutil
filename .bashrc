source config.sh

export PATH=$PREFIX/bin:$PATH
export LD_LIBRARY_PATH=$PREFIX/lib:$PREFIX/share/DynamoRIO-$DYNAMORIO_VERSION/ext/lib64/release:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
export PYTHONPATH=$PREFIX/lib/python2.7/dist-packages/hrpsys:$PYTHONPATH
