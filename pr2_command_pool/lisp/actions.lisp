(in-package :pr2-command-pool-package)

(defun action-move-gripper (target-width arm strength)
  "Move ARM with STRENGTH, taking TARGET-WIDTH into account."
  (when (not (member arm (list +left-arm+ +right-arm+)))
    (ros-error "action-move-gripper" "Unsupported arm specification: ~a." arm))
  (let ((effort-param-name (format nil "~a_gripper_joint_effort" arm)))
    (common:action-move-robot
     (format nil "gripper_control_~a" arm)
     (alexandria:curry #'error-break-function +action-move-gripper-error-limit+)
     T
     (make-param +double+ T "gripper_goal" (write-to-string target-width))
     (make-param +double+ T effort-param-name (write-to-string strength)))))
