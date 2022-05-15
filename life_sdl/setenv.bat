@echo off
set nimver=1.6.6
set dirs=d:\nim-data\gcc\bin
set dirs=%dirs%;c:\Users\%USERNAME%\.choosenim\toolchains\nim-%nimver%\bin
set dirs=%dirs%;c:\make\bin
set path=%dirs%;d:\msys32\mingw32\bin;d:\msys32\usr\bin
