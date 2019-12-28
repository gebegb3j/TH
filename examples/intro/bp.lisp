(defpackage th.ad-example
  (:use #:common-lisp
        #:mu
        #:th))

(in-package :th.ad-example)

;; broadcast
(let* ((x ($parameter 5))
       (y (tensor '(1 2 3)))
       (out ($broadcast x y)))
  ($gs! out (tensor '(1 2 3)))
  (prn ($gradient x)))

(let* ((a (tensor '(5 5 5)))
       (c ($parameter 5))
       (out ($broadcast c a)))
  ($gs! out)
  (prn out)
  (prn "3" ($gradient c)))

;; add
(let* ((a ($parameter (tensor '(1 1 1))))
       (b ($parameter (tensor '(1 1 1))))
       (out ($add a b)))
  ($gs! out (tensor '(1 2 3)))
  (prn ($gradient a))
  (prn ($gradient b)))

(let* ((a ($parameter '(1 1 1)))
       (b ($parameter '(1 1 1)))
       (out ($+ a b)))
  ($gs! out (tensor '(1 2 3)))
  (prn ($gradient a))
  (prn ($gradient b)))

;; sub
(let* ((x (tensor '(1 2 3)))
       (y ($parameter (tensor '(3 2 1))))
       (out ($sub x y)))
  ($gs! out (tensor '(1 1 1)))
  (prn ($gradient y)))

(let* ((x ($parameter '(1 2 3)))
       (y ($parameter '(3 2 1)))
       (out ($- x y)))
  ($gs! out (tensor '(1 1 1)))
  (prn ($gradient x))
  (prn ($gradient y)))

;; dot
(let* ((x ($parameter (tensor '(1 2 3))))
       (y (tensor '(1 2 3)))
       (out ($dot x y)))
  (prn out)
  (prn ($gradient x)))

;; update
(let* ((a (tensor '(1 1 1)))
       (b ($parameter (tensor '(1 2 3))))
       (out ($dot a b)))
  (prn out)
  ($gd! b)
  (prn b))

(let* ((a (tensor '(1 1 1)))
       (b ($parameter '(1 2 3)))
       (out ($@ a b)))
  (prn out)
  ($gd! b)
  (prn b))

;; mv
(let* ((X (tensor '((1) (3))))
       (b ($parameter '(10)))
       (out ($mv X b)))
  (prn out)
  (prn ($gradient b)))

(let* ((m ($parameter (tensor '((2 0) (0 2)))))
       (v (tensor '(2 3)))
       (out ($mv m v)))
  ($gs! out)
  (prn (tensor '((2.0 3.0) (2.0 3.0))))
  (prn ($gradient m)))

(let* ((a ($parameter '((1 1 1) (1 1 1))))
       (b ($parameter '((0.1) (0.1) (0.1))))
       (c ($mm a b)))
  ($gs! c)
  (prn ($gradient a))
  (prn ($gradient b)))

(let* ((a ($parameter '((1 1 1) (1 1 1))))
       (b ($parameter '((0.1) (0.1) (0.1))))
       (out ($sigmoid ($mm a b))))
  ($gs! out)
  (prn "2.44458...")
  (prn ($gradient a)))

;; update effect for sum
(let* ((x ($parameter '((1 2 3) (4 5 6) (7 8 9))))
       (y 40)
       (out ($sum x))
       (delta ($sub out y))
       (loss ($dot delta delta)))
  (prn out)
  (prn loss)
  ($gs! loss)
  (prn ($gradient x))
  ($gd! x 0.01)
  (prn x)
  (prn "decreased")
  (prn ($sum x)))

;; mean
(let* ((x ($parameter '((1 2 3) (4 5 6) (7 8 9))))
       (y 6)
       (out ($mean x)))
  (prn out)
  (loop :for i :from 1 :to 50
        :for y* = ($mean x)
        :for d = ($sub y* y)
        :for l = ($dot d d)
        :do (progn
              ($gs! l)
              ($gd! x 0.9)))
  (prn x)
  (prn "closer to 6")
  (prn ($mean x)))

;; max
(let* ((x ($parameter '((1 2) (3 4) (5 6))))
       (y 5)
       (out ($max x)))
  (prn out)
  (loop :for i :from 1 :to 50
        :for y* = ($max x)
        :for d = ($sub y* y)
        :for l = ($dot d d)
        :do (progn
              ($gs! l)
              ($gd! x 0.1)))
  (prn x)
  (prn "closer to 5")
  (prn ($max x)))

;; min
(let* ((x ($parameter '((1 2) (3 4) (5 6))))
       (y 5)
       (out ($min x)))
  (prn out)
  (loop :for i :from 1 :to 50
        :for y* = ($min x)
        :for d = ($sub y* y)
        :for l = ($dot d d)
        :do (progn
              ($gs! l)
              ($gd! x 0.5)))
  (prn x)
  (prn "closer to 5")
  (prn ($min x)))

;; reshape
(let* ((x ($parameter '((1 2) (3 4))))
       (a (tensor '(1 2 3 4)))
       (y 20)
       (out ($dot ($reshape x 1 4) a))
       (delta ($sub out y))
       (loss ($dot delta delta)))
  (prn out)
  (prn delta)
  (prn loss)
  ($gs! loss)
  (prn ($gradient x))
  (prn x)
  ($gd! x)
  (prn x)
  (prn "supposed to be decreased")
  (prn ($sub ($dot ($reshape x 1 4) a) y)))

;; with transpose
(let* ((x ($parameter '((1 2) (3 4))))
       (a (tensor '(1 2 3 4)))
       (y 20)
       (out ($dot ($reshape ($transpose x) 1 4) a))
       (delta ($sub out y))
       (loss ($dot delta delta)))
  (prn out)
  (prn loss)
  ($gs! loss)
  (prn ($gradient x))
  ($gd! x)
  (prn x)
  (prn ($dot ($reshape ($transpose x) 1 4) a))
  (loop :for i :from 1 :to 10
        :for y* = ($dot ($reshape ($transpose x) 1 4) a)
        :for d = ($sub y* y)
        :for l = ($dot d d)
        :do (progn
              ($gs! l)
              ($gd! x 0.01)))
  (prn x)
  (prn ($dot ($reshape ($transpose x) 1 4) a)))

;; from chainer ad example
(let* ((x ($parameter '(5)))
       (y ($+ ($expt x 2) ($* -2 x) 1))
       (y1 ($expt x 2))
       (y2 ($* -2 x))
       (y3 ($+ y1 y2 1)))
  (prn y)
  ($gs! y)
  (prn "DY/DX" ($gradient x))
  (prn y3)
  ($gs! y3)
  (prn "DY3/DX" ($gradient x)))

(let* ((x ($parameter '(5)))
       (z ($* -2 x))
       (y ($+ ($expt x 2) z 1)))
  (prn y)
  ($gs! y)
  (prn "DY/DX" ($gradient x)))

(let* ((x ($parameter '((1 2 3) (4 5 6))))
       (y ($+ ($expt x 2) ($* -2 x) 1)))
  (prn y)
  ($gs! y)
  (prn "DY/DX" ($gradient x)))

;; supports function
(defun muladd (x y z) ($+ ($* x y) z))

(let* ((x ($parameter ($- ($* 2 (rnd 3 2)) 1)))
       (y ($parameter ($- ($* 2 (rnd 3 2)) 1)))
       (z ($parameter ($- ($* 2 (rnd 3 2)) 1)))
       (r (muladd x y z)))
  (prn r)
  ($gs! r)
  (prn "X" x)
  (prn "Y" y)
  (prn "DR/DX=Y" ($gradient x))
  (prn "DR/DY=X" ($gradient y))
  (prn "DR/DZ=1" ($gradient z)))

;; linear mapping
(let* ((X (tensor '((1) (3))))
       (Y (tensor '(-10 -30)))
       (c ($parameter 0))
       (b ($parameter '(10))))
  (loop :for i :from 0 :below 2000
        :do (let* ((d ($sub ($add ($mv X b) ($broadcast c Y)) Y))
                   (out ($dot d d)))
              (when (zerop (mod i 100)) (prn (list i ($data out))))
              ($gd! c)
              ($gd! b)))
  (prn b))

(let* ((X (tensor '((1) (3))))
       (Y (tensor '(-10 -30)))
       (c ($parameter 0))
       (b ($parameter '(10))))
  (loop :for i :from 0 :below 2000
        :do (let* ((d ($- ($+ ($@ X b) ($broadcast c Y)) Y))
                   (out ($@ d d)))
              (when (zerop (mod i 100)) (prn (list i ($data out))))
              ($gd! c)
              ($gd! b)))
  (prn b))


(let* ((X ($transpose! (range 0 10)))
       (Y (range 0 10))
       (c ($parameter 0))
       (b ($parameter '(0)))
       (a 0.001))
  (loop :for i :from 0 :below 2000
        :do (let* ((Y* ($add ($mv X b) ($broadcast c Y)))
                   (d ($sub Y* Y))
                   (out ($dot d d)))
              (when (zerop (mod i 100)) (prn (list i ($data out))))
              ($gd! c a)
              ($gd! b a)))
  (prn b))

(let* ((X ($transpose! (range 0 10)))
       (Y (range 0 10))
       (c ($parameter 0))
       (b ($parameter '(0)))
       (a 0.001))
  (loop :for i :from 0 :below 2000
        :do (let* ((Y* ($+ ($@ X b) ($broadcast c Y)))
                   (d ($- Y* Y))
                   (out ($@ d d)))
              (when (zerop (mod i 100)) (prn (list i ($data out))))
              ($gd! c a)
              ($gd! b a)))
  (prn b))

(let* ((X (-> (tensor '((1 1 2)
                        (1 3 1)))
              ($transpose!)))
       (Y (tensor '(1 2 3)))
       (c ($parameter 0))
       (b ($parameter '(1 1)))
       (a 0.05))
  (loop :for i :from 0 :below 1000
        :do (let* ((d ($sub ($add ($mv X b) ($broadcast c Y)) Y))
                   (out ($dot d d)))
              (when (zerop (mod i 100)) (prn (list i ($data out))))
              ($gd! c a)
              ($gd! b a)))
  (prn b)
  (prn c))

(let* ((X (-> (tensor '((1 1 2)
                        (1 3 1)))
              ($transpose!)))
       (Y (tensor '(1 2 3)))
       (c ($parameter 0))
       (b ($parameter '(1 1)))
       (a 0.05))
  (loop :for i :from 0 :below 1000
        :do (let* ((d ($- ($+ ($@ X b) ($broadcast c Y)) Y))
                   (out ($@ d d)))
              (when (zerop (mod i 100)) (prn (list i ($data out))))
              ($gd! c a)
              ($gd! b a)))
  (prn b)
  (prn c))

;; regressions
(let* ((X (-> (tensor '(1 3))
              ($transpose!)))
       (Y (tensor '(-10 -30)))
       (c ($parameter 0))
       (b ($parameter (tensor '(10))))
       (a 0.02))
  (loop :for i :from 0 :below 1000
        :do (let* ((d ($sub ($add ($mv X b) ($broadcast c Y)) Y))
                   (out ($dot d d)))
              (when (zerop (mod i 100)) (prn ($data out)))
              ($gd! c a)
              ($gd! b a)))
  (prn b)
  (prn ($add ($mv X b) ($broadcast c Y))))

(let* ((X (-> (tensor '(1 3))
              ($transpose!)))
       (Y (tensor '(-10 -30)))
       (c ($parameter 0))
       (b ($parameter '(10)))
       (a 0.02))
  (loop :for i :from 0 :below 1000
        :do (let* ((d ($- ($+ ($@ X b) ($broadcast c Y)) Y))
                   (out ($@ d d)))
              (when (zerop (mod i 100)) (prn ($data out)))
              ($gd! c a)
              ($gd! b a)))
  (prn ($+ ($@ X b) ($broadcast c Y))))

(let* ((X (tensor '((5 2) (-1 0) (5 2))))
       (Y (tensor '(1 0 1)))
       (c ($parameter (tensor '(0 0 0))))
       (b ($parameter (tensor '(0 0))))
       (a 0.1))
  (loop :for i :from 0 :below 1000
        :do (let* ((Y* ($sigmoid ($add ($mv X b) c)))
                   (out ($bce Y* Y)))
              (when (zerop (mod i 100)) (prn ($data out)))
              ($gd! c a)
              ($gd! b a)))
  (prn ($sigmoid ($add ($mv X b) c))))

;; xor
(let* ((w1 ($parameter (rndn 2 3)))
       (w2 ($parameter (rndn 3 1)))
       (X (tensor '((0 0) (0 1) (1 0) (1 1))))
       (Y (tensor '(0 1 1 0)))
       (a 1.0))
  (loop :for i :from 0 :below 1000
        :do (let* ((l1 ($sigmoid ($mm X w1)))
                   (l2 ($sigmoid ($mm l1 w2)))
                   (d ($sub l2 Y))
                   (out ($dot d d)))
              (when (zerop (mod i 100)) (prn ($data out)))
              ($gd! w1 a)
              ($gd! w2 a)))
  (prn w1)
  (prn w2)
  (prn (let* ((l1 ($sigmoid ($mm X w1)))
              (l2 ($sigmoid ($mm l1 w2))))
         l2)))

(let* ((w1 ($parameter (rndn 2 3)))
       (w2 ($parameter (rndn 3 1)))
       (b1 ($parameter (zeros 3)))
       (b2 ($parameter (ones 1)))
       (o1 (ones 4))
       (o2 (ones 4))
       (X (tensor '((0 0) (0 1) (1 0) (1 1))))
       (Y (tensor '(0 1 1 0)))
       (a 1))
  (loop :for i :from 0 :below 1000
        :do (let* ((xw1 ($mm X w1))
                   (xwb1 ($add xw1 ($vv o1 b1)))
                   (l1 ($sigmoid xwb1))
                   (lw2 ($mm l1 w2))
                   (lwb2 ($add lw2 ($vv o2 b2)))
                   (l2 ($sigmoid lwb2))
                   (d ($sub l2 Y))
                   (out ($dot d d)))
              (when (zerop (mod i 100)) (prn ($data out)))
              ($gd! w1 a)
              ($gd! w2 a)
              ($gd! b1 a)
              ($gd! b2 a)))
  (prn w1)
  (prn b1)
  (prn w2)
  (prn (let* ((l1 ($sigmoid ($add ($mm X w1) ($vv o1 b1))))
              (l2 ($sigmoid ($add ($mm l1 w2) ($vv o2 b2)))))
         l2)))

(let* ((w1 ($parameter (rndn 2 3)))
       (w2 ($parameter (rndn 3 1)))
       (b1 ($parameter (ones 3)))
       (b2 ($parameter (ones 1)))
       (X (tensor '((0 0) (0 1) (1 0) (1 1))))
       (Y (tensor '(0 1 1 0)))
       (a 5))
  (loop :for i :from 0 :below 1000
        :do (let* ((l1 ($sigmoid ($xwpb X w1 b1)))
                   (l2 ($sigmoid ($xwpb l1 w2 b2)))
                   (d ($sub l2 Y))
                   (out ($dot d d)))
              (when (zerop (mod i 100)) (prn ($data out)))
              ($gd! w1 a)
              ($gd! w2 a)
              ($gd! b1 a)
              ($gd! b2 a)))
  (prn (let* ((l1 ($sigmoid ($xwpb X w1 b1)))
              (l2 ($sigmoid ($xwpb l1 w2 b2))))
         l2)))

(let* ((w1 ($parameter (rndn 2 3)))
       (w2 ($parameter (rndn 3 1)))
       (X (tensor '((0 0) (0 1) (1 0) (1 1))))
       (Y (tensor '(0 1 1 0)))
       (a 1))
  (loop :for i :from 0 :below 1000
        :do (let* ((l1 ($tanh ($mm X w1)))
                   (l2 ($sigmoid ($mm l1 w2)))
                   (d ($sub l2 Y))
                   (out ($dot d d)))
              (when (zerop (mod i 100)) (prn ($data out)))
              ($gd! w1 a)
              ($gd! w2 a)))
  (prn (let* ((l1 ($tanh ($mm X w1)))
              (l2 ($sigmoid ($mm l1 w2))))
         l2)))

(let* ((w1 ($parameter (rndn 2 3)))
       (w2 ($parameter (rndn 3 1)))
       (b1 ($parameter (ones 3)))
       (b2 ($parameter (ones 1)))
       (X (tensor '((0 0) (0 1) (1 0) (1 1))))
       (Y (tensor '(0 1 1 0)))
       (a 1))
  (loop :for i :from 0 :below 1000
        :do (let* ((l1 ($tanh ($xwpb X w1 b1)))
                   (l2 ($sigmoid ($xwpb l1 w2 b2)))
                   (d ($sub l2 Y))
                   (out ($dot d d)))
              (when (zerop (mod i 100)) (prn ($data out)))
              ($gd! w1 a)
              ($gd! w2 a)
              ($gd! b1 a)
              ($gd! b2 a)))
  (prn (let* ((l1 ($tanh ($xwpb X w1 b1)))
              (l2 ($sigmoid ($xwpb l1 w2 b2))))
         l2)))

(let* ((w1 ($parameter (rndn 2 3)))
       (w2 ($parameter (rndn 3 1)))
       (b1 ($parameter (ones 3)))
       (b2 ($parameter (ones 1)))
       (o1 (ones 4))
       (X (tensor '((0 0) (0 1) (1 0) (1 1))))
       (Y (tensor '(0 1 1 0)))
       (a 0.2))
  (loop :for i :from 0 :below 1000
        :do (let* ((l1 ($tanh ($xwpb X w1 b1 o1)))
                   (l2 ($sigmoid ($xwpb l1 w2 b2 o1)))
                   (d ($sub l2 Y))
                   (out ($dot d d)))
              (when (zerop (mod i 100)) (prn ($data out)))
              ($gd! w1 a)
              ($gd! w2 a)
              ($gd! b1 a)
              ($gd! b2 a)))
  (prn (let* ((l1 ($tanh ($xwpb X w1 b1)))
              (l2 ($sigmoid ($xwpb l1 w2 b2))))
         l2)))

;; momentum
(let* ((w1 ($parameter (rndn 2 3)))
       (w2 ($parameter (rndn 3 1)))
       (b1 ($parameter (ones 3)))
       (b2 ($parameter (ones 1)))
       (o1 (ones 4))
       (X (tensor '((0 0) (0 1) (1 0) (1 1))))
       (Y (tensor '(0 1 1 0)))
       (a 0.2))
  (loop :for i :from 0 :below 1000
        :do (let* ((l1 ($tanh ($xwpb X w1 b1 o1)))
                   (l2 ($sigmoid ($xwpb l1 w2 b2 o1)))
                   (d ($sub l2 Y))
                   (out ($dot d d)))
              (when (zerop (mod i 100)) (prn ($data out)))
              ($mgd! w1 a)
              ($mgd! w2 a)
              ($mgd! b1 a)
              ($mgd! b2 a)))
  (prn (let* ((l1 ($tanh ($xwpb X w1 b1)))
              (l2 ($sigmoid ($xwpb l1 w2 b2))))
         l2)))

(defun fwd (input weight) ($sigmoid! ($@ input weight)))
(defun dwb (delta output) ($* delta output ($- 1 output)))

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
  (prn (fwd (fwd X w1) w2)))

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
  (prn ($sigmoid ($mm ($sigmoid ($mm X w1)) w2))))