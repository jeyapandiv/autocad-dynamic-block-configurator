;; ======================================
;; DYNAMIC BLOCK CONFIGURATION TOOL
;; ======================================
;; Interactive approach: User selects which params to modify

;; -----------------------------------------------
;; UTILITY: Safe Menu Selection
;; -----------------------------------------------
(defun get-choice-safe (msg lst / i choice result)
  (setq i 1)
  (foreach item lst
    (prompt (strcat "\n" (itoa i) ". " item))
    (setq i (1+ i))
  )

  (setq result nil)

  (while (not result)
    (setq choice (getint (strcat "\n" msg)))
    (if (and choice (>= choice 1) (<= choice (length lst)))
      (setq result (nth (1- choice) lst))
      (prompt "\n⚠️  Invalid choice. Try again.")
    )
  )

  result
)

;; -----------------------------------------------
;; GET PARAMETERS BASED ON VISIBILITY (MAPPING)
;; -----------------------------------------------
(defun get-params-for-visibility (vis / params)
  (cond
    ((wcmatch vis "PLAN*")
     (setq params '("Distance1" "Distance3"))
    )

    ((wcmatch vis "SECTION*")
     (setq params '("Distance2" "Distance9"))
    )

    ((wcmatch vis "ELEVATION*")
     (setq params '("Distance1" "Distance4"))
    )

    (T
     (setq params nil)
    )
  )

  params
)

;; -----------------------------------------------
;; SELECT DWG FILE
;; -----------------------------------------------
(defun select-dwg-file (/ file)
  (setq file (getfiled "Select Library DWG" "" "dwg" 0))

  (if (and file (findfile file))
    (progn
      (prompt (strcat "\n✓ Selected: " file))
      file
    )
    (progn
      (prompt "\n❌ Invalid file or no file selected.")
      nil
    )
  )
)

;; -----------------------------------------------
;; GET DYNAMIC BLOCKS FROM LIBRARY DWG
;; -----------------------------------------------
(defun get-blocks-from-dwg (dwgfile / doc blocks blk names)
  (setq doc (vla-open (vla-get-Documents (vlax-get-acad-object)) dwgfile :vlax-false :vlax-false))
  (setq blocks (vla-get-Blocks doc))
  (setq names '())

  (vlax-for blk blocks
    (if (and
          (= :vlax-true (vla-get-IsDynamicBlock blk))
          (not (wcmatch (vla-get-Name blk) "`**"))
        )
      (setq names (cons (vla-get-Name blk) names))
    )
  )

  (vla-close doc :vlax-false)
  (vl-sort names '<)
)

;; -----------------------------------------------
;; SAFE CONVERSION: AllowedValues to List
;; -----------------------------------------------
(defun safe-allowed-values-to-list (allowedValues / result)
  (cond
    ((listp allowedValues)
     allowedValues
    )
    ((varp allowedValues)
     (vlax-safearray->list (vlax-variant-value allowedValues))
    )
    (T
     (vlax-safearray->list allowedValues)
    )
  )
)

;; -----------------------------------------------
;; GET VISIBILITY STATES
;; -----------------------------------------------
(defun get-visibility-states (obj / props p propName result)
  (setq props (vlax-invoke obj 'GetDynamicBlockProperties))
  (setq result '())

  (foreach p props
    (setq propName (vla-get-PropertyName p))

    (if (wcmatch propName "*Visibility*")
      (if (vlax-property-available-p p 'AllowedValues)
        (setq result (safe-allowed-values-to-list (vlax-get p 'AllowedValues)))
      )
    )
  )

  result
)

;; -----------------------------------------------
;; SET VISIBILITY STATE BY NAME
;; -----------------------------------------------
(defun set-visibility-by-name (obj visName / props p propName)
  (setq props (vlax-invoke obj 'GetDynamicBlockProperties))

  (foreach p props
    (setq propName (vla-get-PropertyName p))

    (if (wcmatch propName "*Visibility*")
      (progn
        (vla-put-value p (vlax-make-variant visName vlax-vbString))
        (vla-update obj)
        (command "_.regen")
      )
    )
  )
)

;; -----------------------------------------------
;; GET ALL NUMERIC PARAMETERS
;; -----------------------------------------------
(defun get-all-numeric-parameters (obj / props p propName paramList val)
  (setq props (vlax-invoke obj 'GetDynamicBlockProperties))
  (setq paramList '())

  (foreach p props
    (setq propName (vla-get-PropertyName p))

    (if (and
          (not (wcmatch propName "*Visibility*"))
          (not (wcmatch propName "*Origin*"))
        )
      (progn
        (if (vlax-property-available-p p 'Value)
          (progn
            (setq val (vlax-variant-value (vla-get-value p)))

            (if (numberp val)
              (setq paramList (cons (list propName val p) paramList))
            )
          )
        )
      )
    )
  )

  (reverse paramList)
)

;; -----------------------------------------------
;; INTERACTIVE: Let user select which params to modify
;; -----------------------------------------------
(defun select-params-to-modify (allParams / i choice selections yesNo param)
  (setq selections '())

  (prompt "\n\n🔹 SELECT PARAMETERS TO MODIFY:")
  (prompt "\n(You can modify multiple parameters)\n")

  (foreach param allParams
    (setq i 1)
    (prompt (strcat "\n  " (car param) " (current: " (rtos (cadr param) 2 4) ")?"))

    (setq yesNo nil)
    (while (not yesNo)
      (setq choice (getint "\n    1=Yes, 2=No: "))
      (if (or (= choice 1) (= choice 2))
        (progn
          (if (= choice 1)
            (progn
              (setq selections (cons param selections))
              (prompt "    ✓ Selected")
            )
            (prompt "    ✗ Skipped")
          )
          (setq yesNo T)
        )
        (prompt "\n    ⚠️  Enter 1 or 2")
      )
    )
  )

  (reverse selections)
)

;; -----------------------------------------------
;; SET PARAMETER VALUE
;; -----------------------------------------------
(defun set-parameter-value (propObj newValue)
  (vla-put-value propObj (vlax-make-variant (float newValue) vlax-vbDouble))
  (command "_.regen")
)

;; -----------------------------------------------
;; MAIN COMMAND
;; -----------------------------------------------
(defun c:GetDynBlk (/ dwgfile blockList blkName ent obj visStates visChoice
                      allParams selectedParams allowedParams filteredParams param
                      paramName currentVal input insPt)

  (prompt "\n╔════════════════════════════════════════╗")
  (prompt "\n║   DYNAMIC BLOCK CONFIGURATION TOOL    ║")
  (prompt "\n║    (Interactive Parameter Selection)  ║")
  (prompt "\n╚════════════════════════════════════════╝")

  ;; STEP 1: USER SELECTS LIBRARY DWG
  (prompt "\n\n📂 STEP 1: Select Library DWG File...")
  (setq dwgfile (select-dwg-file))

  (if (not dwgfile)
    (progn
      (prompt "\n❌ No file selected. Exiting.")
      (exit)
    )
  )

  ;; STEP 2: GET BLOCK LIST
  (prompt "\n\n📂 STEP 2: Loading blocks from library...")
  (setq blockList (get-blocks-from-dwg dwgfile))

  (if (not blockList)
    (progn
      (prompt "\n❌ No dynamic blocks found in library.")
      (exit)
    )
  )

  (prompt (strcat "\n✅ Found " (itoa (length blockList)) " dynamic blocks."))

  ;; STEP 3: SELECT BLOCK
  (prompt "\n\n🔹 STEP 3: SELECT DYNAMIC BLOCK:")
  (setq blkName (get-choice-safe "Enter block number: " blockList))
  (prompt (strcat "\n✓ Selected: " blkName))

  ;; STEP 4: LOAD BLOCK IF NEEDED
  (if (not (tblsearch "BLOCK" blkName))
    (progn
      (prompt "\n📥 STEP 4: Loading block definition from library...")
      (vla-InsertBlock
        (vla-get-ModelSpace (vla-get-ActiveDocument (vlax-get-acad-object)))
        (vlax-3D-point '(0 0 0))
        dwgfile
        1.0 1.0 1.0
        0.0
      )
      (entdel (entlast))
    )
  )

  ;; STEP 5: INSERT TEMPORARY INSTANCE
  (prompt "\n🔧 STEP 5: Creating temporary instance...")
  (command "-insert" blkName "0,0" 1 1 0)

  (setq ent (entlast))
  (setq obj (vlax-ename->vla-object ent))

  (vla-update obj)
  (command "_.regen")

  (setq allParams (get-all-numeric-parameters obj))

  ;; STEP 6: GET AND SELECT VISIBILITY STATE
  (setq visStates (get-visibility-states obj))

  (if visStates
    (progn
      (prompt "\n\n🔹 STEP 6: SELECT VISIBILITY STATE:")
      (setq visChoice (get-choice-safe "Enter visibility number: " visStates))
      (prompt (strcat "\n✓ Selected: " visChoice))

      ;; STEP 7: APPLY VISIBILITY BY NAME
      (prompt "\n🔧 STEP 7: Applying visibility state...")
      (set-visibility-by-name obj visChoice)
      (prompt "\n✓ Visibility changed successfully!")

      ;; STEP 8: FILTER PARAMETERS BASED ON VISIBILITY
      (setq allowedParams (get-params-for-visibility visChoice))

      (prompt (strcat "\n🔍 STEP 8: Visibility-specific parameters for " visChoice ": "))

      (if allowedParams
        (progn
          (foreach p allowedParams
            (prompt (strcat "\n   ✔ " p))
          )
        )
        (prompt "\n   ✔ Using ALL numeric parameters (default mode)")
      )

      (setq filteredParams
        (if allowedParams
          (vl-remove-if-not
            '(lambda (p) (member (car p) allowedParams))
            allParams
          )
          allParams
        )
      )
    )
    (prompt "\n⚠️  No visibility states found.")
  )

  ;; STEP 9: INTERACTIVE PARAMETER SELECTION
  (if allParams
    (progn
      (setq selectedParams (select-params-to-modify allParams))

      (if selectedParams
        (progn
          (prompt (strcat "\n\n✓ STEP 9: Modifying " (itoa (length selectedParams)) " parameters:\n"))

          (foreach param selectedParams
            (prompt (strcat "\n   ✓ " (car param)))
          )

          (prompt "\n\n🔹 STEP 10: ENTER VALUES FOR SELECTED PARAMETERS:")
          (prompt "\n(Press ENTER to keep current value)\n")

          (foreach param selectedParams
            (setq paramName (car param))
            (setq currentVal (cadr param))

            (prompt (strcat "\n  📐 " paramName ":"))
            (prompt (strcat "\n     Current value: " (rtos currentVal 2 4)))

            (setq input
              (getreal
                (strcat "\n     Enter new value <" (rtos currentVal 2 4) ">: ")
              )
            )

            (if input
              (progn
                (set-parameter-value (caddr param) input)
                (prompt (strcat "\n     ✓ Updated to " (rtos input 2 4)))
              )
              (prompt "\n     (kept current value)")
            )
          )
        )
        (prompt "\n⚠️  No parameters selected.")
      )
    )
    (prompt "\n⚠️  No numeric parameters found.")
  )

  ;; STEP 11: GET FINAL INSERTION POINT
  (prompt "\n\n📍 STEP 11: Pick final insertion point (or press ESC to cancel): ")
  (setq insPt (getpoint))

  (if insPt
    (progn
      (command "_.move" ent "" '(0 0 0) insPt)
      (prompt "\n✅ Block inserted and configured successfully!")
    )
    (progn
      (prompt "\n⚠️  Insertion cancelled. Block remains at origin.")
    )
  )

  (princ)
)

;; Load command
(prompt "\n✓ Dynamic Block Tool loaded. Type 'GetDynBlk' to start.")