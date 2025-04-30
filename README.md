# Common Lisp Guestbook Demo V2

A simple guestbook web application written in Common Lisp. This project is a refactoring (V2) of [cl-guestbook](https://github.com/eliascotto/cl-guestbook) to make it more similar in structure and features to the original Flask inspiration.

Inspired by the [Flask Guestbook Demo](https://github.com/qarchli/flask-guest-book).

## Libraries Used

This project utilizes several Common Lisp libraries available via Quicklisp:

*   [Caveman2](https://github.com/fukamachi/caveman): Web framework.
*   [Djula](https://github.com/mmontone/djula): Template engine (Django templates port).
*   [Mito](https://github.com/fukamachi/mito): ORM library.
*   [cl-dbi](https://github.com/fukamachi/cl-dbi): Database interface (used by Mito).
*   [Clack](https://github.com/fukamachi/clack) / [Lack](https://github.com/fukamachi/lack): Web server abstraction layer.
*   [Alexandria](https://common-lisp.net/project/alexandria/): Utility library.
*   [cl-ppcre](https://edicl.github.io/cl-ppcre/): Portable Perl-compatible regular expressions.
*   [uiop](https://common-lisp.net/project/asdf/uiop.html): Utilities for Interaction with Operating System / Portability.
*   [cl-syntax-annot](https://github.com/fukamachi/cl-syntax-annot): Syntax annotations.

## Usage

1.  **Load Dependencies:** Ensure you have Quicklisp set up. Load the project dependencies:
    ```lisp
    (ql:quickload :guestbook)
    ```
2.  **Start the Server:** Start the Clack server (adjust port if needed):
    ```lisp
    (guestbook.core:start)
    ```
3.  **Access:** Open your web browser and navigate to `http://localhost:3210`.

## Author

* Elia Scotto

## Copyright

Copyright (c) 2025 Elia Scotto

## License

Licensed under the MIT License.
