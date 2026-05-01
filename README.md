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
./script.sh -v -m dog -a a,b,c 1 2 3
```

---

## Supported Forms

```sh
-v
--verbose

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

## License

See repository license.
