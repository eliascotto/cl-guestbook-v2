;;;; flashcl.lisp - A tiny helper layer inspired by Flask for Caveman2/Mito
;;;; Loads dependencies, provides shorter aliases and macros.

(in-package :cl-user)
(defpackage :flashcl
  (:use #:cl)
  (:import-from #:caveman2
                #:defroute
                #:redirect
                #:*request*
                #:*response*)
  (:import-from #:lack.request
                #:request-parameters)
  (:import-from #:mito
                #:dao-table-class ; Re-export metaclass for use in defmodel
                #:connect-toplevel
                #:ensure-table-exists
                #:select-dao
                #:find-dao
                #:delete-dao
                #:insert-dao)
  (:export ;; Setup
          #:init-flashcl
          ;; App Definition
          #:flashcl-app ;; Variable holding the app instance
          #:defmodel
          ;; Routing & Request/Response
          #:defroute
          #:form-param
          #:render ;; Re-export caveman's render (or wrap it)
          #:redirect ;; Re-export caveman's redirect
          ;; Database
          #:db-all
          #:db-add
          #:db-find
          #:db-delete
          #:dao-table-class ;; Re-export metaclass
          ;; Running
          #:run-app
          #:stop-app))
(in-package :flashcl)

;; --- Global State ---
(defvar flashcl-app nil "Holds the Caveman2 application instance.")

(defvar *database-path* nil "Path to the SQLite database file.")

;; --- Utils ---
(defun get-absolute-path (relative-path)
  "Returns the absolute path for a given relative path."
  (let ((parent-path (uiop:pathname-parent-directory-pathname (uiop:getcwd))))
    (uiop:ensure-directory-pathname (merge-pathnames parent-path relative-path))))

;; --- Setup ---
(defun init-flashcl (db-type db-path &optional
                                       (template-dir "templates")
                                       (static-dir "static"))
  "Initializes Flashcl environment. Sets DB/Template paths, connects DB."
  (setf *database-path* (get-absolute-path db-path))
  (setf *static-directory* (get-absolute-path static-dir))

  ;; Set Djula's template directory
  (djula:add-template-directory (get-absolute-path template-dir))
  (format t "Set template directory as ~A~%" (get-absolute-path template-dir))

  ;; Connect to SQLite database
  (handler-case (connect-toplevel db-type :database-name *database-path*)
    (error (c)
      (format *error-output* "~&Error connecting to database ~A: ~A~%" *database-path* c)
      ;; Optionally re-signal or handle differently
      ))

  ;; Define the Caveman2 app instance here
  (setf flashcl-app (make-instance 'caveman2:<app>)))

;; --- Template Rendering ---
(defparameter *template-registry* (make-hash-table :test 'equal))

(defun render (template-path &optional env)
  "Renders a Djula template from TEMPLATE-PATH, caching it for reuse.
ENV is an optional plist of variables passed to the template."
  (let ((template (gethash template-path *template-registry*)))
    (unless template
      ;; If the template is not already compiled, it is compiled, and stored in *TEMPLATE-REGISTRY*.
      (setf template (djula:compile-template* (princ-to-string template-path)))
      (setf (gethash template-path *template-registry*) template))
    (apply #'djula:render-template*
           template nil
           env)))

;; --- Model Definition ---
(defmacro defmodel (name slots &rest options)
  "Defines a Mito DAO class and ensures its table exists.
   Example: (flashcl:defmodel comment
              ((name :col-type (:varchar 20))
               (comment :col-type :text)))"
  (let ((class-options options)
        (table-name (intern (format nil "~aS" (string-downcase name)) *package*))) ; Basic pluralization

    ;; Add table name inference if not present
    (unless (find :table-name options :key #'car)
      (push `(:table-name ,(string-downcase table-name)) class-options))

    `(progn
      (defclass ,name ()
        ,slots
        (:metaclass mito:dao-table-class)
        ,@class-options)
      ;; Ensure table exists after class definition
      ;; Note: This runs at compile/load time when defmodel is processed.
      ;; Ensure DB is connected before loading code using defmodel.
      (handler-case (ensure-table-exists ',name)
        (error (c)
          (format *error-output* "~&Warning: Could not ensure table for ~A (DB might not be connected yet?): ~A~%" ',name c)))
      ;; Return the class name
      ',name)))

;; --- Request/Response Helpers ---
(defun form-param (name)
  "Gets a parameter from the request's form data (POST body)."
  (cdr (assoc name (request-parameters *request*) :test #'string=)))

(defun body-params ()
  "Gets the body parameters from the request."
  (request-parameters *request*))

;; We can re-export caveman2:render and redirect, or wrap them if needed.
;; Re-exporting is simpler. Caveman2's render already handles paths well.

;; --- Database Helpers ---
(defun db-all (class-name)
  "Selects all records for the given model class."
  (select-dao class-name))

(defun db-find (class-name id)
  "Finds a model instance by ID."
  (find-dao class-name :id id))

(defun db-add (instance)
  "Inserts a model instance into the database."
  (insert-dao instance))

(defun db-delete (instance)
  "Deletes a model instance from the database."
  (delete-dao instance))

;; --- Running the App ---
(defvar *app-instance* nil "Holds the Caveman2 application instance.")

(defun run-app (&rest args
                &key  (server :hunchentoot)
                      (port 5432)
                      (debug t)
                      (static-dir *static-directory*))
  "Starts the Clack server for the defined flashcl-app."
  (unless flashcl-app
    (error "Flashcl app not initialized. Call (flashcl:init-flashcl ...) first."))

  ;; Ensure the server is not already running
  (unless (null *app-instance*)
    (restart-case (error "Server is already running.")
      (restart-server ()
        :report "Restart the server."
        (stop-app))))

  ;; Ensure DB connection exists before starting server
  (handler-case (connect-toplevel :sqlite3 :database-name *database-path*)
    (error (c)
      (format *error-output* "~&Error connecting to database: ~A~%" c)))

  (format t "~&Starting Flashcl server on http://localhost:~a/~%" port)
  (let ((app (lack:builder
              (:static
               :path (lambda (path)
                       (if (ppcre:scan "^(?:/images/|/css/|/js/|/robot\\.txt$|/favicon\\.ico$)" path)
                           path
                           nil))
               :root static-dir)
              flashcl-app)))
    (setf *app-instance* 
      (apply #'clack:clackup app
             :server server
             :port port
             :debug debug
             args))))

(defun stop-app ()
  "Stops the Clack server for the defined flashcl-app."
  (when *app-instance*
    (clack:stop *app-instance*)
    (setf *app-instance* nil)))
