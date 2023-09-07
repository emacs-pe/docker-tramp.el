;;; docker-tramp.el --- TRAMP integration for docker containers for Emacs 28 and earlier -*- lexical-binding: t; -*-

;; Copyright (C) 2015 Mario Rodas <marsam@users.noreply.github.com>

;; Author: Mario Rodas <marsam@users.noreply.github.com>
;; URL: https://github.com/emacs-pe/docker-tramp.el
;; Keywords: docker, convenience
;; Version: 0.1.1
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
;;
;; `docker-tramp.el' offers a TRAMP method for Docker containers.
;;
;; > **NOTE**: `docker-tramp.el' relies in the `docker exec` command.  Tested
;; > with docker version 1.6.x but should work with versions >1.3.  Podman
;; > also works.
;;
;; > **NOTE**: [Similar functionality][] is built-in to Emacs from version 29
;; > onwards, so perhaps you don't need this package any more.
;;
;; ## Usage
;;
;; Offers the TRAMP method `docker` to access running containers
;;
;;     C-x C-f /docker:user@container:/path/to/file
;;
;;     where
;;       user           is the user that you want to use inside the container (optional)
;;       container      is the id or name of the container
;;
;; ### [Multi-hop][] examples
;;
;; If you container is hosted on `vm.example.net`:
;;
;;     /ssh:vm-user@vm.example.net|docker:user@container:/path/to/file
;;
;; If you need to run the `docker` command as, say, the `root` user:
;;
;;     /sudo:root@localhost|docker:user@container:/path/to/file
;;
;; ## Troubleshooting
;;
;; ### Tramp hangs on Alpine container
;;
;; Busyboxes built with the `ENABLE_FEATURE_EDITING_ASK_TERMINAL' config option
;; send also escape sequences, which `tramp-wait-for-output' doesn't ignores
;; correctly.  Tramp upstream fixed in [98a5112][] and is available since
;; Tramp>=2.3.
;;
;; For older versions of Tramp you can dump [docker-tramp-compat.el][] in your
;; `load-path' somewhere and add the following to your `init.el', which
;; overwrites `tramp-wait-for-output' with the patch applied:
;;
;;     (require 'docker-tramp-compat)
;;
;; ### Tramp does not respect remote `PATH'
;;
;; This is a known issue with Tramp, but is not a bug so much as a poor default
;; setting.  Adding `tramp-own-remote-path' to `tramp-remote-path' will make
;; Tramp use the remote's `PATH' environment varialbe.
;;
;;     (add-to-list 'tramp-remote-path 'tramp-own-remote-path)
;;
;; [Similar functionality]: https://www.gnu.org/software/tramp/#index-method-docker
;; [Multi-hop]: https://www.gnu.org/software/emacs/manual/html_node/tramp/Ad_002dhoc-multi_002dhops.html
;; [98a5112]: http://git.savannah.gnu.org/cgit/tramp.git/commit/?id=98a511248a9405848ed44de48a565b0b725af82c
;; [docker-tramp-compat.el]: https://github.com/emacs-pe/docker-tramp.el/raw/master/docker-tramp-compat.el

;;; Code:
(eval-when-compile (require 'cl-lib))

(require 'tramp)
(require 'tramp-cache)

(defgroup docker-tramp nil
  "TRAMP integration for Docker containers."
  :prefix "docker-tramp-"
  :group 'applications
  :link '(url-link :tag "Github" "https://github.com/emacs-pe/docker-tramp.el")
  :link '(emacs-commentary-link :tag "Commentary" "docker-tramp"))

(defcustom docker-tramp-docker-executable "docker"
  "Path to docker (or compatible) executable."
  :type '(choice
          (const "docker")
          (const "podman")
          (string))
  :group 'docker-tramp)

;;;###autoload
(defcustom docker-tramp-docker-options nil
  "List of docker options."
  :type '(repeat string)
  :group 'docker-tramp)

(defcustom docker-tramp-use-names nil
  "Whether use names instead of id."
  :type 'boolean
  :group 'docker-tramp)

;;;###autoload
(defconst docker-tramp-completion-function-alist
  '((docker-tramp--parse-running-containers  ""))
  "Default list of (FUNCTION FILE) pairs to be examined for docker method.")

;;;###autoload
(defconst docker-tramp-method "docker"
  "Method to connect docker containers.")

(defun docker-tramp--running-containers ()
  "Collect docker running containers.

Return a list of containers of the form: \(ID NAME\)"
  (cl-loop for line in (cdr (ignore-errors (apply #'process-lines docker-tramp-docker-executable (append docker-tramp-docker-options (list "ps")))))
           for info = (split-string line "[[:space:]]+" t)
           collect (cons (car info) (last info))))

(defun docker-tramp--parse-running-containers (&optional ignored)
  "Return a list of (user host) tuples.

TRAMP calls this function with a filename which is IGNORED.  The
user is an empty string because the docker TRAMP method uses bash
to connect to the default user containers."
  (cl-loop for (id name) in (docker-tramp--running-containers)
           collect (list "" (if docker-tramp-use-names name id))))

;;;###autoload
(defun docker-tramp-cleanup ()
  "Cleanup TRAMP cache for docker method."
  (interactive)
  (let ((containers (apply 'append (docker-tramp--running-containers))))
    (maphash (lambda (key _)
               (and (vectorp key)
                    (string-equal docker-tramp-method (tramp-file-name-method key))
                    (not (member (tramp-file-name-host key) containers))
                    (remhash key tramp-cache-data)))
             tramp-cache-data))
  (setq tramp-cache-data-changed t)
  (if (zerop (hash-table-count tramp-cache-data))
      (ignore-errors (delete-file tramp-persistency-file-name))
    (tramp-dump-connection-properties)))

;;;###autoload
(defun docker-tramp-add-method ()
  "Add docker tramp method."
  (add-to-list 'tramp-methods
               `(,docker-tramp-method
                 (tramp-login-program      ,docker-tramp-docker-executable)
                 (tramp-login-args         (,docker-tramp-docker-options ("exec" "-it") ("-u" "%u") ("%h") ("sh")))
                 (tramp-remote-shell       "/bin/sh")
                 (tramp-remote-shell-args  ("-i" "-c")))))

(defun docker-tramp--update-method ()
  "Update docker tramp method."
  (let (it)
    (while (setq it (assoc docker-tramp-method tramp-methods))
      (setq tramp-methods (delq it tramp-methods))))
  (docker-tramp-add-method))

;; Customization of `docker-tramp-docker-executable' updates `docker-tramp-method'
(put 'docker-tramp-docker-executable 'custom-set
     (lambda (sym val)
       (custom-set-default sym val)
       (docker-tramp--update-method)))

;;;###autoload
(eval-after-load 'tramp
  '(progn
     (docker-tramp-add-method)
     (tramp-set-completion-function docker-tramp-method docker-tramp-completion-function-alist)))

(provide 'docker-tramp)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; docker-tramp.el ends here
