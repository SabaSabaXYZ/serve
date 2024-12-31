(ql:quickload '(:hunchentoot :find-port))

(defvar *installation-file* "C:/bin/serve.exe" "The filepath to install to when running (make)")

(defmacro grab-argument (accessor transform default)
  (let ((name (gensym)))
    `(let ((,name (,accessor *posix-argv*)))
       (if ,name
           (,transform ,name)
           ,default))))

(defmacro validate (value message &body predicate)
  `(when (not ,@predicate)
     (format t ,message ,value)
     (exit)))

(defmacro die-on-error (&body body)
  `(handler-case ,@body
     (error (err)
       (format t "Error: ~a~%~%Usage: ~a [port] [root-directory]~%" err (grab-argument first identity *installation-file*))
       (exit))))

(defun wait-until-empty-line ()
  (loop for line = (read-line *standard-input* nil nil)
        while line
        until (zerop (length line))))

(defun main ()
  (die-on-error
    (let* ((port (grab-argument second parse-integer (find-port:find-port)))
           (document-root (grab-argument third identity "."))
           (parsed-document-root (probe-file document-root))
           (server (make-instance 'hunchentoot:easy-acceptor :port port :document-root parsed-document-root)))
      (validate port "Port ~a is not available~%" (find-port:port-open-p port))
      (validate document-root "Path ~a does not exist~%" parsed-document-root)
      (hunchentoot:start server)
      (format t "Server started on http://localhost:~a serving up '~a'~%Enter an empty line to exit.~%" port document-root)
      (wait-until-empty-line)
      (hunchentoot:stop server))))

(defun make (&key (executable-name *installation-file*) (source-file "serve.lisp"))
  "Compiles the current state into an executable"
  (progn
    (if source-file
        (load (compile-file source-file))
        nil)
    (save-lisp-and-die executable-name :toplevel #'main :executable t)))
