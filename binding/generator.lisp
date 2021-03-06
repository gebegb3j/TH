(declaim (optimize (speed 3) (debug 1) (safety 0)))

(in-package :th)

(defmethod $copy! ((generator generator) from)
  (let ((gen (make-instance 'generator))
        (h (th-generator-copy ($handle generator)
                              ($handle from))))
    (setf ($handle gen) h)
    #+sbcl (sb-ext:finalize gen (lambda () (th-generator-free h)))
    gen))

(defmethod $seed ((generator generator)) (th-random-seed ($handle generator)))
(defmethod (setf $seed) (seed (generator generator))
  (th-random-manual-seed ($handle generator) (coerce seed 'integer))
  seed)

(defmethod $random ((generator generator))  (th-random-random ($handle generator)))

(defmethod $uniform ((generator generator) a b)
  (th-random-uniform ($handle generator)
                     (coerce a 'double-float)
                     (coerce b 'double-float)))

(defmethod $normal ((generator generator) mean stdev)
  (th-random-normal ($handle generator)
                    (coerce mean 'double-float)
                    (coerce stdev 'double-float)))

(defmethod $exponential ((generator generator) lam)
  (th-random-exponential ($handle generator)
                         (coerce lam 'double-float)))

(defmethod $cauchy ((generator generator) median sigma)
  (th-random-cauchy ($handle generator)
                    (coerce median 'double-float)
                    (coerce sigma 'double-float)))

(defmethod $lognormal ((generator generator) mean stdev)
  (th-random-log-normal ($handle generator)
                        (coerce mean 'double-float)
                        (coerce stdev 'double-float)))

(defmethod $geometric ((generator generator) p)
  (th-random-geometric ($handle generator)
                       (coerce p 'double-float)))

(defmethod $bernoulli ((generator generator) p)
  (th-random-bernoulli ($handle generator)
                       (coerce p 'double-float)))
