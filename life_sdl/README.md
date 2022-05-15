### Life_Game test with SDL1

---
Life Game test

Language: nim

Libraries:

```shell
$ nimble install sdl1 graphics
```

#### Prerequisite

---

- libwinpthread-1.dll, SDL1.dll SDL_ttf.dll
   -  32bit version: included in this project.
   -  64bit version: not included in this project.

  If you execute \*.exe file on 64bit Windows,  
  it would need 64bit version dlls.

#### Build and run

---

For example,

```Shell
make
```

Execute `life_sdl.exe`
