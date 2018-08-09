;; from
;; https://wiseodd.github.io/techblog/2016/09/17/gan-tensorflow/

(ql:quickload :opticl)

(defpackage :gan-work
  (:use #:common-lisp
        #:mu
        #:th
        #:th.db.mnist))

(in-package :gan-work)

;; load mnist data, takes ~22 secs in macbook 2017
(defparameter *mnist* (read-mnist-data))

;; mnist data has following dataset
;; train-images, train-labels and test-images, test-labels
(print *mnist*)

;; training data - uses batches for performance
(defparameter *batch-size* 1000)
(defparameter *batch-count* (/ 60000 *batch-size*))

(defparameter *mnist-train-image-batches*
  (loop :for i :from 0 :below *batch-count*
        :for rng = (loop :for k :from (* i *batch-size*) :below (* (1+ i) *batch-size*)
                         :collect k)
        :collect ($contiguous! ($index ($ *mnist* :train-images) 0 rng))))

(defparameter *discriminator* (parameters))
(defparameter *generator* (parameters))

(defparameter *gen-size* 100)
(defparameter *hidden-size* 128)
(defparameter *img-size* (* 28 28))

;; discriminator network
(defparameter *dw1* ($parameter *discriminator* (vxavier (list *img-size* *hidden-size*))))
(defparameter *db1* ($parameter *discriminator* (zeros 1 *hidden-size*)))
(defparameter *dw2* ($parameter *discriminator* (vxavier (list *hidden-size* 1))))
(defparameter *db2* ($parameter *discriminator* (zeros 1 1)))

;; generator network
(defparameter *gw1* ($parameter *generator* (vxavier (list *gen-size* *hidden-size*))))
(defparameter *gb1* ($parameter *generator* (zeros 1 *hidden-size*)))
(defparameter *gw2* ($parameter *generator* (vxavier (list *hidden-size* *img-size*))))
(defparameter *gb2* ($parameter *generator* (zeros 1 *img-size*)))

(defparameter *os* (ones *batch-size* 1))

(defun generate (z)
  (let* ((gh1 ($tanh ($+ ($@ z *gw1*) ($@ ($constant *os*) *gb1*))))
         (glogprob ($+ ($@ gh1 *gw2*) ($@ ($constant *os*) *gb2*))))
    (th::tensor-clamp ($data glogprob) ($data glogprob) -50 50)
    ($sigmoid glogprob)))

(defun discriminate (x)
  (let* ((dh1 ($tanh ($+ ($@ x *dw1*) ($@ ($constant *os*) *db1*))))
         (dlogit ($+ ($@ dh1 *dw2*) ($@ ($constant *os*) *db2*))))
    (th::tensor-clamp ($data dlogit) ($data dlogit) -50 50)
    ($sigmoid dlogit)))

(defun samplez () ($constant ($ru! (tensor *batch-size* *gen-size*) -1 1)))

(defun outpng (data fname)
  (let ((img (opticl:make-8-bit-gray-image 28 28))
        (d ($reshape data 28 28)))
    (loop :for i :from 0 :below 28
          :do (loop :for j :from 0 :below 28
                    :do (progn
                          (setf (aref img i j) (round (* 255 ($ d i j)))))))
    (opticl:write-png-file fname img)))

(defparameter *eps* ($constant 1E-7))

(defun bced (dr df)
  ($+ ($bce dr ($constant ($* 0.9 ($one dr))))
      ($bce df ($constant ($zero df)))))

(defun bceg (df) ($bce df ($constant ($one df))))

(defun logd (dr df)
  ($neg ($mean ($+ ($log ($+ dr *eps*))
                   ($log ($+ ($- 1 df) *eps*))))))

(defun logg (df)
  ($neg ($mean ($log ($+ df *eps*)))))

(defun lossd (dr df) (logd dr df))
(defun lossg (df) (logg df))

(defparameter *epoch* 100)
(defparameter *k* 1)

($cg! *discriminator*)
($cg! *generator*)

(loop :for epoch :from 1 :to *epoch*
      :do (progn
            ($cg! *discriminator*)
            ($cg! *generator*)
            (loop :for data :in *mnist-train-image-batches*
                  :for bidx :from 0
                  :for x = ($constant data)
                  :for z = (samplez)
                  :do (progn
                        ;; discriminator
                        (dotimes (k *k*)
                          (let* ((dr (discriminate x))
                                 (g (generate z))
                                 (df (discriminate g)))
                            (lossd dr df)
                            ($adgd! *discriminator*)
                            ($cg! *discriminator*)
                            ($cg! *generator*)))
                        ;; generator
                        (let* ((g (generate z))
                               (df (discriminate g)))
                          (lossg df)
                          ($adgd! *generator*)
                          ($cg! *discriminator*)
                          ($cg! *generator*))))
            (let* ((x ($constant (car *mnist-train-image-batches*)))
                   (dr (discriminate x))
                   (z (samplez))
                   (g (generate z))
                   (df (discriminate g))
                   (ld (lossd dr df))
                   (lf (lossg df)))
              ($cg! *discriminator*)
              ($cg! *generator*)
              (prn "LOSS:" epoch ($data ld) ($data lf))
              (when (zerop (rem epoch 10))
                (loop :for i :from 1 :to 1
                      :for s = (random *batch-size*)
                      :for fname = (format nil "/Users/Sungjin/Desktop/i~A-~A.png" epoch i)
                      :do (outpng ($index ($data g) 0 s) fname))))
            (gcf)))