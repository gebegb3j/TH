(defpackage :mnist-bn
  (:use #:common-lisp
        #:mu
        #:th
        #:th.db.mnist))

(in-package :mnist-bn)

(defparameter *mnist* (read-mnist-data))

(defparameter *x-train* ($index ($ *mnist* :train-images) 0 (xrange 0 1000)))
(defparameter *y-train* ($index ($ *mnist* :train-labels) 0 (xrange 0 1000)))

(defparameter *x-batches*
  (loop :for i :from 0 :below 10
        :for rng = (loop :for k :from (* i 100) :below (* (1+ i) 100)
                         :collect k)
        :collect ($contiguous! ($index *x-train* 0 rng))))
(defparameter *y-batches*
  (loop :for i :from 0 :below 10
        :for rng = (loop :for k :from (* i 100) :below (* (1+ i) 100)
                         :collect k)
        :collect ($contiguous! ($index *y-train* 0 rng))))

(defparameter *w01* ($parameter (-> (tensor 784 100)
                                    ($uniform! 0 0.01))))
(defparameter *b01* ($parameter (zeros 100)))
(defparameter *w02* ($parameter (-> (tensor 100 100)
                                    ($uniform! 0 0.01))))
(defparameter *b02* ($parameter (zeros 100)))
(defparameter *w03* ($parameter (-> (tensor 100 100)
                                    ($uniform! 0 0.01))))
(defparameter *b03* ($parameter (zeros 100)))
(defparameter *w04* ($parameter (-> (tensor 100 100)
                                    ($uniform! 0 0.01))))
(defparameter *b04* ($parameter (zeros 100)))
(defparameter *w05* ($parameter (-> (tensor 100 100)
                                    ($uniform! 0 0.01))))
(defparameter *b05* ($parameter (zeros 100)))
(defparameter *w06* ($parameter (-> (tensor 100 10)
                                    ($uniform! 0 0.01))))
(defparameter *b06* ($parameter (zeros 10)))

(defparameter *p01* (list *w01* *b01* *w02* *b02* *w03* *b03*
                          *w04* *b04* *w05* *b05* *w06* *b06*))

(defparameter *w11* ($parameter (-> (tensor 784 100)
                                    ($uniform! 0 0.01))))
(defparameter *b11* ($parameter (zeros 100)))
(defparameter *g11* ($parameter (-> (tensor 784)
                                    ($uniform! 0 1))))
(defparameter *e11* ($parameter (zeros 784)))
(defparameter *rm11* (zeros 784))
(defparameter *rv11* (ones 784))
(defparameter *sm11* (zeros 784))
(defparameter *sd11* (ones 784))
(defparameter *w12* ($parameter (-> (tensor 100 100)
                                    ($uniform! 0 0.01))))
(defparameter *b12* ($parameter (zeros 100)))
(defparameter *g12* ($parameter (-> (tensor 100)
                                    ($uniform! 0 1))))
(defparameter *e12* ($parameter (zeros 100)))
(defparameter *rm12* (zeros 100))
(defparameter *rv12* (ones 100))
(defparameter *sm12* (zeros 100))
(defparameter *sd12* (ones 100))
(defparameter *w13* ($parameter (-> (tensor 100 100)
                                    ($uniform! 0 0.01))))
(defparameter *b13* ($parameter (zeros 100)))
(defparameter *g13* ($parameter (-> (tensor 100)
                                    ($uniform! 0 1))))
(defparameter *e13* ($parameter (zeros 100)))
(defparameter *rm13* (zeros 100))
(defparameter *rv13* (ones 100))
(defparameter *sm13* (zeros 100))
(defparameter *sd13* (ones 100))
(defparameter *w14* ($parameter (-> (tensor 100 100)
                                    ($uniform! 0 0.01))))
(defparameter *b14* ($parameter (zeros 100)))
(defparameter *g14* ($parameter (-> (tensor 100)
                                    ($uniform! 0 1))))
(defparameter *e14* ($parameter (zeros 100)))
(defparameter *rm14* (zeros 100))
(defparameter *rv14* (ones 100))
(defparameter *sm14* (zeros 100))
(defparameter *sd14* (ones 100))
(defparameter *w15* ($parameter (-> (tensor 100 100)
                                    ($uniform! 0 0.01))))
(defparameter *b15* ($parameter (zeros 100)))
(defparameter *g15* ($parameter (-> (tensor 100)
                                    ($uniform! 0 1))))
(defparameter *e15* ($parameter (zeros 100)))
(defparameter *rm15* (zeros 100))
(defparameter *rv15* (ones 100))
(defparameter *sm15* (zeros 100))
(defparameter *sd15* (ones 100))
(defparameter *w16* ($parameter (-> (tensor 100 10)
                                    ($uniform! 0 0.01))))
(defparameter *b16* ($parameter (zeros 10)))

(defparameter *p02* (list *w11* *b11* *w12* *b12* *w13* *b13*
                          *w14* *b14* *w15* *b15* *w16* *b16*
                          *g11* *e11* *g12* *e12* *g13* *e13*
                          *g14* *e14* *g15* *e15*))
(defparameter *a02* (list *rm11* *rv11* *sm11* *sd11*
                          *rm12* *rv12* *sm12* *sd12*
                          *rm13* *rv13* *sm13* *sd13*
                          *rm14* *rv14* *sm14* *sd14*
                          *rm15* *rv15* *sm15* *sd15*))

(defun single-step (params x)
  (let ((w1 ($ params 0))
        (b1 ($ params 1))
        (w2 ($ params 2))
        (b2 ($ params 3))
        (w3 ($ params 4))
        (b3 ($ params 5))
        (w4 ($ params 6))
        (b4 ($ params 7))
        (w5 ($ params 8))
        (b5 ($ params 9))
        (w6 ($ params 10))
        (b6 ($ params 11)))
    (-> x
        ($affine w1 b1)
        ($relu)
        ($affine w2 b2)
        ($relu)
        ($affine w3 b3)
        ($relu)
        ($affine w4 b4)
        ($relu)
        ($affine w5 b5)
        ($relu)
        ($affine w6 b6)
        ($softmax))))

(defun single-step-bn (params aps x)
  (let ((w1 ($ params 0))
        (b1 ($ params 1))
        (w2 ($ params 2))
        (b2 ($ params 3))
        (w3 ($ params 4))
        (b3 ($ params 5))
        (w4 ($ params 6))
        (b4 ($ params 7))
        (w5 ($ params 8))
        (b5 ($ params 9))
        (w6 ($ params 10))
        (b6 ($ params 11))
        (g1 ($ params 12))
        (e1 ($ params 13))
        (rm1 ($ aps 0))
        (rv1 ($ aps 1))
        (sm1 ($ aps 2))
        (sd1 ($ aps 3))
        (g2 ($ params 14))
        (e2 ($ params 15))
        (rm2 ($ aps 4))
        (rv2 ($ aps 5))
        (sm2 ($ aps 6))
        (sd2 ($ aps 7))
        (g3 ($ params 16))
        (e3 ($ params 17))
        (rm3 ($ aps 8))
        (rv3 ($ aps 9))
        (sm3 ($ aps 10))
        (sd3 ($ aps 11))
        (g4 ($ params 18))
        (e4 ($ params 19))
        (rm4 ($ aps 12))
        (rv4 ($ aps 13))
        (sm4 ($ aps 14))
        (sd4 ($ aps 15))
        (g5 ($ params 20))
        (e5 ($ params 21))
        (rm5 ($ aps 16))
        (rv5 ($ aps 17))
        (sm5 ($ aps 18))
        (sd5 ($ aps 19)))
    (-> x
        ($affine w1 b1)
        ($bn g1 e1 rm1 rv1 sm1 sd1)
        ($relu)
        ($affine w2 b2)
        ($bn g2 e2 rm2 rv2 sm2 sd2)
        ($relu)
        ($affine w3 b3)
        ($bn g3 e3 rm3 rv3 sm3 sd3)
        ($relu)
        ($affine w4 b4)
        ($bn g4 e4 rm4 rv4 sm4 sd4)
        ($relu)
        ($affine w5 b5)
        ($bn g5 e5 rm5 rv5 sm5 sd5)
        ($relu)
        ($affine w6 b6)
        ($softmax))))

($cg! *p01*)
(let ((y* (single-step *p01* *x-train*)))
  ($cee y* *y-train*)
  ($cg! *p01*))

($cg! *p02*)
(let ((y* (single-step-bn *p02* *a02* *x-train*)))
  ($cee y* *y-train*)
  ($cg! *p02*))

(progn
  ($cg! *p01*)
  (loop :for epoch :from 1 :to 100
        :do (loop :for xb :in *x-batches*
                  :for yb :in *y-batches*
                  :for i :from 0
                  :for y* = (single-step *p01* xb)
                  :for l = ($cee y* yb)
                  :do (progn
                        (when (and (zerop (rem epoch 100))
                                   (zerop i))
                          (prn (format nil "[~A] ~A" epoch l)))
                        ($adgd! *p01*)))))

(progn
  ($cg! *p02*)
  (loop :for epoch :from 1 :to 100
        :do (loop :for xb :in *x-batches*
                  :for yb :in *y-batches*
                  :for i :from 0
                  :for y* = (single-step-bn *p02* *a02* xb)
                  :for l = ($cee y* yb)
                  :do (progn
                        (when (and (zerop (rem epoch 100))
                                   (zerop i))
                          (prn (format nil "[~A] ~A" epoch l)))
                        ($adgd! *p02*)))))
