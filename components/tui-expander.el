;;; tui-expander.el --- Basic expander control       -*- lexical-binding: t; -*-

;;; Commentary:
;; 

(require 'dash)
(require 'tui-core)
(require 'tui-span "components/tui-span.el")

;;; Code:

(defvar tui-expander-keymap
  (let ((map (make-sparse-keymap)))
    (define-key map "+" 'tui-expander-expand)
    (define-key map "-" 'tui-expander-collapse)
    (define-key map "=" 'tui-expander-toggle-expansion)
    map)
  "Expander keymap.")

(defvar tui-expander-glyph-keymap
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map tui-expander-keymap)
    (define-key map [mouse-1] 'tui-expander-toggle-expansion)
    (define-key map [space] 'tui-expander-toggle-expansion)
    (define-key map [return] 'tui-expander-toggle-expansion)
    map)
  "Expander keymap.")

(defvar tui-default-expander-expand-glyph "▲" "Default glyph to use for displaying expander buttons.")
(defvar tui-default-expander-collapse-glyph "▼" "Default glyph to use for displaying collapse buttons.")

;; TODO: revise definition to easily substitute "+/-" glyphs
(defun tui--expander-glyph (expanded &optional expand-glyph collapse-glyph)
  "Internal helper to render a group's expander glyph button.
Argument EXPANDED - whether the expander is expanded.
Optional argument EXPAND-GLYPH - glyph to show when collapsed.
Optional argument COLLAPSE-GLYPH - glyph to show when expanded."
  (if expanded
      (tui-span
       :text-props `(help-echo "click to collapse"
                               keymap ,tui-expander-keymap)
       (or collapse-glyph
           tui-default-expander-collapse-glyph))
    (tui-span
     :text-props `(help-echo "click to expand"
                             keymap ,tui-expander-keymap)
     (or expand-glyph
         tui-default-expander-expand-glyph))))

(defun tui-expander-expand (event)
  "Mouse function to expand expander at point of EVENT."
  (interactive "e")
  (tui-expander--expand
   (tui-expander-get-expander event)))

(defun tui-expander--expand (&optional expander)
  "Collapse EXPANDER."
  (unless expander (setq expander (tui-expander-get-expander)))
  (tui--set-state expander '(:expanded t)))

;; FIXME: has implicit expectation that it is invoked with the tree column as current
(defun tui-expander--collapse (&optional expander)
  "Collapse EXPANDER."
  (unless expander (setq expander (tui-expander-get-expander)))
  (tui--set-state expander '(:expanded nil)))

(defun tui-expander-toggle-expansion (&optional expander)
  "Toggle expansion EXPANDER."
  (interactive)
  (unless expander (setq expander (tui-expander-get-expander)))
  (if (plist-get (tui--get-state expander) :expanded)
      (tui-expander--collapse expander)
    (tui-expander--expand expander)))

(defun tui-expander-get-expander (&optional position-or-event)
  "Return the expander associated with POSITION-OR-EVENT."
  (when (eventp position-or-event)
    (setq position-or-event (posn-point (event-end position-or-event))))
  (let ((position (or position-or-event
                      (point))))
    (tui-get-element-at position 'tui-expander)))

(tui-define-component tui-expander
  :documentation
  "Expander component enables showing/hiding content below a supplied header."
  :prop-documentation
  (:header "Shown regardless of whether expander is expanded or collapsed."
    :children "Content of the expander shown following the header."
    :initially-expanded "Whether the content of the expander should be initially be shown.")
  ;; TODO :get-default-props
  ;; :expanded-glyph
  ;; :collapsed-glyph
  :get-initial-state
  (lambda ()
    (let* ((props (tui-get-props))
           (initially-expanded (if (plist-member props :initially-expanded)
                                   (plist-get props :initially-expanded)
                                 t)))
      (list :expanded initially-expanded)))
  :render
  (lambda ()
    (let* ((props (tui-get-props))
           (header (plist-get props :header))
           (content (plist-get props :children))
           (expanded (plist-get (tui-get-state) :expanded)))
      (tui-div
       :text-props `(keymap ,tui-expander-keymap)
       :replace-behavior nil
       (tui-span
        :text-props-replace `(font-lock-ignore t
                                       face (:background "blue")
                                       keymap ,tui-expander-glyph-keymap)
        (if expanded "⊟" "⊞"))
       " "
       header
       (tui-div
        :invisible (not expanded)
        content)))))

(defun tui-demo-basic-expander ()
  "Show a demonstration expander."
  (interactive)
  (tui-show-component-demo
   (tui-expander
    :header (tui-line "This is an expander")
    "Aliquam erat volutpat.  Nunc eleifend leo vitae magna.  In id erat non orci commodo lobortis.  Proin neque massa, cursus ut, gravida ut, lobortis eget, lacus.  Sed diam.  Praesent fermentum tempor tellus.  Nullam tempus.  Mauris ac felis vel velit tristique imperdiet.  Donec at pede.  Etiam vel neque nec dui dignissim bibendum.  Vivamus id enim.  Phasellus neque orci, porta a, aliquet quis, semper a, massa.  Phasellus purus.  Pellentesque tristique imperdiet tortor.  Nam euismod tellus id erat.\n")))

(defun tui-demo-nested-expander ()
  "Show a demonstration of nested expanders."
  (interactive)
  (tui-show-component-demo
   (tui-expander
    :header (tui-line "This is an expander")
    (tui-prefix-lines
     :prefix "  "
     (list
      (tui-line "Lorem ipsum dolor sit amet, consectetuer adipiscing elit.  Donec hendrerit tempor tellus.  Donec pretium posuere tellus.  Proin quam nisl, tincidunt et, mattis eget, convallis nec, purus.  Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.  Nulla posuere.  Donec vitae dolor.  Nullam tristique diam non turpis.  Cras placerat accumsan nulla.  Nullam rutrum.  Nam vestibulum accumsan nisl.")
      (tui-expander
       :header (tui-line "This is a nested expander")
       (tui-prefix-lines
        :prefix "    "
        (tui-line "Aliquam erat volutpat.  Nunc eleifend leo vitae magna.  In id erat non orci commodo lobortis.  Proin neque massa, cursus ut, gravida ut, lobortis eget, lacus.  Sed diam.  Praesent fermentum tempor tellus.  Nullam tempus.  Mauris ac felis vel velit tristique imperdiet.  Donec at pede.  Etiam vel neque nec dui dignissim bibendum.  Vivamus id enim.  Phasellus neque orci, porta a, aliquet quis, semper a, massa.  Phasellus purus.  Pellentesque tristique imperdiet tortor.  Nam euismod tellus id erat."))))))))

(provide 'tui-expander)

(provide 'tui-expander)

;;; tui-expander.el ends here
