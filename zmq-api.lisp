(in-package :cl-zmq)

(defun bind (s address)
  (with-foreign-string (addr address)
    (%bind s addr)))

(defun connect (s address)
  (with-foreign-string (addr address)
    (%connect s addr)))

(defun make-message (&optional (data nil data-p) &key (size nil size-p))
  (let* ((msg (make-instance 'msg :finalizer #'msg-close))
	 (raw (msg-raw msg)))
    (when size-p
      (msg-init-size raw size))
    (when data-p
      (multiple-value-bind (ptr len)
	  (etypecase data
	    (string (let ((ptr (convert-to-foreign data :string)))
		      (values ptr (1+ (foreign-funcall "strlen" :pointer ptr :long)))))
	    (array (let* ((len (length data))
			  (ptr (foreign-alloc :uchar :count len)))
		     (dotimes (i len)
		       (setf (mem-aref ptr :uchar i) (aref data i)))
		     (values ptr len))))
	(msg-init-data raw ptr len (callback zmq-free))))
    msg))

(defmacro with-context ((context app-threads io-threads &optional flags) &body body)
  `(let ((,context (init ,app-threads ,io-threads (or ,flags 0))))
     ,@body
     (term ,context)))

(defmacro with-socket ((socket context type) &body body)
  `(let ((,socket (socket ,context ,type)))
     ,@body
     (close ,socket)))

(defmacro with-stopwatch (&body body)
  (let ((watch (gensym)))
    `(with-foreign-object (,watch :long 2)
       (setq ,watch (stopwatch-start))
       ,@body
       (stopwatch-stop ,watch))))

(defun msg-data-as-string (msg)
  (let ((data (%msg-data (msg-raw msg))))
    (unless (zerop (pointer-address data))
      (convert-from-foreign data :string))))

(defun msg-data-as-array (msg)
  (let ((data (%msg-data (msg-raw msg))))
    (unless (zerop (pointer-address data))
      (let* ((len (msg-size msg))
	     (arr (make-array len :element-type '(unsigned-byte))))
	(dotimes (i len)
	  (setf (aref arr i) (mem-aref data :uchar i)))
	arr))))

(defun send (s msg &optional flags)
  (%send s (msg-raw msg) (or flags 0)))

(defun recv (s msg &optional flags)
  (%recv s (msg-raw msg) (or flags 0)))

(defun msg-size (msg)
  (%msg-size (msg-raw msg)))

(defun msg-move (dst src)
  (%msg-move (msg-raw dst) (msg-raw src)))

(defun msg-copy (dst src)
  (%msg-copy (msg-raw dst) (msg-raw src)))

;
