(defsystem "guestbook"
  :version "0.0.1"
  :author "Elia Scotto"
  :license "MIT"
  :depends-on (:alexandria
               :uiop
               :cl-ppcre

               ;; for @export annotation
               :cl-syntax-annot

               ;; Web application protocols libraries
               :clack
               :lack

               ;; Web framework
               :caveman2

               ;; Template engine
               :djula
               
               ;; Database
               :mito
               :cl-dbi)
  :components ((:module "src"
                :components
                ((:file "flashcl")
                 (:file "core"))))
  :description ""
  :in-order-to ((test-op (test-op "guestbook/tests"))))

(defsystem "guestbook/tests"
  :author "Elia Scotto"
  :license "MIT"
  :depends-on ("guestbook"
               "rove")
  :components ((:module "tests"
                :components
                ((:file "main"))))
  :description "Test system for guestbook"
  :perform (test-op (op c) (symbol-call :rove :run c)))
