;; Copyright (c) 2009, 2010 Vitaly Mayatskikh <v.mayatskih@gmail.com>
;;
;; This file is part of CL-ZMQ.
;;
;; Vitaly Mayatskikh grants you the rights to distribute
;; and use this software as governed by the terms
;; of the Lisp Lesser GNU Public License
;; (http://opensource.franz.com/preamble.html),
;; known as the LLGPL.

(in-package :zeromq)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  0MQ errors.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defconstant hausnumero 156384712)

;;  Native 0MQ error codes.
(defconstant emthread (+ hausnumero 50))
(defconstant efsm (+ hausnumero 51))
(defconstant enocompatproto (+ hausnumero 52))

(defcfun ("zmq_strerror" %strerror) :pointer
  (errnum       :int))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  0MQ message definition.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defconstant max-vsm-size 30)

;;  Message types. These integers may be stored in 'content' member of the
;;  message instead of regular pointer to the data.
(defconstant delimiter 31)
(defconstant vsm 32)

;; Message flags. ZMQ_MSG_SHARED is strictly speaking not a message flag
;; (it has no equivalent in the wire format), however, making  it a flag
;; allows us to pack the stucture tigher and thus improve performance.
(defconstant msg-more 1)
(defconstant msg-shared 128)

(defcstruct (msg)
  (content      :pointer)
  (shared       :uchar)
  (vsm-size     :uchar)
  (vsm-data     :uchar :count 30))      ;; FIXME max-vsm-size

(defcfun ("zmq_msg_init" msg-init) :int
  (msg  msg))

(defcfun* ("zmq_msg_init_size" %msg-init-size) :int
  (msg  msg)
  (size :long))

(defcallback zmq-free :void ((ptr :pointer) (hint :pointer))
  (declare (ignorable hint))
  (foreign-free ptr))

(defcfun ("zmq_msg_init_data" msg-init-data) :int
  (msg  msg)
  (data :pointer)
  (size :long)
  (ffn  :pointer)                       ; zmq_free_fn
  (hint :pointer))

(defcfun* ("zmq_msg_close" %msg-close) :int
  (msg  msg))

(defcfun ("zmq_msg_move" %msg-move) :int
  (dest msg)
  (src  msg))

(defcfun ("zmq_msg_copy" %msg-copy) :int
  (dest msg)
  (src  msg))

(defcfun ("zmq_msg_data" %msg-data) :pointer
  (msg  msg))

(defcfun ("zmq_msg_size" %msg-size) :int
  (msg  msg))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  0MQ infrastructure (a.k.a. context) initialisation & termination.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcfun* ("zmq_init" init) :pointer
  (io-threads   :int))

(defcfun ("zmq_term" term) :int
  (context      :pointer))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  0MQ socket definition.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; socket types.
(defconstant pair 0)
(defconstant pub 1)
(defconstant sub 2)
(defconstant req 3)
(defconstant rep 4)
(defconstant dealer 5)
(defconstant router 6)
(defconstant pull 7)
(defconstant push 8)
(defconstant xreq dealer)     ; old alias
(defconstant xrep router)     ; old alias
(defconstant upstream pull)   ; old alias
(defconstant downstream push) ; old alias

;; socket options
(defconstant hwm 1)
(defconstant swap 3)
(defconstant affinity 4)
(defconstant identity 5)
(defconstant subscribe 6)
(defconstant unsubscribe 7)
(defconstant rate 8)
(defconstant recovery-ivl 9)
(defconstant mcast-loop 10)
(defconstant sndbuf 11)
(defconstant rcvbuf 12)
(defconstant rcvmore 13)
;; LRH2011-06-04: Can't define constants fd, type and events as
;; they conflict with CFFI and/or other code here.
(defconstant zfd 14)
(defconstant zevents 15)
(defconstant ztype 16)
(defconstant linger 17)
(defconstant reconnect-ivl 18)
(defconstant backlog 19)
(defconstant recovery-ivl-msec 20)
(defconstant reconnect-ivl-max 21)

;; send/recv options.
(defconstant noblock 1)
(defconstant sndmore 2)

(defcfun* ("zmq_socket" socket) :pointer
  (context      :pointer)
  (type         :int))

(defcfun ("zmq_close" close) :int
  (s    :pointer))

(defcfun* ("zmq_setsockopt" %setsockopt) :int
  (s            :pointer)
  (option       :int)
  (optval       :pointer)
  (optvallen    :long))

(defcfun* ("zmq_getsockopt" %getsockopt) :int
  (s            :pointer)
  (option       :int)
  (optval       :pointer)
  (optvallen    :pointer))

(defcfun* ("zmq_bind" %bind) :int
  (s    :pointer)
  (addr :pointer :char))

(defcfun* ("zmq_connect" %connect) :int
  (s    :pointer)
  (addr :pointer :char))


(defcfun* ("zmq_send" %send) :int
  (s            :pointer)
  (msg          msg)
  :optional
  (flags        :int))

(defcfun* ("zmq_recv" %recv) :int
  (s            :pointer)
  (msg          msg)
  :optional
  (flags        :int))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  I/O multiplexing.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defconstant pollin 1)
(defconstant pollout 2)
(defconstant pollerr 4)

(defcstruct pollitem
  (socket       :pointer)
  (fd           :int)
  (events       :short)
  (revents      :short))

(defcfun ("zmq_poll" %poll) :int
  (items        :pointer)
  (nitems       :int)
  (timeout      :long))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Helper functions.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcfun ("zmq_version" %version) :void
  (major        :pointer)
  (minor        :pointer)
  (patch        :pointer))

(defcfun ("zmq_errno" errno) :int)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Devices
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defconstant streamer 1)
(defconstant forwarder 2)
(defconstant queue 3)

(defcfun* ("zmq_device" %device) :int
  (device       :int)
  (insocket     :pointer)
  (outsocket    :pointer))
