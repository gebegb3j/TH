;; https://medium.com/@jonathan_hui/gan-dcgan-deep-convolutional-generative-adversarial-networks-df855c438f

(defpackage :dcgan2-layers
  (:use #:common-lisp
        #:mu
        #:th
        #:th.image
        #:th.layers
        #:th.db.mnist))

(in-package :dcgan2-layers)

(defun build-batches (batch-size batch-count)
  (let ((mnist (read-mnist-data)))
    (loop :for i :from 0 :below batch-count
          :for s = (* i batch-size)
          :for e = (* (1+ i) batch-size)
          :for r = (loop :for k :from s :below e :collect k)
          :collect ($contiguous! ($reshape! ($- ($* 2 ($index ($ mnist :train-images) 0 r)) 1)
                                            batch-size 1 28 28)))))

(defparameter *batch-size* 120)
(defparameter *batch-count* (/ 60000 *batch-size*))

(defparameter *mnist-batches* (build-batches *batch-size* *batch-count*))

(defparameter *latent-dim* 100)

(defparameter *generator* (sequential-layer
                           (reshape-layer *latent-dim* 1 1)
                           (full-convolution-2d-layer *latent-dim* 128 3 3
                                                      :weight-initializer :random-normal
                                                      :weight-initialization '(0 0.02)
                                                      :activation :selu)
                           (full-convolution-2d-layer 128 64 3 3
                                                      :stride-width 2 :stride-height 2
                                                      :weight-initializer :random-normal
                                                      :weight-initialization '(0 0.02)
                                                      :activation :selu)
                           (full-convolution-2d-layer 64 32 2 2
                                                      :stride-width 2 :stride-height 2
                                                      :weight-initializer :random-normal
                                                      :weight-initialization '(0 0.02)
                                                      :activation :selu)
                           (full-convolution-2d-layer 32 1 2 2
                                                      :stride-width 2 :stride-height 2
                                                      :weight-initializer :random-normal
                                                      :weight-initialization '(0 0.02)
                                                      :activation :tanh)))

(defparameter *discriminator* (sequential-layer
                               (convolution-2d-layer 1 64 4 4
                                                     :stride-width 2 :stride-height 2
                                                     :padding-width 1 :padding-height 1
                                                     :weight-initializer :random-normal
                                                     :weight-initialization '(0 0.02)
                                                     :activation :selu)
                               (convolution-2d-layer 64 32 4 4
                                                     :stride-width 2 :stride-height 2
                                                     :padding-width 1 :padding-height 1
                                                     :weight-initializer :random-normal
                                                     :weight-initialization '(0 0.02)
                                                     :activation :selu)
                               (convolution-2d-layer 32 16 4 4
                                                     :stride-width 2 :stride-height 2
                                                     :padding-width 1 :padding-height 1
                                                     :weight-initializer :random-normal
                                                     :weight-initialization '(0 0.02)
                                                     :activation :selu)
                               (convolution-2d-layer 16 1 3 3
                                                     :weight-initializer :random-normal
                                                     :weight-initialization '(0 0.02)
                                                     :activation :sigmoid)
                               (reshape-layer 1)))

(defparameter *lr* 1E-3)
(defparameter *real-labels* (ones *batch-size*))
(defparameter *fake-labels* (zeros *batch-size*))

(defun optim (model)
  ($amgd! model *lr* 0.5 0.999)
  ($cg! *generator*)
  ($cg! *discriminator*))

(defun generate (&key (trainp t))
  "generates fake images from random normal inputs"
  ($execute *generator* (rndn *batch-size* *latent-dim*) :trainp trainp))

(defun discriminate (xs &key (trainp t))
  "check whether inputs are real or fake"
  ($execute *discriminator* xs :trainp trainp))

(defun train-discriminator (xs &optional verbose)
  "teaching discriminator how to discriminate reals from fakes"
  (let* ((fake-scores (discriminate (generate)))
         (real-scores (discriminate xs))
         (fake-loss ($bce fake-scores *fake-labels*))
         (real-loss ($bce real-scores *real-labels*))
         (dloss ($+ fake-loss real-loss)))
    (when verbose (prn "  DL:" (if ($parameterp dloss) ($data dloss) dloss)))
    (optim *discriminator*)))

(defun train-generator (&optional verbose)
  "teaching generator how to create more real fakes"
  (let* ((fake-scores (discriminate (generate)))
         (gloss ($bce fake-scores *real-labels*)))
    (when verbose (prn "  GL:" (if ($parameterp gloss) ($data gloss) gloss)))
    (optim *generator*)))

(defun write-tensor-at (img x y tx)
  (let* ((h ($size tx 1))
         (w ($size tx 2))
         (sx (* x w))
         (sy (* y h)))
    (loop :for j :from 0 :below h
          :do (loop :for i :from 0 :below w
                    :for v = ($ tx 0 j i)
                    :for px = (round (* 255 (* 0.5 (1+ v))))
                    :do (setf (aref img (+ sy j) (+ sx i)) px)))))

(defun outpngs (data fname)
  (let* ((h ($size ($ data 0) 1))
         (w ($size ($ data 0) 2))
         (dn ($size data 0))
         (n (ceiling (sqrt dn)))
         (nc n)
         (nr (ceiling (/ dn n)))
         (img (opticl:make-8-bit-gray-image (* nr h) (* nc w))))
    (loop :for sy :from 0 :below nr
          :do (loop :for sx :from 0 :below nc
                    :for idx = (+ (* sy nr) sx)
                    :for tx = (when (< idx dn) ($ data idx))
                    :when tx
                      :do (write-tensor-at img sx sy tx)))
    (opticl:write-png-file fname img)))

(defun train (xs epoch idx)
  (let ((verbose (zerop (rem idx 50))))
    (when verbose (prn "EPOCH/IDX>" epoch ":" idx))
    (loop :for k :from 0 :below 1
          :do (train-discriminator xs verbose))
    (train-generator verbose)
    (when (zerop (rem idx 500))
      (let ((generated (generate :trainp nil))
            (fname (format nil "~A/Desktop/~A-~A.png" (namestring (user-homedir-pathname))
                           epoch idx)))
        (outpngs generated fname)))
    (when verbose (th::report-foreign-memory-allocation))))

(defparameter *epochs* 20)

($reset! *generator*)
($reset! *discriminator*)

(time
 (with-foreign-memory-limit ()
   (loop :for epoch :from 1 :to *epochs*
         :do (loop :for xs :in *mnist-batches*
                   :for idx :from 0
                   :do (train xs epoch idx)))))

(let ((generated (generate :trainp nil))
      (fname (format nil "~A/Desktop/images.png" (namestring (user-homedir-pathname)))))
  (outpngs generated fname))

(let ((xs (car *mnist-batches*))
      (fname (format nil "~A/Desktop/ixs.png" (namestring (user-homedir-pathname)))))
  (outpngs xs fname))

(gcf)
(setf *epochs* 1)
