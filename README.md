# Scheme in dc

A small Scheme interpreter written in `dc`, the RPN calculator that ships with macOS and other *nix systems. Nothing else is needed except `/bin/sh` and `od` to feed it input.

```
chmod +x scheme.sh
./scheme.sh              # interactive REPL (Ctrl-D to quit)
./scheme.sh demo.scm     # run a program
```

## Files

- **scheme.dc** — the interpreter: reader, eval/apply, environments, primitives, printer, REPL. About 280 lines of dc.
- **prelude.scm** — the rest of the language written in Scheme: `let`, `let*`, `letrec`, named `let`, `cond`, `case`, `and`, `or`, `when`, `unless`, `do`, quasiquote, and list, number and string functions.
- **scheme.sh** — converts source text to one byte per line, because dc's only input command (`?`) reads a line and runs it as dc code.
- **demo.scm** — a tour.
- **scheme-trace.dc** — a copy of scheme.dc with print statements added, for learning how it works: the reader shows each symbol, number and string being encoded (base-256 bytes, then ×8 + tag), and eval shows each function call with its arguments and result, indented by depth. Calls aren't tail calls in this copy, so long loops use more memory. It's a separate copy, so changes to scheme.dc don't carry over.
- **trace.sh** — runs scheme-trace.dc (`./trace.sh`, or `echo '(fac 5)' | ./trace.sh`). Skips the prelude to keep the output readable, so only built-ins are available.

## How it works

Every Scheme value is a single dc number with a 3-bit type tag in the low bits: fixnums, pairs, symbols, closures, primitives, constants, strings, and syntax. Pairs are indexes into two dc arrays (`A` for car, `D` for cdr). A symbol is its name's bytes read as one base-256 number, so no symbol table is needed and dc's `P` prints it back. Strings use the same trick. Because dc numbers are arbitrary precision, integers are bignums for free.

The core implements only `quote`, `if`, `define`, `set!`, `lambda`, `begin`, and `define-macro`. Every other special form is a macro in the prelude. The first time a macro call runs, the interpreter overwrites it in place with its expansion, so loops don't re-expand.

Tail calls are proper: the evaluator always ends a tail position with dc's `x` command, and dc doesn't grow its stack for a macro's final `x`.

Errors (unbound variable, calling a non-procedure, `car` of a non-pair, `(error ...)`) print a message and abort the current top-level form; the REPL keeps going.

## Limitations

- **No garbage collector.** Every call allocates cons cells that are never reclaimed, so memory grows steadily: about 1.2 KB per call for a one-argument loop (40,000 calls peaked at 52 MB), more for functions with more arguments or nested calls. A few hundred thousand calls take a few hundred MB, so the limit depends on available memory. A collector is the natural next step.
- No `call/cc`, floats, vectors, chars, or hygienic macros. `define-macro` is Lisp-style, with `gensym` to avoid capture.
- **Speed:** about 17,000 calls per second to a user-defined function with macOS's dc (about 50,000 counting the built-in `=` and `-` calls inside each one), plus about 0.1 s to start up and load the prelude. GNU dc (most Linux systems) runs it correctly but is expected to be far slower, because its arrays are linked lists; that hasn't been measured.

  Measured on an Apple M2 Pro, macOS 26.3, with `/usr/bin/time -l ./scheme.sh` on `(define (loop n) (if (= n 0) (quote done) (loop (- n 1))))` for N = 0 to 40,000, single runs.
