(in-package :planning-common-package)

(defparameter *transform-listener* nil)

(defun init-transform-listener ()
  "Initialize `*transform-listener*'."
  (setf *transform-listener* (make-instance 'cl-tf:transform-listener)))

(defun get-transform-listener ()
  "Return `*transform-listener*'. Initialize it first if necessary."
  (if *transform-listener*
      *transform-listener*
      (init-transform-listener)))

(defun extract-pose-from-transform (parent-frame frame)
  "Lookup transform between PARENT-FRAME and FRAME and return just the pose.

PARENT-FRAME (string): The source frame in which FRAME is published.
FRAME (string): The target frame published in relation to PARENT_FRAME."
  (cl-tf:wait-for-transform (get-transform-listener)
                            :source-frame parent-frame
                            :target-frame frame
                            :timeout 1)
  (let ((target-transform-stamped
          (cl-tf:lookup-transform
           (get-transform-listener)
           frame
           parent-frame)))
     (cl-tf:transform->pose target-transform-stamped)))

(defun tf-pose->string (pose)
  "Create space-seperated string of the seven values in POSE.

POSE (cl-tf:pose): a pose."
  (let ((origin (cl-tf:origin pose))
        (orientation (cl-tf:orientation pose)))
    (multiple-value-bind (axis angle) (cl-tf:quaternion->axis-angle orientation)
      (let* ((normalized-axis
               (if (eql angle 0.0d0)
                   (cl-tf:make-3d-vector 1 0 0)
                   (cl-tf:normalize-vector axis)))
             (normalized-angle (cl-tf:normalize-angle angle)))
        (format nil "~a ~a ~a ~a ~a ~a ~a"
                (cl-tf:x origin)
                (cl-tf:y origin)
                (cl-tf:z origin)
                (- 0 (cl-tf:x normalized-axis))
                (- 0 (cl-tf:y normalized-axis))
                (- 0 (cl-tf:z normalized-axis))
                (- 0 normalized-angle))))))

(defun tf-lookup->string (parent-frame frame)
  "Use `tf-pose->string' and `extract-pose-from-transform' to create a string from a lookup.
See their documentation for more information."
  (tf-pose->string
   (extract-pose-from-transform parent-frame frame)))
