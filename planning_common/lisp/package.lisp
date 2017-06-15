(defpackage :planning-common-package
  (:nicknames :common)
  (:use :cl :roslisp)
  (:export

   :+no-arm+
   :+left-arm+
   :+right-arm+
   :+both-arms+

   :+double+
   :+transform+

   :low-level-failure
   :high-level-failure
   :action-timeout
   :action-lost
   :perception-pipeline-failure
   :seen-since-failure
   
   :object-info
   :make-object-info
   :object-info-name
   :object-info-frame
   :object-info-timestamp
   :object-info-height
   :object-info-width
   :object-info-depth
   :object-info-type
   :object-info-pose

   :service-run-pipeline
   
   :action-move-robot

   :prolog-seen-since
   :prolog-disconnect-frames
   :prolog-connect-frames
   
   :ensure-node-is-running
   :make-param
   :get-transform-listener
   :extract-pose-from-transform
   :tf-pose->string
   :tf-lookup->string
   :file->string
   :split
   :strings->KeyValues
   :get-joint-config
   :get-controller-specs
   :say

   :run-full-pipeline
   :run-pipeline
   :connect-objects
   :disconnect-objects
   :get-object-info))

(in-package :planning-common-package)

; constants
; arms
(alexandria:define-constant +no-arm+ "n" :test #'equal)
(alexandria:define-constant +right-arm+ "r" :test #'equal)
(alexandria:define-constant +left-arm+ "l" :test #'equal)
(alexandria:define-constant +both-arms+ "b" :test #'equal)

; param types
(defconstant +double+ (symbol-code 'suturo_manipulation_msgs-msg:TypedParam :DOUBLE))
(defconstant +transform+ (symbol-code 'suturo_manipulation_msgs-msg:TypedParam :TRANSFORM))
