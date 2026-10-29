#!/bin/sh
# trace.sh -- run scheme-trace.dc, which prints how the reader encodes
# each symbol, number and string as it reads them.
#
#   ./trace.sh                          interactive: type expressions
#   echo '"15"' | ./trace.sh            trace one expression
#
# The prelude is skipped so its hundreds of symbols don't flood the
# trace. Built-ins like car, +, string-append still work; prelude
# functions and macros (let, cond, list helpers) are not defined.

here=$(cd "$(dirname "$0")" && pwd)
DC=${SCHEME_DC:-dc}

bytes() {
    for b in $(od -An -tu1 -v); do echo "$b"; done
}

{
    echo _3
    while IFS= read -r line || [ -n "$line" ]; do
        printf '%s\n' "$line" | bytes
    done
    echo _1
} | DC_LINE_LENGTH=0 "$DC" "$here/scheme-trace.dc"
