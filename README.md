Overview
--------

acclint is a lint program that checks AC3D model files for problems.  It supports
the standard AC3D file format (files ending in .ac) and the extended AC3D file
format used by TORCS and Speed Dreams (files ending in .acc).  acclint is also
able to correct many common problems.

Download
--------

Use the [git clone](https://git-scm.com/docs/git-clone) command to download this
project:

```
git clone https://github.com/IOBYTE/acclint
cd acclint
```

Build with CMake and GNU Make
-----------------------------

Create a build directory inside the example project directory and configure the
build using [CMake](https://cmake.org) to generate the Makefiles for
[GNU Make](https://www.gnu.org/software/make/):
```
mkdir build && cd build
cmake CMAKE_BUILD_TYPE=Release ..
```

Then build the executable named ```acclint``` using GNU Make:
```
make
```

The resulting binary is ```acclint``` inside the build directory.

You can install ```acclint``` using GNU Make:
```
sudo make install
```

Examples
-------

Here is an example of running ```acclint``` on the supplied file ```example.ac```.

```
AC3DbS
MATERIAL "1" png 1 1 1  amb 1 1 1  emis 0 0 0  spec 0.5 0.5 5  shi 64.1  trans 1.1
OBJECT world
kids 2
OBJECT poly
name "square"
numvert 7
0 0 0
0 1 0
1 0 0
1 0 0
0 1 0
1 1 0
1 1 1
numsurf 2
SURF 0x10
mat 0
refs 3
0 0 0
1 0 0
2 0 0
SURF 0x10
mat 0
refs 3
3 0 0
4 0 0
5 0 0
kids 0
```

```
acclint example.ac
example.ac:1 warning: trailing text: "S"
AC3DbS
     ^
example.ac:2 warning: invalid material rgb: png
MATERIAL "1" png 1 1 1  amb 1 1 1  emis 0 0 0  spec 0.5 0.5 5  shi 64.1  trans 1.1 
             ^
example.ac:2 warning: invalid material spec: 5 range: 0 to 1
MATERIAL "1" png 1 1 1  amb 1 1 1  emis 0 0 0  spec 0.5 0.5 5  shi 64.1  trans 1.1 
                                                            ^
example.ac:2 warning: floating point shi: 64.1
MATERIAL "1" png 1 1 1  amb 1 1 1  emis 0 0 0  spec 0.5 0.5 5  shi 64.1  trans 1.1 
                                                                   ^
example.ac:2 warning: invalid material trans: 1.1 range: 0 to 1
MATERIAL "1" png 1 1 1  amb 1 1 1  emis 0 0 0  spec 0.5 0.5 5  shi 64.1  trans 1.1 
                                                                               ^
example.ac:2 warning: trailing text: " "
MATERIAL "1" png 1 1 1  amb 1 1 1  emis 0 0 0  spec 0.5 0.5 5  shi 64.1  trans 1.1 
                                                                                  ^
example.ac:8 warning: trailing text: " "
0 0 0 
     ^
example.ac:12 warning: duplicate verticies
0 1 0
^
example.ac:9 note: first instance
0 1 0
^
example.ac:11 warning: duplicate verticies
1 0 0
^
example.ac:10 note: first instance
1 0 0
^
example.ac:19 warning: trailing text: " "
0 0 0 
     ^
example.ac:14 warning: unused vertex
1 1 1
^
example.ac:29 warning: blank line
example.ac:4 warning: missing kids: only 1 out of 2 kids found
13 warnings
```

acclint can also fix and optimize many common non-fatal problems.

```
acclint example.ac -o example-cleaned.ac
```
produces this:
```
AC3Db
MATERIAL "1" rgb 1 1 1  amb 1 1 1  emis 0 0 0  spec 0.5 0.5 1  shi 64  trans 1
OBJECT world
kids 1
OBJECT poly
name "square"
numvert 4
0 0 0
0 1 0
1 0 0
1 1 0
numsurf 2
SURF 0x10
mat 0
refs 3
0 0 0
1 0 0
2 0 0
SURF 0x10
mat 0
refs 3
2 0 0
1 0 0
3 0 0
kids 0
```
acclint can also convert from one file format version to another.
```
acclint filev12.ac -o filev11.ac -v 11
acclint filev11.ac -o filev12.ac -v 12
```
acclint can also convert .acc files to the .ac file format.
```
acclint file.acc -o file.ac
```
acclint can not convert .ac files to the .acc file format.
```
acclint file.ac -o file.acc
Can't convert file.ac to file.acc! Use accc from TORCS or Speed Dreams.
```
acclint can also dump the object hiearchy of a file.
```
acclint  --dump surf -Wno-warnings example.ac
1 world 1 kid
    1 poly "square" 2 surfaces
        1 surface 3 refs
        2 surface 3 refs
```
Running regression tests
--------

Running the regression tests on linux requires [Bats](https://github.com/bats-core/bats-core) (Bash Automated Testing System).

Change the current directory from the installed directory to the ```test``` directory and run the file ```testrunner.sh```.

acclint must be installed before you can run the tests.

```
cd test
bash testrunner.sh
```

Feedback
--------

This software is in early development and is far from feature complete. There is a todo list in ```TODO.txt```.

Please let me know if you have problems with the software or want to see improvements using [Issues](https://github.com/IOBYTE/acclint/issues).

Copyright
--------

© 2020-2021 Robert Reif

