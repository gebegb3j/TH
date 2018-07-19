(defpackage :vanilla-lstm
  (:use #:common-lisp
        #:mu
        #:th))

(in-package :vanilla-lstm)

(defparameter *data-lines* (read-lines-from "data/tinyshakespeare.txt"))
(defparameter *data* (format nil "~{~A~^~%~}" *data-lines*))
(defparameter *chars* (remove-duplicates (coerce *data* 'list)))
(defparameter *data-size* ($count *data*))
(defparameter *vocab-size* ($count *chars*))

(defparameter *char-to-idx* (let ((ht #{}))
                              (loop :for i :from 0 :below *vocab-size*
                                    :for ch = ($ *chars* i)
                                    :do (setf ($ ht ch) i))
                              ht))
(defparameter *idx-to-char* *chars*)

(defparameter *hidden-size* 100)
(defparameter *sequence-length* 25)
(defparameter *learning-rate* 1E-1)
(defparameter *weight-sd* 0.1)
(defparameter *z-size* (+ *hidden-size* *vocab-size*))

(defun d$sigmoid (y) ($* y ($- 1 y)))
(defun d$tanh (y) ($- 1 ($* y y)))

(defparameter *wf* ($+ ($* (rndn *z-size* *hidden-size*) *weight-sd*) 0.5))
(defparameter *bf* (zeros 1 *hidden-size*))

(defparameter *wi* ($+ ($* (rndn *z-size* *hidden-size*) *weight-sd*) 0.5))
(defparameter *bi* (zeros 1 *hidden-size*))

(defparameter *wc* ($* (rndn *z-size* *hidden-size*) *weight-sd*))
(defparameter *bc* (zeros 1 *hidden-size*))

(defparameter *wo* ($+ ($* (rndn *z-size* *hidden-size*) *weight-sd*) 0.5))
(defparameter *bo* (zeros 1 *hidden-size*))

(defparameter *wv* ($+ ($* (rndn *hidden-size* *vocab-size*) *weight-sd*) 0.5))
(defparameter *bv* (zeros 1 *vocab-size*))

(defparameter *dwf* (zeros *z-size* *hidden-size*))
(defparameter *dbf* (zeros 1 *hidden-size*))

(defparameter *dwi* (zeros *z-size* *hidden-size*))
(defparameter *dbi* (zeros 1 *hidden-size*))

(defparameter *dwc* (zeros *z-size* *hidden-size*))
(defparameter *dbc* (zeros 1 *hidden-size*))

(defparameter *dwo* (zeros *z-size* *hidden-size*))
(defparameter *dbo* (zeros 1 *hidden-size*))

(defparameter *dwv* (zeros *hidden-size* *vocab-size*))
(defparameter *dbv* (zeros 1 *vocab-size*))

(defparameter *mdwf* (zeros *z-size* *hidden-size*))
(defparameter *mdbf* (zeros 1 *hidden-size*))

(defparameter *mdwi* (zeros *z-size* *hidden-size*))
(defparameter *mdbi* (zeros 1 *hidden-size*))

(defparameter *mdwc* (zeros *z-size* *hidden-size*))
(defparameter *mdbc* (zeros 1 *hidden-size*))

(defparameter *mdwo* (zeros *z-size* *hidden-size*))
(defparameter *mdbo* (zeros 1 *hidden-size*))

(defparameter *mdwv* (zeros *hidden-size* *vocab-size*))
(defparameter *mdbv* (zeros 1 *vocab-size*))

(defun zero-grads ()
  ($zero! *dwf*)
  ($zero! *dbf*)
  ($zero! *dwi*)
  ($zero! *dbi*)
  ($zero! *dwc*)
  ($zero! *dbc*)
  ($zero! *dwo*)
  ($zero! *dbo*)
  ($zero! *dwv*)
  ($zero! *dbv*))

(defun zero-ms ()
  ($zero! *mdwf*)
  ($zero! *mdbf*)
  ($zero! *mdwi*)
  ($zero! *mdbi*)
  ($zero! *mdwc*)
  ($zero! *mdbc*)
  ($zero! *mdwo*)
  ($zero! *mdbo*)
  ($zero! *mdwv*)
  ($zero! *mdbv*))

(defun choose (probs)
  (let ((choices (sort (loop :for i :from 0 :below ($size probs 1)
                             :collect (list i ($ probs 0 i)))
                       (lambda (a b) (> (cadr a) (cadr b))))))
    (labels ((make-ranges ()
               (loop :for (datum probability) :in choices
                     :sum (coerce probability 'double-float) :into total
                     :collect (list datum total)))
             (pick (ranges)
               (declare (optimize (speed 3) (safety 0) (debug 0)))
               (loop with random = (random 1D0)
                     for (datum below) of-type (t double-float) in ranges
                     when (< random below)
                       do (return datum))))
      (pick (make-ranges)))))

(defun sample (ph pc fidx len)
  (let ((xt (zeros 1 *vocab-size*))
        (indices (list fidx)))
    (setf ($ xt 0 fidx) 1)
    (loop :for i :from 0 :below len
          :for zt = ($cat ph xt 1)
          :for ft = ($sigmoid ($+ ($@ zt *wf*) *bf*))
          :for it = ($sigmoid ($+ ($@ zt *wi*) *bi*))
          :for cbt = ($tanh ($+ ($@ zt *wc*) *bc*))
          :for ct = ($+ ($* ft pc) ($* it cbt))
          :for ot = ($sigmoid ($+ ($@ zt *wo*) *bo*))
          :for ht = ($* ot ($tanh ct))
          :for vt = ($+ ($@ ht *wv*) *bv*)
          :for yt = ($softmax vt)
          :do (let ((nxt (zeros 1 *vocab-size*))
                    (choice (choose yt)))
                (setf ($ nxt 0 choice) 1)
                (setf ph ht)
                (setf pc ct)
                (setf xt nxt)
                (push choice indices)))
    (coerce (mapcar (lambda (i) ($ *idx-to-char* i)) (reverse indices)) 'string)))

(loop :for iter :from 1 :to 1
      :for n = 0
      :for upto = (max 1 (- *data-size* *sequence-length* 1))
      :for ph = (zeros 1 *hidden-size*)
      :for pc = (zeros 1 *hidden-size*)
      :for err = 0
      :do (progn
            (zero-ms)
            (loop :for p :from 0 :below upto :by *sequence-length*
                  :for input = (let ((m (zeros *sequence-length* *vocab-size*)))
                                 (loop :for i :from p :below (+ p *sequence-length*)
                                       :for ch = ($ *data* i)
                                       :do (setf ($ m (- i p) ($ *char-to-idx* ch)) 1))
                                 m)
                  :for target = (let ((m (zeros *sequence-length* *vocab-size*)))
                                  (loop :for i :from (1+ p) :below (+ p *sequence-length* 1)
                                        :for ch = ($ *data* i)
                                        :do (setf ($ m (- i p 1) ($ *char-to-idx* ch)) 1))
                                  m)
                  :do (let* ((dhn (zeros 1 *hidden-size*))
                             (dcn (zeros 1 *hidden-size*))
                             (hs (list ph))
                             (cs (list pc))
                             (os nil)
                             (ds nil)
                             (zs nil)
                             (is nil)
                             (fs nil)
                             (cbs nil)
                             (losses nil)
                             (tloss 0)
                             (hindices (loop :for k :from 0 :below ($size ph 1) :collect k)))
                        (loop :for i :from 0 :below (min 1 ($size input 0))
                              :for xt = ($index input 0 i)
                              :for zt = ($cat ph xt 1)
                              :for ft = ($sigmoid ($+ ($@ zt *wf*) *bf*))
                              :for it = ($sigmoid ($+ ($@ zt *wi*) *bi*))
                              :for cbt = ($tanh ($+ ($@ zt *wc*) *bc*))
                              :for ct = ($+ ($* ft pc) ($* it cbt))
                              :for ot = ($sigmoid ($+ ($@ zt *wo*) *bo*))
                              :for ht = ($* ot ($tanh ct))
                              :for vt = ($+ ($@ ht *wv*) *bv*)
                              :for yt = ($softmax vt)
                              :for y = ($index target 0 i)
                              :for l = ($cee yt y)
                              :for d = ($- yt y)
                              :do (progn
                                    (push ht hs)
                                    (push ct cs)
                                    (push ot os)
                                    (push zt zs)
                                    (push it is)
                                    (push ft fs)
                                    (push cbt cbs)
                                    (push l losses)
                                    (push d ds)
                                    (incf tloss l)))
                        (zero-grads)
                        (loop :for i :from 0 :below (min 1 ($size input 0))
                              :for dvt = ($ ds i)
                              :for ht = ($ hs i)
                              :for ct = ($ cs i)
                              :for pc = ($ cs (1+ i))
                              :for ot = ($ os i)
                              :for zt = ($ zs i)
                              :for cbt = ($ cbs i)
                              :for it = ($ is i)
                              :for ft = ($ fs i)
                              :do (let ((dht nil)
                                        (dot nil)
                                        (dct nil)
                                        (dcbt nil)
                                        (dit nil)
                                        (dft nil)
                                        (dzt nil))
                                    ($add! *dwv* ($@ ($transpose ht) dvt))
                                    ($add! *dbv* dvt)
                                    (setf dht ($@ dvt ($transpose *wv*)))
                                    (setf dht ($+ dht dhn))
                                    (setf dot ($* (d$sigmoid ot) dht ($tanh ct)))
                                    ($add! *dwo* ($@ ($transpose zt) dot))
                                    ($add! *dbo* dot)
                                    (setf dct ($+ dcn ($* dht ot (d$tanh ($tanh ct)))))
                                    (setf dcbt ($* (d$tanh cbt) dct it))
                                    ($add! *dwc* ($@ ($transpose zt) dcbt))
                                    ($add! *dbc* dcbt)
                                    (setf dit ($* (d$sigmoid it) dct cbt))
                                    ($add! *dwi* ($@ ($transpose zt) dit))
                                    ($add! *dbi* dit)
                                    (setf dft ($* (d$sigmoid ft) dct pc))
                                    ($add! *dwf* ($@ ($transpose zt) dft))
                                    ($add! *dbf* dft)
                                    (setf dzt ($+ ($@ dft ($transpose *wf*))
                                                  ($@ dit ($transpose *wi*))
                                                  ($@ dcbt ($transpose *wc*))
                                                  ($@ dot ($transpose *wo*))))
                                    (setf dhn ($index dzt 1 hindices))
                                    (setf dcn ($* ft dct))))
                        ($add! *mdwf* ($expt *dwf* 2))
                        ($axpy! (- *learning-rate*) ($div *dwf* ($sqrt ($+ *mdwf* 1E-8))) *wf*)
                        ($add! *mdbf* ($expt *dbf* 2))
                        ($axpy! (- *learning-rate*) ($div *dbf* ($sqrt ($+ *mdbf* 1E-8))) *bf*)
                        ($add! *mdwi* ($expt *dwi* 2))
                        ($axpy! (- *learning-rate*) ($div *dwi* ($sqrt ($+ *mdwi* 1E-8))) *wi*)
                        ($add! *mdbi* ($expt *dbi* 2))
                        ($axpy! (- *learning-rate*) ($div *dbi* ($sqrt ($+ *mdbi* 1E-8))) *bi*)
                        ($add! *mdwc* ($expt *dwc* 2))
                        ($axpy! (- *learning-rate*) ($div *dwc* ($sqrt ($+ *mdwc* 1E-8))) *wc*)
                        ($add! *mdbc* ($expt *dbc* 2))
                        ($axpy! (- *learning-rate*) ($div *dbc* ($sqrt ($+ *mdbc* 1E-8))) *bc*)
                        ($add! *mdwo* ($expt *dwo* 2))
                        ($axpy! (- *learning-rate*) ($div *dwo* ($sqrt ($+ *mdwo* 1E-8))) *wo*)
                        ($add! *mdbo* ($expt *dbo* 2))
                        ($axpy! (- *learning-rate*) ($div *dbo* ($sqrt ($+ *mdbo* 1E-8))) *bo*)
                        ($add! *mdwv* ($expt *dwv* 2))
                        ($axpy! (- *learning-rate*) ($div *dwv* ($sqrt ($+ *mdwv* 1E-8))) *wv*)
                        ($add! *mdbv* ($expt *dbv* 2))
                        ($axpy! (- *learning-rate*) ($div *dbv* ($sqrt ($+ *mdbv* 1E-8))) *bv*)
                        (setf err (+ (* 0.99 err) (* 0.01 tloss)))
                        (when (zerop (rem n 1000))
                          (prn "***" n err)
                          ;;(prn ">>" (subseq *data* p (+ p *sequence-length*)))
                          ;;(prn "==" (subseq *data* (1+ p) (+ p *sequence-length* 1)))
                          (prn "<<" (sample ($0 hs) ($0 cs) ($ *char-to-idx* ($ *data* p)) 100))
                          (gcf))
                        (incf n)))))
