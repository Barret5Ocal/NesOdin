#!/bin/bash

code="$PWD"
opts=-g
cd ..\..\build > /dev/null
g++ $opts $code/CPU.odin -o NES.exe
cd $code > /dev/null
