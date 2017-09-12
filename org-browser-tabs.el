(defun org-browser-get-chrome-tabs ()
  (do-applescript
"tell application \"Google Chrome\"
   set output to \"\"
   set theWindow to the first window
   tell theWindow
     set output to output & \"* Window\n\"
     repeat with theTab in tabs
       tell theTab
	 set output to output & \"** [[\" & URL & \"][\" & title & \"]]\n\"
       end tell
     end repeat
   end tell
   return the output
end tell"))

(defun org-browser-insert-tabs ()
  (insert (org-browser-get-chrome-tabs)))

(defun open-tabs-build-script (links)
  (concat
   "tell application \"Google Chrome\"\n"
   "  set theWindow to make new window\n"
   "  tell theWindow\n"
   "    set theTab to active tab\n"
   "    tell theTab\n"
   "      set URL to \"" (car links) "\"\n"
   "    end tell\n"
   (apply 'concat (mapcar (lambda (link)
			    (concat
			     "    set theTab to make new tab\n"
			     "    tell theTab\n"
			     "      set URL to \"" link "\"\n"
			     "    end tell\n"
			     )) (cdr links)))
   "  end tell\n"
   "end tell\n"))

(defun open-tabs-get-links (headline)
  (org-element-map headline 'link
    (lambda (link) (org-element-property :raw-link link))))

(defun open-tabs (headline)
  (do-applescript (open-tabs-build-script (open-tabs-get-links headline))))

(org-element-map (org-element-parse-buffer) 'headline
  (lambda (headline)
    (if (member "tabs" (org-element-property :tags headline))
	(open-tabs headline))))
