;;; docker-tramp-test.el --- docker-tramp.el: Unit test suite -*- lexical-binding: t -*-

;; Copyright (C) 2015 Mario Rodas <marsam@users.noreply.github.com>

;; Author: Mario Rodas <marsam@users.noreply.github.com>
;; URL: https://github.com/emacs-pe/docker-tramp.el
;; Keywords: convenience
;; Version: 0.1
;; Package-Requires: ((emacs "24") (cl-lib "0.5"))

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; The unit test suite of docker

;;; Code:

(require 'docker-tramp)
(require 'undercover nil t)

(when (fboundp 'undercover)
  (undercover "docker-tramp.el"))

(ert-deftest docker-tramp-basic-test ()
  (should (equal 1 1)))

(provide 'docker-tramp-test)

;;; docker-tramp-test.el ends here
