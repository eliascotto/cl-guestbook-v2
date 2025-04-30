(in-package :cl-user)
(defpackage guestbook.core
  (:use :cl :flashcl))
(in-package :guestbook.core)

(init-flashcl :sqlite3 "guestbook.sqlite")

(defmodel message
  ((username :col-type (:varchar 50) :accessor message-username)
   (content  :col-type  :text        :accessor message-content)))

(defroute "/" ()
  (render #P"index.html" (list :messages (db-all 'message))))

(defroute ("/message" :method :POST) ()
  (let ((name (form-param "name"))
        (message (form-param "message")))
    (if (and name message (> (length name) 0) (> (length message) 0))
      (db-add (make-instance 'message :username name :content message))
      (format t "Missing body parameters: received ~A~%" (body-params))))
  (redirect "/"))

(defroute ("/message/delete/:id" :method :POST) (&key id)
  (if id
    (let ((id (ignore-errors (parse-integer id))))
      (when id
        (db-delete (db-find 'message id)))
      (format t "Missing id parameter.")))
  (redirect "/"))

;; --- Run the Application ---
;; Call run-app function from your REPL or add it here to run on load. Call stop-app to stop the server.
;;
;; Example: (guestook::run-app) or just (run-app) inside the package.
;; (run-app :port 5000 :server :hunchentoot)
