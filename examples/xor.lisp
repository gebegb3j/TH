(defpackage :xor-example
  (:use #:common-lisp
        #:mu
        #:th))

(in-package :xor-example)

;; because there's no complete neural network library without xor example

;; direct, without using ad.
(defun fwd (input weight) ($sigmoid! ($@ input weight)))
(defun dwb (delta output) ($* delta output ($- 1 output)))

(time
 (with-foreign-memory-limit
   (let* ((X (tensor '((0 0 1) (0 1 1) (1 0 1) (1 1 1))))
          (Y (tensor '((0) (1) (1) (0))))
          (w1 (rndn 3 3))
          (w2 (rndn 3 1))
          (lr 1))
     (loop :for i :from 0 :below 1000
           :do (let* ((l1 (fwd X w1))
                      (l2 (fwd l1 w2))
                      (l2d (dwb ($- l2 y) l2))
                      (l1d (dwb ($@ l2d ($transpose w2)) l1))
                      (dw2 ($@ ($transpose l1) l2d))
                      (dw1 ($@ ($transpose X) l1d)))
                 ($sub! w1 ($* lr dw1))
                 ($sub! w2 ($* lr dw2))))
     (prn (fwd (fwd X w1) w2)))))

;; using ad or autograd
(time
 (with-foreign-memory-limit
     (let* ((w1 ($parameter (rndn 3 3)))
            (w2 ($parameter (rndn 3 1)))
            (X (tensor '((0 0 1) (0 1 1) (1 0 1) (1 1 1))))
            (Y (tensor '(0 1 1 0)))
            (lr 1))
       (loop :for i :from 0 :below 1000
             :do (let* ((l1 ($sigmoid ($mm X w1)))
                        (l2 ($sigmoid ($mm l1 w2)))
                        (d ($sub l2 Y))
                        (out ($dot d d)))
                   ($gs! out 1)
                   ($gd! w1 lr)
                   ($gd! w2 lr)))
       (prn ($sigmoid ($mm ($sigmoid ($mm X w1)) w2))))))

(let* ((w1 ($parameter ($xaviern! (tensor 3 3))))
       (w2 ($parameter ($xaviern! (tensor 3 1))))
       (X (tensor '((0 0 1) (0 1 1) (1 0 1) (1 1 1))))
       (Y (tensor '(0 1 1 0)))
       (lr 1))
  (loop :for i :from 0 :below 1000
        :do (let* ((l1 ($sigmoid ($mm X w1)))
                   (l2 ($sigmoid ($mm l1 w2)))
                   (d ($sub l2 Y))
                   (out ($dot d d)))
              ($gs! out 1)
              ($gd! w1 lr)
              ($gd! w2 lr)))
  (prn ($sigmoid ($mm ($sigmoid ($mm X w1)) w2))))

(let* ((w1 (vxavier '(3 3)))
       (w2 (vxavier '(3 1)))
       (X (tensor '((0 0 1) (0 1 1) (1 0 1) (1 1 1))))
       (Y (tensor '(0 1 1 0)))
       (lr 1))
  (loop :for i :from 0 :below 1000
        :do (let* ((l1 ($sigmoid ($mm X w1)))
                   (l2 ($sigmoid ($mm l1 w2)))
                   (d ($sub l2 Y))
                   (out ($dot d d)))
              ($gs! out 1)
              ($gd! w1 lr)
              ($gd! w2 lr)))
  (prn ($sigmoid ($mm ($sigmoid ($mm X w1)) w2))))

(let* ((w1 ($parameter (rndn 3 3)))
       (w2 ($parameter (rndn 3 1)))
       (X (tensor '((0 0 1) (0 1 1) (1 0 1) (1 1 1))))
       (Y (tensor '(0 1 1 0)))
       (lr 1))
  (loop :for i :from 0 :below 1000
        :do (let* ((l1 ($sigmoid ($mm X w1)))
                   (l2 ($sigmoid ($mm l1 w2)))
                   (d ($sub l2 Y))
                   (out ($dot d d)))
              ($gs! out 1)
              ($mgd! w1 lr)
              ($mgd! w2 lr)))
  (prn ($sigmoid ($mm ($sigmoid ($mm X w1)) w2))))

(let* ((w1 ($parameter (rndn 3 3)))
       (w2 ($parameter (rndn 3 1)))
       (X (tensor '((0 0 1) (0 1 1) (1 0 1) (1 1 1))))
       (Y (tensor '(0 1 1 0)))
       (lr 1))
  (loop :for i :from 0 :below 1000
        :do (let* ((l1 ($sigmoid ($mm X w1)))
                   (l2 ($sigmoid ($mm l1 w2)))
                   (d ($sub l2 Y))
                   (out ($dot d d)))
              ($gs! out 1)
              ($agd! w1 lr)
              ($agd! w2 lr)))
  (prn ($sigmoid ($mm ($sigmoid ($mm X w1)) w2))))

(let* ((ps (parameters))
       (w1 ($parameter ps (rndn 3 3)))
       (w2 ($parameter ps (rndn 3 1)))
       (X (tensor '((0 0 1) (0 1 1) (1 0 1) (1 1 1))))
       (Y (tensor '(0 1 1 0)))
       (lr 0.01))
  (loop :for i :from 0 :below 1000
        :do (let* ((l1 ($sigmoid ($mm X w1)))
                   (l2 ($sigmoid ($mm l1 w2)))
                   (d ($sub l2 Y))
                   (out ($dot d d)))
              ($gs! out 1)
              ($amgd! ps lr)))
  (prn ($sigmoid ($mm ($sigmoid ($mm X w1)) w2))))

(let* ((w1 ($parameter (rndn 3 3)))
       (w2 ($parameter (rndn 3 1)))
       (X (tensor '((0 0 1) (0 1 1) (1 0 1) (1 1 1))))
       (Y (tensor '(0 1 1 0)))
       (lr 0.1))
  (loop :for i :from 0 :below 1000
        :do (let* ((l1 ($sigmoid ($mm X w1)))
                   (l2 ($sigmoid ($mm l1 w2)))
                   (d ($sub l2 Y))
                   (out ($dot d d)))
              ($gs! out 1)
              ($rmgd! w1 lr)
              ($rmgd! w2 lr)))
  (prn ($sigmoid ($mm ($sigmoid ($mm X w1)) w2))))

(let* ((w1 ($parameter (rndn 3 3)))
       (w2 ($parameter (rndn 3 1)))
       (X (tensor '((0 0 1) (0 1 1) (1 0 1) (1 1 1))))
       (Y (tensor '(0 1 1 0))))
  (loop :for i :from 0 :below 1000
        :do (let* ((l1 ($sigmoid ($mm X w1)))
                   (l2 ($sigmoid ($mm l1 w2)))
                   (d ($sub l2 Y))
                   (out ($dot d d)))
              ($gs! out 1)
              ($adgd! (list w1 w2))))
  (prn ($sigmoid ($mm ($sigmoid ($mm X w1)) w2))))
