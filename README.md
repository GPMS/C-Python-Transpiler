# C to Python Transpiler

A **Linux only** transpiler that translates C code into Python using bison and flex.

## Dependencies
- gcc
- make
- bison
- flex

## Compiling
```shell
$ make
```

## Running
```shell
$ ./cmp <c-file>
```
If there are no errors, the program will output a python file, a .dot graph file and a txt file with all symbols to the 'output' folder.

## Running Tests
```shell
$ ./tests
```