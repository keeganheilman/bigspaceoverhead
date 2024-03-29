;; Set the package installation directory so that packages aren't stored in the
;; ~/.emacs.d/elpa path.
(require 'package)
(setq package-user-dir (expand-file-name "./.packages"))
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("elpa" . "https://elpa.gnu.org/packages/")))

;; Initialize the package system
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

;; Install dependencies
(package-install 'htmlize)
(package-install 'find-lisp)
(package-install 'org)
(package-install 'org-roam)
(package-install 's)
(package-install 'zenburn-theme)

(require 's)
(require 'ox-publish)
(require 'find-lisp)
(require 'org-roam)

(load-theme 'zenburn t)

(setq make-backup-files nil)

(defun my/sitemap-format-entry (entry style project)
    (format "%s [[file:%s][%s]]"
            (format-time-string "%Y-%m-%d" (org-publish-find-date entry project))
            entry
            (org-publish-find-title entry project)))

(setq org-html-validation-link nil ;; Do not show "Validate" link
      org-confirm-babel-evaluate nil)
;; The following setting is to ask htmlize to output HTML with
;; classes instead of defining the theme inline
;; (setq org-html-htmlize-output-type 'css) ; default: 'inline-css

(setq org-publish-project-alist
      '(
         ;; The digital garden
         ("notes"
          :base-directory "org"
          :base-extension "org"
          :publishing-directory "_public/"
          :publishing-function org-html-publish-to-html
          :with-broken-links f
          :recursive f
          :author "Keegan Heilman"
          :email "keeganheilman@gmail.com"
          :with-toc nil
          :html-postamble nil
          :section-numbers nil
          :htmlized-source t
          :html-head-include-scripts nil
          :html-head-include-default-style nil
          :html-head "<link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\" />"
          :auto-sitemap nil ;; Recent changes
          :sitemap-title "big space overhead"
          :sitemap-filename nil
          :sitemap-format-entry my/sitemap-format-entry
          :sitemap-sort-files anti-chronologically
          :sitemap-file-entry-format "%d - %t"
          :sitemap-style list)


        ; All figures, javascript scipts, etc linked to posts
        ("static"
        :base-directory "org"
        :base-extension "css\\|js\\|png\\|jpg\\|jpeg\\|gif\\|svg\\|pdf\\|mp3\\|ogg\\|swf"
        :publishing-directory "_public/"
        :recursive t
        :publishing-function org-publish-attachment
        )
        ; Te website's css
        ("css"
        :base-directory "css"
        :base-extension "css"
        :publishing-directory "_public/"
        :recursive t
        :publishing-function org-publish-attachment
        )
        ("org" :components ("static" "css"))))


; ---------------------------------------------------------------------
;                          PUBLISH
; ---------------------------------------------------------------------

(defun my/publish-all()
  (setq org-roam-directory "./org")  ; we first setup the org-roam locations
  (setq org-roam-db-location "./org/org-roam.db")  ; we first setup the org-roam locations
  (setq org-id-extra-files (org-roam--list-files org-roam-directory)) ; necessary to make link with IDs work
  (org-roam-db-sync t)
  (call-interactively 'org-publish-all))

; EXTERIOR LINKS -------------------------------------------------
; Exterior links need to be easily identifiable for readers. They
; should also open in a new tab.
; ---
(defun my/format-external-links (text backend info)
  (when (org-export-derived-backend-p backend 'html)
    (when (string-match-p (regexp-quote "http") text)
      (s-replace "<a" "<a target='_blank' rel='noopener noreferrer' class='external'" text))))

(add-to-list 'org-export-filter-link-functions
             'my/format-external-links)


; --- BACKLINKS ------------------------------------------------------
(add-hook 'org-export-before-processing-hook 'my/add-roam-backlinks)

(defun my/add-roam-backlinks (backend)
  "Insert backlinks at the end of org files. BACKEND."
  (when (org-roam-node-at-point)
    (save-excursion
      (goto-char (point-max))
      (insert "\n* page mentions:\n")
      (my/collect-roam-backlinks backend))))

(defun my/collect-roam-backlinks (backend)
  (when (org-roam-node-at-point)
    (goto-char (point-max))
    ;; Add a new header for the references
    (let* ((backlinks (org-roam-backlinks-get (org-roam-node-at-point) :unique t)))
      (dolist (backlink backlinks)
        (let* ((source-node (org-roam-backlink-source-node backlink))
               (point (org-roam-backlink-point backlink)))
          (insert
           (format "- [[./%s][%s]]\n"
                   (file-name-nondirectory (org-roam-node-file source-node))
                   (org-roam-node-title source-node))))))))
