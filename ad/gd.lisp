(in-package :th)

(defgeneric $gd! (node &optional learning-rate) (:documentation "Executes gradient descent."))
(defgeneric $mgd! (node &optional learning-rate momentum) (:documentation "Executes momentum."))
(defgeneric $agd! (node &optional learning-rate) (:documentation "Executes adagrad."))
(defgeneric $amgd! (node &optional learning-rate β1 β2) (:documentation "Executes adam."))
(defgeneric $rmgd! (node &optional learning-rate decay-rate) (:documentation "Executes rmsprop."))
(defgeneric $adgd! (node &optional decay-rate) (:documentation "Executes adadelta."))

(defmethod $gd! ((object t) &optional (learning-rate 0.01)) (declare (ignore learning-rate)))

(defmethod $gd! ((node node) &optional (learning-rate 0.01))
  (let ((children ($children node)))
    (if children
        (loop :for c :in children :do ($gd! c learning-rate))
        (when ($gradientp node)
          (let ((data ($data node))
                (grv ($gradient node)))
            (cond ((null grv) nil)
                  ((numberp grv) (setf ($data node) (- data (* grv learning-rate))))
                  (t ($axpy! (- learning-rate) grv data)))
            (setf ($gradient node) nil))))
    node))

(defmethod $mgd! ((object t) &optional (learning-rate 0.01) (momentum 0.9))
  (declare (ignore learning-rate momentum)))

(defmethod $mgd! ((node node) &optional (learning-rate 0.01) (momentum 0.9))
  (let ((children ($children node)))
    (if children
        (loop :for c :in children :do ($mgd! c learning-rate momentum))
        (when ($gradientp node)
          (let ((data ($data node))
                (grv ($gradient node)))
            (cond ((null grv) nil)
                  ((numberp grv) (let ((v ($attr node :v 0)))
                                   (setf v (+ (* grv (- learning-rate)) (* v momentum)))
                                   (setf ($data node) (+ data v))
                                   (setf ($attr node :v) v)))
                  (t (let ((v ($attr node :v (apply #'zeros ($size grv)))))
                       (setf ($ ($attrs node) :v) ($axpy! (- learning-rate) grv ($mul! v momentum)))
                       ($axpy! 1 ($ ($attrs node) :v) data))))
            (setf ($gradient node) nil))))
    node))

(defmethod $agd! ((object t) &optional (learning-rate 0.01))
  (declare (ignore learning-rate)))

(defmethod $agd! ((node node) &optional (learning-rate 0.01))
  (let ((children ($children node)))
    (if children
        (loop :for c :in children :do ($agd! c learning-rate))
        (when ($gradientp node)
          (let ((data ($data node))
                (grv ($gradient node))
                (eps 1E-8))
            (cond ((null grv) nil)
                  ((numberp grv) (let ((h ($attr node :h 0)))
                                   (setf h (+ (* grv grv) h))
                                   (setf ($data node) (- data (* learning-rate
                                                                 (/ grv (+ (sqrt h) eps)))))
                                   (setf ($attr node :h) h)))
                  (t (let ((h ($attr node :h (apply #'zeros ($size grv)))))
                       ($axpy! 1 ($expt grv 2) h)
                       ($axpy! (- learning-rate) ($div grv ($add! ($sqrt h) eps)) data))))
            (setf ($gradient node) nil))))
    node))

(defmethod $amgd! ((object t) &optional (learning-rate 0.01) (β1 0.9) (β2 0.999))
  (declare (ignore learning-rate β1 β2)))

(defmethod $amgd! ((node node) &optional (learning-rate 0.01) (β1 0.9) (β2 0.999))
  (let ((children ($children node)))
    (if children
        (loop :for c :in children :do ($amgd! c learning-rate β1 β2))
        (when ($gradientp node)
          (let ((data ($data node))
                (grv ($gradient node)))
            (cond ((null grv) nil)
                  ((numberp grv) (let ((niter ($attr node :niteration 1))
                                       (m ($attr node :m 0))
                                       (v ($attr node :v 0)))
                                   (setf m (+ (* β1 m) (* (- 1 β1) grv)))
                                   (setf v (+ (* β1 v) (* (- 1 β1) (* grv grv))))
                                   (setf ($attr node :m) m)
                                   (setf ($attr node :v) v)
                                   (setf ($attr node :niteration) (1+ niter))
                                   (setf m (/ m (- 1 (expt β1 niter))))
                                   (setf v (/ v (- 1 (expt β2 niter))))
                                   (setf ($data node) (- data (/ (* learning-rate m)
                                                                 (+ (sqrt v) 1E-8))))))
                  (t (let ((niter ($attr node :niteration 1))
                           (m ($attr node :m (apply #'zeros ($size grv))))
                           (v ($attr node :v (apply #'zeros ($size grv))))
                           (clr 0))
                       (setf ($attr node :niteration) (1+ niter))
                       (setf clr (/ (* learning-rate (sqrt (- 1 (expt β2 niter))))
                                    (- 1 (expt β1 niter))))
                       ($axpy! (- 1 β1) ($sub grv m) m)
                       ($axpy! (- 1 β2) ($sub! ($expt grv 2) v) v)
                       ($axpy! (- clr) ($div m ($add! ($sqrt v) 1E-8)) data))))
            (setf ($gradient node) nil))))
    node))

(defmethod $rmgd! ((object t) &optional (learning-rate 0.001) (decay-rate 0.99))
  (declare (ignore learning-rate decay-rate)))

(defmethod $rmgd! ((node node) &optional (learning-rate 0.001) (decay-rate 0.99))
  (let ((children ($children node)))
    (if children
        (loop :for c :in children :do ($rmgd! c learning-rate))
        (when ($gradientp node)
          (let ((data ($data node))
                (grv ($gradient node))
                (eps 1E-8))
            (cond ((null grv) nil)
                  ((numberp grv) (let ((h ($attr node :h 0)))
                                   (setf h (* h decay-rate))
                                   (setf h (+ h (* (- 1 decay-rate) grv grv)))
                                   (setf ($attr node :h) h)
                                   (setf ($data node) (- data (/ (* learning-rate grv)
                                                                 (+ (sqrt h) eps))))))
                  (t (let ((h ($attr node :h (apply #'zeros ($size grv)))))
                       ($mul! h decay-rate)
                       ($axpy! (- 1 decay-rate) ($expt grv 2) h)
                       ($axpy! (- learning-rate) ($div grv ($add! ($sqrt h) eps)) data))))
            (setf ($gradient node) nil))))
    node))

(defmethod $adgd! ((object t) &optional (decay-rate 0.95)) (declare (ignore decay-rate)))

(defmethod $adgd! ((node node) &optional (decay-rate 0.95))
  (let ((children ($children node)))
    (if children
        (loop :for c :in children :do ($adgd! c decay-rate))
        (when ($gradientp node)
          (let ((data ($data node))
                (grv ($gradient node))
                (eps 1E-6))
            (cond ((null grv) nil)
                  ((numberp grv) (let ((h ($attr node :h 0))
                                       (d ($attr node :d 0)))
                                   (setf h (* h decay-rate))
                                   (setf h (+ h (* (- 1 decay-rate) grv grv)))
                                   (let ((delta (* grv (/ (sqrt (+ d eps))
                                                          (sqrt (+ h eps))))))
                                     (setf d (* d decay-rate))
                                     (setf d (+ d (* (- 1 decay-rate) (* delta delta))))
                                     (setf ($attr node :h) h)
                                     (setf ($attr node :d) d)
                                     (setf ($data node) (- data delta)))))
                  (t (let ((h ($attr node :h (apply #'zeros ($size grv))))
                           (d ($attr node :d (apply #'zeros ($size grv)))))
                       ($mul! h decay-rate)
                       ($axpy! (- 1 decay-rate) ($expt grv 2) h)
                       (let ((delta ($mul! ($sqrt! ($div! ($add d eps) ($add h eps))) grv)))
                         ($mul! d decay-rate)
                         ($axpy! (- 1 decay-rate) ($expt delta 2) d)
                         ($axpy! -1 delta data)))))
            (setf ($gradient node) nil))))
    node))
