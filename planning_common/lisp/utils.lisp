(in-package :planning-common-package)

(defun ensure-node-is-running ()
  "Ensure a node is running. Start one otherwise."
  (unless (eq (node-status) :RUNNING)
    (start-ros-node "planning")))

(defun make-param (type is-const name value)
  "Create a message of type 'suturo_manipulation_msgs/TypedParam'."
  (make-message "suturo_manipulation_msgs/TypedParam"
                :type type
                :isConst is-const
                :name name
                :value value))

(defun file->string (path-to-file)
  "Create a String from PATH-TO-FILE."
  (let ((in (open path-to-file :if-does-not-exist nil))
        (out ""))
    (when in
      (loop for line = (read-line in nil)
            while line do (setf out (concatenate 'string out line (string #\linefeed))))
      (close in))
    out))

(defun split (string characters)
  "Return split STRING at every occurence of a character in CHARACTERS.
The return value does not include empty strings.

STRING (string): String to be split.
CHARACTERS (string): Contains every character on which STRING shall be split."
  (flet ((delimiterp (c) (position c characters)))
    (loop
      :for beg = (position-if-not #'delimiterp string)
        :then (position-if-not #'delimiterp string :start (1+ end))
      :for end = (and beg (position-if #'delimiterp string :start beg))
      :when beg :collect (subseq string beg end)
        :while end)))

(defun strings->KeyValues (strings)
  "Generate messages of type 'diagnostic_msgs/KeyValue' pairs out of STRINGS.

STRINGS (list of strings): Alternating keys and values. Has to have an even length."
  (when (>= (length strings) 2)
    (cons
     (make-message "diagnostic_msgs/KeyValue"
                   :key (car strings)
                   :value (car (cdr strings)))
     (let ((rest-strings (cdr (cdr strings))))
       (when rest-strings
         (strings->KeyValues rest-strings))))))

(defun run-full-pipeline ()
  "Run perception pipeline for recognizing knife and cake."
  (ros-info "run-full-pipeline" "recognizing Knife....")
  (service-run-pipeline "knife")
  (sleep 15)
  (service-run-pipeline "spatula")
  (sleep 10)
  (ros-info "run-full-pipeline" "recognizing Cake...")
  (service-run-pipeline "cake")
  (sleep 10)
  (service-run-pipeline "plate")
  (sleep 10)
  (service-run-pipeline "end")
  (sleep 5))

(defun run-pipeline (obj-type)
  "Run perception pipeline for OBJ-TYPE."
  (let ((unrecognized-objs (service-run-pipeline obj-type)))
    unrecognized-objs))

(defun connect-objects (parent-info child-info)
  "Connect objects described by PARENT-INFO and CHILD-INFO
using prolog interface."
  (prolog-connect-frames
   (format nil "/~a" (object-info-name parent-info))
   (format nil "/~a" (object-info-name child-info))))

(defun disconnect-objects (parent-info child-info)
  "Disconnect objects described by PARENT-INFO and CHILD-INFO
using prolog interface."
  (prolog-disconnect-frames
   (format nil "/~a" (object-info-name parent-info))
   (format nil "/~a" (object-info-name child-info))))

(defun get-object-info (object-type)
  "Get object infos for OBJECT-TYPE using prolog interface."
  (let ((raw-response (prolog-get-object-info-simple object-type)))
    (when raw-response
      (cut:with-vars-bound
          (?name ?frame ?timestamp ?pose ?width ?height ?depth)
          raw-response
        (make-object-info
         :name (knowrob->str ?name T)
         :frame (knowrob->str ?frame)
         :type object-type
         :timestamp ?timestamp
         :pose ?pose
         :height ?height
         :width ?width
         :depth ?depth
         :physical-parts (get-phys-parts (knowrob->str ?name T)))))))

; if it doesn't work from the start, comment in the uncommented line. 
; Make sure the node is running though
(defun say (a-string)
  (unless (eq roslisp::*node-status* :running)
    (roslisp:start-ros-node "sound-play-node"))
  (let ((publisher (roslisp:advertise "robotsound" 'sound_play-msg:<soundrequest>)))
    ;(loop while (< (roslisp:num-subscribers publisher) 1) do (sleep 0.01))
    (ros-info (sound-play) "saying ~a" a-string)
    (roslisp:publish-msg
     publisher
     :sound (symbol-code 'sound_play-msg:<soundrequest> :say)
     :command (symbol-code 'sound_play-msg:<soundrequest> :play_once)
     :arg a-string :arg2 "voice_kal_diphone")))

(defun get-guest-ids ()
  '(1 2 3 4 5 6))

(defun get-guest-order (id)
  "Get guest order of guest with ID."
  (cut:with-vars-bound
      (?amount)
      (prolog-guest-info id)
    ?amount))

(defun get-current-order ()
  "Retrieves the whole orders list via prolog. First checks orders where the delivered amount of cake is greater than 0,
then if those orders are finished already. Else get a jet untouched order or wait for new ones."
  (let ((all-orders-raw (prolog-get-open-orders-of)))
    (unless all-orders-raw
      (flet ((order-status (order)
               (cut:with-vars-bound
                   (?amount ?delivered)
                   order
                 (if (>= (symbol->integer ?delivered) (symbol->integer ?amount))
                     :finished
                     (if (< 0 (symbol->integer ?amount) (symbol->integer ?delivered))
                         :started
                         :queued)))))
        (reduce (lambda (this next)
                  (alexandria:switch ((order-status this))
                    (:started (last (assoc "?customerid" this)))
                    (:finished (last (assoc "?customerid" next)))
                    (:queued (if (eq (order-status next) :queued)
                                 (last (assoc "?customerid" this))
                                 (last (assoc "?customerid" next)))))) all-orders-raw)))))

(defun get-remaining-amount-for-order (customer-id)
  "Retrieve the remaining amount of pieces still to deliver. total - delivered = value"
  (let ((raw-order (prolog-get-open-orders-of customer-id)))
    (when raw-order
      (cut:with-vars-bound
          (?Item ?Amount ?Delivered)
          raw-order
        (- ?Amount ?Delivered)))))

(defun knowrob->str (knowrob-sym &optional (split NIL))
  "Turn a symbol representing a string returned by Knowledge into a normal string. Optionally cut off the knowrob prefix as well."
  (let* ((pre-str (symbol-name knowrob-sym))
         (str (subseq pre-str 1 (1- (length pre-str)))))
    (if split
        (when (find #\# str)
          (second (split str "#")))
        str)))

(defun symbol->integer (symbol)
  "Parses a symbol containing an integer into an integer. Symbol has to contain an integer value."
  (parse-integer (remove #\| (write-to-string symbol))))
