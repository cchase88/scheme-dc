#!/bin/sh
# scheme.sh -- run the dc Scheme interpreter
#
#   ./scheme.sh              interactive: type expressions, results are printed
#   ./scheme.sh file.scm     run a program
#
# dc can't read raw characters: its ? command reads a line and runs it as
# dc code. So this script turns the source into one decimal byte per line
# with od, and dc reads it a character at a time. Special lines:
#   _3  turn on echo (REPL mode)      _1  end of input
# Set SCHEME_DC to choose a dc binary (default: dc on your PATH).

here=$(cd "$(dirname "$0")" && pwd)
DC=${SCHEME_DC:-dc}

bytes() {
    for b in $(od -An -tu1 -v); do echo "$b"; done
}

{
    bytes < "$here/prelude.scm"
    if [ $# -gt 0 ]; then
        for f in "$@"; do bytes < "$f"; echo 10; done
    else
        echo _3
        while IFS= read -r line || [ -n "$line" ]; do
            printf '%s\n' "$line" | bytes
        done
    fi
    echo _1
} | DC_LINE_LENGTH=0 "$DC" "$here/scheme.dc"
