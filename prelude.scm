;;; prelude.scm -- the rest of Scheme, written in Scheme
;;;
;;; scheme.dc only knows quote, if, define, set!, lambda, begin and
;;; define-macro, plus a few dozen primitives. Everything below is
;;; built from those. Macro expansions are cached: the interpreter
;;; overwrites each macro call with its expansion the first time it runs.

;; ---- pairs and lists -------------------------------------------------
(define (caar x) (car (car x)))
(define (cadr x) (car (cdr x)))
(define (cdar x) (cdr (car x)))
(define (cddr x) (cdr (cdr x)))
(define (caddr x) (car (cddr x)))
(define (cdddr x) (cdr (cddr x)))
(define (cadddr x) (car (cdddr x)))

(define (map1 f l)
  (if (null? l) '() (cons (f (car l)) (map1 f (cdr l)))))

(define (append2 a b)
  (if (null? a) b (cons (car a) (append2 (cdr a) b))))

(define (append . ls)
  (if (null? ls) '()
      (if (null? (cdr ls)) (car ls)
          (append2 (car ls) (apply append (cdr ls))))))

;; ---- quasiquote ------------------------------------------------------
;; `(a ,b ,@c) becomes (cons 'a (cons b (append c '())))
(define (%qq x)
  (if (pair? x)
      (if (eq? (car x) 'unquote)
          (cadr x)
          (if (if (pair? (car x)) (eq? (caar x) 'unquote-splicing) #f)
              (list 'append (cadr (car x)) (%qq (cdr x)))
              (list 'cons (%qq (car x)) (%qq (cdr x)))))
      (list 'quote x)))

(define-macro (quasiquote x) (%qq x))

;; ---- binding forms ---------------------------------------------------
(define-macro (letrec bindings . body)
  `((lambda () ,@(map1 (lambda (b) `(define ,@b)) bindings) ,@body)))

(define-macro (let bindings . body)
  (if (symbol? bindings)
      ;; named let: (let loop ((i 0)) ...)
      `((letrec ((,bindings (lambda ,(map1 car (car body)) ,@(cdr body))))
          ,bindings)
        ,@(map1 cadr (car body)))
      `((lambda ,(map1 car bindings) ,@body) ,@(map1 cadr bindings))))

(define-macro (let* bindings . body)
  (if (null? bindings)
      `(let () ,@body)
      `(let (,(car bindings)) (let* ,(cdr bindings) ,@body))))

;; ---- conditionals ----------------------------------------------------
(define-macro (and . xs)
  (if (null? xs) #t
      (if (null? (cdr xs)) (car xs)
          `(if ,(car xs) (and ,@(cdr xs)) #f))))

(define-macro (or . xs)
  (if (null? xs) #f
      (if (null? (cdr xs)) (car xs)
          (let ((t (gensym)))
            `(let ((,t ,(car xs))) (if ,t ,t (or ,@(cdr xs))))))))

(define-macro (cond . clauses)
  (if (null? clauses) #f
      (let ((test (caar clauses)) (body (cdar clauses)))
        (if (eq? test 'else)
            `(begin ,@body)
            (if (null? body)
                `(or ,test (cond ,@(cdr clauses)))
                (if (eq? (car body) '=>)
                    (let ((t (gensym)))
                      `(let ((,t ,test))
                         (if ,t (,(cadr body) ,t) (cond ,@(cdr clauses)))))
                    `(if ,test (begin ,@body) (cond ,@(cdr clauses)))))))))

(define-macro (when c . body) `(if ,c (begin ,@body) #f))
(define-macro (unless c . body) `(if ,c #f (begin ,@body)))

(define-macro (case key . clauses)
  (let ((k (gensym)))
    `(let ((,k ,key))
       (cond ,@(map1 (lambda (c)
                       (if (eq? (car c) 'else)
                           c
                           `((memv ,k ',(car c)) ,@(cdr c))))
                     clauses)))))

(define-macro (do specs test-and-result . body)
  (let ((loop (gensym)))
    `(let ,loop ,(map1 (lambda (s) (list (car s) (cadr s))) specs)
       (if ,(car test-and-result)
           (begin ,@(cdr test-and-result))
           (begin ,@body
                  (,loop ,@(map1 (lambda (s) (if (null? (cddr s)) (car s) (caddr s)))
                                 specs)))))))

;; ---- types -----------------------------------------------------------
(define (number? x) (eq? (%tag x) 0))
(define integer? number?)
(define (symbol? x) (eq? (%tag x) 2))
(define (string? x) (eq? (%tag x) 6))
(define (procedure? x) (or (eq? (%tag x) 3) (eq? (%tag x) 4)))
(define (boolean? x) (or (eq? x #t) (eq? x #f)))
(define (list? x) (or (null? x) (and (pair? x) (list? (cdr x)))))

(define (equal? a b)
  (if (and (pair? a) (pair? b))
      (and (equal? (car a) (car b)) (equal? (cdr a) (cdr b)))
      (eq? a b)))

;; ---- numbers ---------------------------------------------------------
(define (zero? n) (= n 0))
(define (positive? n) (> n 0))
(define (negative? n) (< n 0))
(define (even? n) (= (remainder n 2) 0))
(define (odd? n) (not (even? n)))
(define (abs n) (if (< n 0) (- n) n))
(define (modulo a b)
  (let ((r (remainder a b)))
    (if (and (not (= r 0)) (not (eq? (< r 0) (< b 0)))) (+ r b) r)))
(define (min a . xs) (fold-left (lambda (m x) (if (< x m) x m)) a xs))
(define (max a . xs) (fold-left (lambda (m x) (if (> x m) x m)) a xs))
(define (gcd a b) (if (= b 0) (abs a) (gcd b (remainder a b))))
(define (expt b n) (if (= n 0) 1 (* b (expt b (- n 1)))))
(define (square x) (* x x))
(define (1+ n) (+ n 1))
(define (1- n) (- n 1))

;; ---- lists -----------------------------------------------------------
(define (length l)
  (let loop ((l l) (n 0)) (if (null? l) n (loop (cdr l) (+ n 1)))))
(define (reverse l)
  (let loop ((l l) (r '())) (if (null? l) r (loop (cdr l) (cons (car l) r)))))
(define (list-tail l k) (if (= k 0) l (list-tail (cdr l) (- k 1))))
(define (list-ref l k) (car (list-tail l k)))
(define (last-pair l) (if (null? (cdr l)) l (last-pair (cdr l))))

(define (map f l . ls)
  (if (null? ls)
      (map1 f l)
      (let loop ((ls (cons l ls)))
        (if (null? (car ls)) '()
            (cons (apply f (map1 car ls)) (loop (map1 cdr ls)))))))

(define (for-each f l)
  (if (null? l) #t (begin (f (car l)) (for-each f (cdr l)))))

(define (filter p l)
  (cond ((null? l) '())
        ((p (car l)) (cons (car l) (filter p (cdr l))))
        (else (filter p (cdr l)))))

(define (fold-left f acc l)
  (if (null? l) acc (fold-left f (f acc (car l)) (cdr l))))
(define (fold-right f acc l)
  (if (null? l) acc (f (car l) (fold-right f acc (cdr l)))))
(define (reduce f init l)
  (if (null? l) init (fold-left f (car l) (cdr l))))

(define (memq x l) (cond ((null? l) #f) ((eq? x (car l)) l) (else (memq x (cdr l)))))
(define memv memq)
(define (member x l) (cond ((null? l) #f) ((equal? x (car l)) l) (else (member x (cdr l)))))
(define (assq k al) (cond ((null? al) #f) ((eq? k (caar al)) (car al)) (else (assq k (cdr al)))))
(define assv assq)
(define (assoc k al) (cond ((null? al) #f) ((equal? k (caar al)) (car al)) (else (assoc k (cdr al)))))

(define (iota n) (let loop ((i (- n 1)) (acc '())) (if (< i 0) acc (loop (- i 1) (cons i acc)))))

;; ---- strings ---------------------------------------------------------
;; A string is its bytes as one base-256 number, so string functions are
;; arithmetic on that number (%string->bytes / %bytes->string convert).
(define (string-length s)
  (let loop ((b (%string->bytes s)) (n 0))
    (if (= b 0) n (loop (quotient b 256) (+ n 1)))))

(define (number->string n)
  (define (digits n acc)
    (if (< n 10)
        (+ (* acc 256) 48 n)
        (digits (quotient n 10) (+ (* acc 256) 48 (remainder n 10)))))
  (define (rev b acc) (if (= b 0) acc (rev (quotient b 256) (+ (* acc 256) (remainder b 256)))))
  (if (< n 0)
      (string-append "-" (number->string (- n)))
      ;; digits come out least significant first, so reverse the bytes
      (%bytes->string (rev (digits n 0) 0))))

(define (string=? a b) (eq? a b))

;; ---- misc ------------------------------------------------------------
(define (void) (if #f #f))
(define (print . xs) (for-each display xs) (newline))
