(declaim (optimize (speed 3) (debug 1) (safety 0)))

(in-package :th)

(defmacro define-storage-struct (typename datatype)
  (let ((storage-struct (intern (strcat "TH-" (string-upcase typename) "-STORAGE"))))
    `(cffi:defcstruct ,storage-struct
       (data (:pointer ,datatype))
       (size :long-long)
       (ref-count :int)
       (flag :char)
       (allocator (:pointer :void))
       (allocator-context (:pointer :void))
       (view (:pointer (:struct ,storage-struct))))))

(defmacro define-storage-struct-ptr (typename)
  (let ((storage-struct (intern (strcat "TH-" (string-upcase typename) "-STORAGE")))
        (storage-struct-ptr (intern (strcat "TH-" (string-upcase typename) "-STORAGE-PTR"))))
    `(cffi:defctype ,storage-struct-ptr (:pointer (:struct ,storage-struct)))))

(defmacro define-tensor-struct (typename)
  (let ((storage-struct (intern (strcat "TH-" (string-upcase typename) "-STORAGE")))
        (tensor-struct (intern (strcat "TH-" (string-upcase typename) "-TENSOR"))))
    `(cffi:defcstruct ,tensor-struct
       (size (:pointer :long))
       (stride (:pointer :long))
       (n-dimension :int)
       (storage (:pointer (:struct ,storage-struct)))
       (storage-offset :long-long)
       (ref-count :int)
       (flag :char))))

(defmacro define-tensor-struct-ptr (typename)
  (let ((tensor-struct (intern (strcat "TH-" (string-upcase typename) "-TENSOR")))
        (tensor-struct-ptr (intern (strcat "TH-" (string-upcase typename) "-TENSOR-PTR"))))
    `(cffi:defctype ,tensor-struct-ptr (:pointer (:struct ,tensor-struct)))))

(defmacro define-structs (typename datatype)
  `(progn
     (define-storage-struct ,typename ,datatype)
     (define-storage-struct-ptr ,typename)
     (define-tensor-struct ,typename)
     (define-tensor-struct-ptr ,typename)))

(defun tree-leaves%% (tree test result)
  (if tree
      (if (listp tree)
          (cons (tree-leaves%% (car tree) test result)
                (tree-leaves%% (cdr tree) test result))
          (if (funcall test tree)
              (funcall result tree)
              tree))))

(defmacro tree-leaves (tree test result)
  `(tree-leaves%% ,tree
                  (lambda (x) (declare (ignorable x)) ,test)
                  (lambda (x) (declare (ignorable x)) ,result)))

(defun make-defcfun-storage (fl prefix real acreal)
  (let* ((storageptr (intern (string-upcase (strcat "th-" (string-downcase prefix) "-storage-ptr"))))
         (realptr (list :pointer real))
         (acrealptr (list :pointer acreal))
         (ptrdiff-t :long-long)
         (size-t :long)
         (fd1 (tree-leaves fl (eq 'storageptr x) storageptr))
         (fd2 (tree-leaves fd1 (eq 'real x) real))
         (fd3 (tree-leaves fd2 (eq 'realptr x) realptr))
         (fd4 (tree-leaves fd3 (eq 'acreal x) acreal))
         (fd5 (tree-leaves fd4 (eq 'acrealptr x) acrealptr))
         (fd6 (tree-leaves fd5 (eq 'ptrdiff-t x) ptrdiff-t))
         (fd7 (tree-leaves fd6 (eq 'size-t x) size-t))
         (funcdata fd7)
         (cffiname (strcat "TH" prefix "Storage_" (car funcdata)))
         (lfname (string-upcase (strcat "th-" (string-downcase prefix)
                                        "-storage-" (string (cadr funcdata))))))
    (append (list 'cffi:defcfun (list cffiname (intern lfname)))
            (cddr funcdata))))

(defun make-defcfun-tensor (fl prefix real acreal)
  (let* ((storageptr (intern (string-upcase (strcat "th-" (string-downcase prefix) "-storage-ptr"))))
         (tensorptr (intern (string-upcase (strcat "th-" (string-downcase prefix) "-tensor-ptr"))))
         (realptr (list :pointer real))
         (acrealptr (list :pointer acreal))
         (ptrdiff-t :long-long)
         (size-t :long)
         (fd1 (tree-leaves fl (eq 'storageptr x) storageptr))
         (fd2 (tree-leaves fd1 (eq 'tensorptr x) tensorptr))
         (fd3 (tree-leaves fd2 (eq 'real x) real))
         (fd4 (tree-leaves fd3 (eq 'realptr x) realptr))
         (fd5 (tree-leaves fd4 (eq 'acreal x) acreal))
         (fd6 (tree-leaves fd5 (eq 'acrealptr x) acrealptr))
         (fd7 (tree-leaves fd6 (eq 'ptrdiff-t x) ptrdiff-t))
         (fd8 (tree-leaves fd7 (eq 'size-t x) size-t))
         (funcdata fd8)
         (cffiname (strcat "TH" prefix "Tensor_" (car funcdata)))
         (lfname (string-upcase (strcat "th-" (string-downcase prefix)
                                        "-tensor-" (string (cadr funcdata))))))
    (append (list 'cffi:defcfun (list cffiname (intern lfname)))
            (cddr funcdata))))

(defun make-defcfun-blas (fl prefix real acreal)
  (let* ((storageptr (intern (string-upcase (strcat "th-" (string-downcase prefix) "-storage-ptr"))))
         (tensorptr (intern (string-upcase (strcat "th-" (string-downcase prefix) "-tensor-ptr"))))
         (realptr (list :pointer real))
         (acrealptr (list :pointer acreal))
         (ptrdiff-t :long-long)
         (size-t :long)
         (fd1 (tree-leaves fl (eq 'storageptr x) storageptr))
         (fd2 (tree-leaves fd1 (eq 'tensorptr x) tensorptr))
         (fd3 (tree-leaves fd2 (eq 'real x) real))
         (fd4 (tree-leaves fd3 (eq 'realptr x) realptr))
         (fd5 (tree-leaves fd4 (eq 'acreal x) acreal))
         (fd6 (tree-leaves fd5 (eq 'acrealptr x) acrealptr))
         (fd7 (tree-leaves fd6 (eq 'ptrdiff-t x) ptrdiff-t))
         (fd8 (tree-leaves fd7 (eq 'size-t x) size-t))
         (funcdata fd8)
         (cffiname (strcat "TH" prefix "Blas_" (car funcdata)))
         (lfname (string-upcase (strcat "th-" (string-downcase prefix)
                                        "-blas-" (string (cadr funcdata))))))
    (append (list 'cffi:defcfun (list cffiname (intern lfname)))
            (cddr funcdata))))

(defun make-defcfun-lapack (fl prefix real acreal)
  (let* ((storageptr (intern (string-upcase (strcat "th-" (string-downcase prefix) "-storage-ptr"))))
         (tensorptr (intern (string-upcase (strcat "th-" (string-downcase prefix) "-tensor-ptr"))))
         (realptr (list :pointer real))
         (acrealptr (list :pointer acreal))
         (ptrdiff-t :long-long)
         (size-t :long)
         (fd1 (tree-leaves fl (eq 'storageptr x) storageptr))
         (fd2 (tree-leaves fd1 (eq 'tensorptr x) tensorptr))
         (fd3 (tree-leaves fd2 (eq 'real x) real))
         (fd4 (tree-leaves fd3 (eq 'realptr x) realptr))
         (fd5 (tree-leaves fd4 (eq 'acreal x) acreal))
         (fd6 (tree-leaves fd5 (eq 'acrealptr x) acrealptr))
         (fd7 (tree-leaves fd6 (eq 'ptrdiff-t x) ptrdiff-t))
         (fd8 (tree-leaves fd7 (eq 'size-t x) size-t))
         (funcdata fd8)
         (cffiname (strcat "TH" prefix "Lapack_" (car funcdata)))
         (lfname (string-upcase (strcat "th-" (string-downcase prefix)
                                        "-lapack-" (string (cadr funcdata))))))
    (append (list 'cffi:defcfun (list cffiname (intern lfname)))
            (cddr funcdata))))