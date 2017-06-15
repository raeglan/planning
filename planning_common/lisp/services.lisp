(in-package :planning-common-package)

(defun service-log-experiment-description (creator description experiment experiment-name robot)
  "Return success field of response message from calling service '/log_experiment_description'."
  (let ((srv "/log_experiment_description"))
    (if (not (wait-for-service srv 10))
        (ros-warn srv "Timed out waiting for service.")
        (with-fields
            (success)
            (call-service srv
                          ;'suturo_knowledge_msgs-srv:LogExperimentDescription
                          :creator creator
                          :description description
                          :experiment experiment
                          :experimentName experiment-name
                          :robot robot)
          success))))

(defun service-log-task (name parent-id start end params success)
  "Return actionID field of response message from calling service '/log_action'."
  (let ((srv "/log_action"))
    (if (not (wait-for-service srv 10))
        (ros-warn srv "Timed out waiting for service.")
        (with-fields
            (actionID)
            (call-service srv
                          'suturo_knowledge_msgs-srv:LogAction
                          :nameOfAction name
                          :parentActionID parent-id
                          :startTime start
                          :endTime end
                          :parameters params
                          :success success)
          actionID))))
            
(defun service-connect-frames (parent-frame-id child-frame-id)
  "Return success field of response message from calling service '/connect_frames_service'."
  (let ((srv "/connect_frames_service"))
    (if (not (wait-for-service srv 10))
        (ros-warn srv "Timed out waiting for service.")
        (with-fields
            (success)
            (call-service srv
                          'suturo_knowledge_msgs-srv:ConnectFrames
                          :parentFrame parent-frame-id
                          :childFrame child-frame-id)
            success))))

(defun service-run-pipeline (&rest objects)
  "Return failedObjects field of response message from calling service '/percepteros/set_pipeline'."
  (let ((srv "/percepteros/set_pipeline"))
    (if (not (wait-for-service srv 10))
        (ros-warn srv "Timed out waiting for service.")
        (with-fields
            (failedObjects)
            (call-service srv
                          'suturo_perception_msgs-srv:RunPipeline
                          :objects objects)
            failedObjects))))


