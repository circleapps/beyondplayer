#!/bin/bash

set -ex
cd "$( dirname "${BASH_SOURCE[0]}" )"
#rm -rf dist
#mkdir dist

copy_deps() {
  local dep=$1
  local depname=$(basename $dep)
  [[ -e dist/$depname ]] || install -m755 $dep dist
  otool -L $dep | awk '/\/usr\/local.*\.dylib /{print $1}' | while read lib; do
    local libname=$(basename $lib)
    [[ $depname = $libname ]] && continue
    echo $libname
    install_name_tool -change $lib @loader_path/$libname dist/$depname
    [[ -e dist/$libname ]] && continue
    install -m755 $lib dist
    copy_deps $lib
  done
}

#set +x
#copy_deps /usr/local/lib/libmpv.1.dylib
#set -x

# See <https://github.com/Kagami/boram/issues/11>.
install_name_tool -change /System/Library/Frameworks/CoreImage.framework/Versions/A/CoreImage /System/Library/Frameworks/QuartzCore.framework/Versions/A/Frameworks/CoreImage.framework/Versions/A/CoreImage dist/libavfilter.7.dylib
install_name_tool -change /usr/local/opt/mpv/lib/libmpv.1.dylib '@loader_path/libmpv.1.dylib' ../src/node_modules/mpv.js/build/Release/mpvjs.node

chmod +x dist/*.dylib
cp -r dist/* ../src/node_modules/mpv.js/build/Release/

rm -f ../src/app/build/renderer.js.map

npm run dev_no_watch --prefix ../src

electron-packager ../src --overwrite --ignore=app/js --platform=darwin --arch=x64 --out=../build/dev --icon=../icon_pro.icns --prune \
 --electron-version=5.0.13 --extend-info extend-info-pro.plist