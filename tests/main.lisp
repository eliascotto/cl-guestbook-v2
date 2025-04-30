(defpackage guestbook/tests/main
  (:use :cl
        :guestbook
        :rove))
(in-package :guestbook/tests/main)

;; NOTE: To run this test file, execute `(asdf:test-system :guestbook)' in your Lisp.

(deftest test-target-1
  (testing "should (= 1 1) to be true"
    (ok (= 1 1))))
