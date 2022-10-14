# z3-ocaml-build
Repro for `flexdll` *Out of memory while reading `z3.dll.a`* when building `Ocaml` bindings for `z3`.

## Usage
Run `build.ps1` in `powershell` as follows:
```powershell
powershell.exe -ExecutionPolicy RemoteSigned -File .\build.ps1
```
This script does the following:
1. Install cygwin with the required packages in `z3-ocaml-build_root_dir/cygwin`:
    - coreutils
    - make
    - mingw64-x86_64-gcc-g++
    - mingw64-x86_64-gmp
    - curl
    - python
2. Build following packages in `z3-ocaml-build_root_dir/prefix` using the `Makefile`:
    - OCaml 4.14.0  
    - Flexdll 0.41
    - Findlib 1.9.1
    - Zarith 1.12
    - Z3 4.11.2

The `z3` build will fail at:
```
ocamlmklib -o api/ml/z3ml  -I api/ml -L. api/ml/z3native_stubs.o api/ml/z3enums.cmo api/ml/z3native.cmo api/ml/z3.cmo  -lz3 -lstdc++ -cclib -static-libgcc -cclib -static-libstdc++ -ccopt -L$(ocamlfind printconf destdir)/stublibs -dllpath $(ocamlfind printconf destdir)/stublibs
```
```
** Fatal error: Error while reading libz3.dll.a: Out of memory
```