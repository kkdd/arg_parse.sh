# arg_parse.sh

A small, readable **POSIX-compliant shell argument parser**.

Works with `sh`, `dash`, `bash` without external dependencies.

---

## Features

- POSIX compatible
- Short and long options (`-v`, `--verbose`)
- Combined short flags (`-abc`)
- Options with values (`-m dog`, `--mammal=dog`)
- Simple `while + case` structure
- No external commands

---

## Constraints

- Options must come before positional arguments  
- Values starting with `-` are not supported as arguments

---

## Example

```sh
./arg_parse.sh -d -m dog --loops=0  1 2 3
```

---

## Supported Forms

```sh
-h
--help

-m dog
-mdog
--mammal dog
--mammal=dog
```

---

## Design

Focused on:

- Readability
- Minimalism
- Portability

A lightweight alternative to `getopts` / `getopt`.

---

## Example of Warning

```console
$ ./arg_parse.sh --loops -xy
Warning: Type "arg_parse.sh --help" for usage instructions.
- Option '--loops' requires an argument
- Unknown option: '-x'
- Unknown option: '-y'
```

---

## Example of Usage

```console
$ ./arg_parse.sh --help

    Name: arg_parse.sh - parse arguments

    Usage: arg_parse.sh [options] [positinal_argument [...]]

    Options:
      -h|--help          Show this usage and exit.
      -d|--debug         Enable debug mode.
      -l|--loops N       Set the number of loops (default: 1)
      -m|--mammal NAME   Set mammal name.
```

---

## License

See repository license.
