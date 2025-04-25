#lang racket/base

(provide path->synthesized-alias-bytes)

;; ----------------------------------------
;; Instad of using Mac libraries, this function synthesizes bytes
;; directly using the undocumented structure of an alias. Information
;; about the structure is from
;;   https://en.wikipedia.org/wiki/Alias_(Mac_OS)
;; combined with some guesses from additional experiments

(define (path->synthesized-alias-bytes #:volume-name volume-name
                                       #:file-name file-name
                                       #:file-inode file-inode
                                       #:parent-name parent-name
                                       #:parent-inode parent-inode
                                       #:file-absolute-name file-absolute-name
                                       #:file-absolute-path-within-volume file-absolute-path-within-volume
                                       #:volume-maybe-absolute-path volume-maybe-absolute-path)
  (define bigend? #t)
  (define (short n) (integer->integer-bytes n 2 #f bigend?))
  (define (sshort n) (integer->integer-bytes n 2 #t bigend?))
  (define (int n) (integer->integer-bytes n 4 #f bigend?))
  (define (size+pad s n)
    (define bstr (string->bytes/utf-8 s))
    (bytes-append (bytes (bytes-length bstr)) bstr (make-bytes (- n (bytes-length bstr)))))
  (define (short-size+even-pad parent-name)
    (define bstr (string->bytes/utf-8 parent-name))
    (define len (bytes-length bstr))
    (bytes-append (short len) bstr (if (even? len) #"" #"\0")))
  (define (size+utf-16-with-size s)
    ;; doesn't try to handle surrogate pairs
    (define bytes (make-bytes (* 2 (add1 (string-length s)))))
    (bytes-set! bytes 1 (string-length s))
    (for ([c (in-string s)]
          [i (in-naturals 1)])
      (integer->integer-bytes (char->integer c) 2 #f bigend? bytes (* i 2)))
    (bytes-append (short (bytes-length bytes)) bytes))
  (define now-date (+ (current-seconds)
                      ;; offset in seconds to 1904
                      2082819600))
  (define base-bstr
    (bytes-append
     (short 2) ; version
     (short 0) ; kind = file
     (size+pad volume-name 27)
     (int now-date)
     #"H+"
     (short 5) ; ejectable media
     (int parent-inode)
     (size+pad file-name 63)
     (int file-inode)
     (int now-date)
     #"\0\0\0\0" ; file type
     #"\0\0\0\0" ; file creator
     (sshort -1) ; nlvl from
     (sshort -1) ; nlvl to
     (int #xd02) ; volume attributes
     (short 0) ; filesystem id
     (make-bytes 10) ; reserved

     ;; start of tagged optional values

     (short 0) ; type = directory name
     (short-size+even-pad parent-name)

     (short 1) ; type = directory ids
     (short 0)

     (short 2) ; type = absolute-path
     (short-size+even-pad file-absolute-name)

     (short 14) ; type = file name as utf-16 ?
     (size+utf-16-with-size file-name)

     (short 15) ; type = parent name as utf-16 ?
     (size+utf-16-with-size parent-name)

     (short 18) ; type = abs path within volume ?
     (short-size+even-pad file-absolute-path-within-volume)

     (short 19) ; type = volume likely mount point ?
     (short-size+even-pad volume-maybe-absolute-path)

     (sshort -1) ; type: end
     (short 0)))

  (bytes-append
   #"\0\0\0\0" ; no creator
   (short (+ (bytes-length base-bstr) 6))
   base-bstr))
