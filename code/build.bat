@echo off

set opts=-debug
set code=%cd%
pushd ..\..\build
odin build %code% %opts%
popd
