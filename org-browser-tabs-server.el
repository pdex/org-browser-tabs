;; http://cask.github.io/why-cask.html
;; https://www.emacswiki.org/emacs/MakingPackages
;; http://tess.oconnor.cx/2006/03/json.el

(require 'web-server)
(require 'json)

(setq links '())
(setq server nil)

(defun stored-links-as-json (links)
  (let ((json-object-type 'alist)
	(json-array-type 'list)
	(json-key-type 'string))
    (json-encode links)))

(defun stored-links-count ()
  (json-encode (length links)))

(defun store-link (link) (setq links (append links (list link))))

(defun parse-message (message)
  (let ((json-object-type 'alist)
	(json-array-type 'list)
	(json-key-type 'string))
    (json-read-from-string message)))

(defun handle-message (message)
  ;;(store-link (parse-message message))
  (setq links (parse-message message))
  (message (concat "focused" (alist-get "focused" links))))

(defun get-from-headers (key headers)
  (alist-get 'content (cdr (assoc key headers))))

(defun handle-request (request)
  (with-slots (process headers) request
    (let ((message (cdr (assoc 'payload headers)))
	  (windows (get-from-headers "windows" headers))
	  (payload (get-from-headers "payload" headers))
	  )
      (if payload (progn
		    (handle-message payload)
		    (ws-response-header process 200
					'("Content-type" . "application/json")
					'("Access-Control-Allow-Origin" . "*"))
		    (process-send-string process
					 (stored-links-count)))))))

;; (lambda (request)
;;   (with-slots (process headers) request
;;	(let ((message (cdr (assoc "message" headers))))
;;	  (if message
;;	      (let ((value (cdr (assoc 'content message))))
;;		(handle-message value)
;;		(ws-response-header process 200 '("Content-type" . "application/json")
;;				    '("Access-Control-Allow-Origin" . "*"))
;;		(process-send-string process (stored-links-count)))))))


(defun test-request (request)
  (with-slots (process headers) request
    (message "got request")))

(defun start-web-server ()
  (setq server
	(ws-start
	 '(((:POST . ".*") . handle-request))
	 9090)))

(start-web-server)

(defun stop-web-server ()
  (ws-stop server))

(stop-web-server)

(defun org-browser-tabs-server-focused-window ()
  (let ((focused (alist-get "focused" links)))
    (if focused (alist-get focused links))))


(defun org-browser-tabs-server-text ()
  (let* ((name (alist-get "focused"))
	 (tabs (org-browser-tabs-server-focused-window)))
    (apply 'concat "* " name "\n"
	   (mapcar (lambda (tab)
		     (concat "** [[" (alist-get 'url tab) "]["
			     (alist-get 'title tab) "]]\n"))
		   tabs))))
