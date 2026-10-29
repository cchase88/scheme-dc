;;; demo.scm -- a tour of what the dc Scheme can do
;;; run with:  ./scheme.sh demo.scm

;; Recursion, and free bignums (dc numbers have no size limit)
(define (fact n) (if (= n 0) 1 (* n (fact (- n 1)))))
(print "30! = " (fact 30))
(print "2^128 = " (expt 2 128))

;; Tail calls run in constant stack: this loop doesn't grow dc's stack
(define (count-to n)
  (let loop ((i 0)) (if (< i n) (loop (+ i 1)) i)))
(print "counted to " (count-to 10000))

;; Closures with private state
(define (make-counter)
  (let ((n 0))
    (lambda () (set! n (+ n 1)) n)))
(define tick (make-counter))
(tick) (tick)
(print "counter says " (tick))

;; Higher-order list functions (all defined in prelude.scm)
(print (map (lambda (x) (* x x)) (iota 10)))
(print (filter even? (iota 10)))
(print (fold-left + 0 (iota 101)))

;; Macros: define-macro is the only macro facility in the core;
;; let, cond, and, or, case, do and quasiquote are all built with it.
(define-macro (while test . body)
  (let ((loop (gensym)))
    `(let ,loop () (when ,test ,@body (,loop)))))

(define i 0)
(while (< i 5)
  (display i) (display " ")
  (set! i (+ i 1)))
(newline)

;; A tiny symbolic differentiator
(define (deriv e x)
  (cond ((number? e) 0)
        ((symbol? e) (if (eq? e x) 1 0))
        ((eq? (car e) '+) `(+ ,(deriv (cadr e) x) ,(deriv (caddr e) x)))
        ((eq? (car e) '*) `(+ (* ,(cadr e) ,(deriv (caddr e) x))
                              (* ,(deriv (cadr e) x) ,(caddr e))))
        (else (error "unknown expression" e))))
(print "d/dx (x*x + 3x) = " (deriv '(+ (* x x) (* 3 x)) 'x))

;; Strings are bignums too, so string-append is arithmetic
(print (string-append "fib(20) = " (number->string
  (let fib ((n 20)) (if (< n 2) n (+ (fib (- n 1)) (fib (- n 2))))))))
