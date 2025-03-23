;; Technique Registration Contract
;; Documents traditional preservation methods

;; Define data variables
(define-data-var last-technique-id uint u0)
(define-data-var last-ingredient-id uint u0)

;; Map to store preservation techniques
(define-map preservation-techniques
  { id: uint }
  {
    owner: principal,
    name: (string-ascii 100),
    description: (string-ascii 500),
    origin-region: (string-ascii 100),
    cultural-context: (string-ascii 200),
    estimated-age-years: uint,
    equipment-needed: (string-ascii 200),
    difficulty-level: (string-ascii 20),
    registration-date: uint
  }
)

;; Map to store technique steps
(define-map technique-steps
  { technique-id: uint, step-number: uint }
  {
    description: (string-ascii 500),
    duration-minutes: uint,
    temperature: (string-ascii 50),
    special-notes: (string-ascii 200)
  }
)

;; Map to store ingredients
(define-map ingredients
  { id: uint }
  {
    name: (string-ascii 100),
    category: (string-ascii 50),
    description: (string-ascii 200)
  }
)

;; Map to link techniques with ingredients
(define-map technique-ingredients
  { technique-id: uint, ingredient-id: uint }
  {
    quantity: (string-ascii 50),
    preparation: (string-ascii 200),
    substitutes: (string-ascii 200)
  }
)

;; Get the last assigned technique ID
(define-read-only (get-last-technique-id)
  (ok (var-get last-technique-id))
)

;; Get technique details by ID
(define-read-only (get-technique (id uint))
  (map-get? preservation-techniques { id: id })
)

;; Register a new preservation technique
(define-public (register-technique
    (name (string-ascii 100))
    (description (string-ascii 500))
    (origin-region (string-ascii 100))
    (cultural-context (string-ascii 200))
    (estimated-age-years uint)
    (equipment-needed (string-ascii 200))
    (difficulty-level (string-ascii 20)))
  (let
    ((new-id (+ (var-get last-technique-id) u1)))
    (var-set last-technique-id new-id)
    (map-set preservation-techniques { id: new-id } {
      owner: tx-sender,
      name: name,
      description: description,
      origin-region: origin-region,
      cultural-context: cultural-context,
      estimated-age-years: estimated-age-years,
      equipment-needed: equipment-needed,
      difficulty-level: difficulty-level,
      registration-date: block-height
    })
    (ok new-id)
  )
)

;; Update technique information
(define-public (update-technique
    (id uint)
    (description (string-ascii 500))
    (equipment-needed (string-ascii 200))
    (difficulty-level (string-ascii 20)))
  (let ((technique-data (map-get? preservation-techniques { id: id })))
    (match technique-data
      technique (if (is-eq tx-sender (get owner technique))
        (begin
          (map-set preservation-techniques { id: id } {
            owner: (get owner technique),
            name: (get name technique),
            description: description,
            origin-region: (get origin-region technique),
            cultural-context: (get cultural-context technique),
            estimated-age-years: (get estimated-age-years technique),
            equipment-needed: equipment-needed,
            difficulty-level: difficulty-level,
            registration-date: (get registration-date technique)
          })
          (ok id)
        )
        (err u403))
      (err u404)
    )
  )
)

;; Add a step to a technique
(define-public (add-technique-step
    (technique-id uint)
    (step-number uint)
    (description (string-ascii 500))
    (duration-minutes uint)
    (temperature (string-ascii 50))
    (special-notes (string-ascii 200)))
  (let ((technique-data (map-get? preservation-techniques { id: technique-id })))
    (match technique-data
      technique (if (is-eq tx-sender (get owner technique))
        (begin
          (map-set technique-steps { technique-id: technique-id, step-number: step-number } {
            description: description,
            duration-minutes: duration-minutes,
            temperature: temperature,
            special-notes: special-notes
          })
          (ok { technique-id: technique-id, step-number: step-number })
        )
        (err u403))
      (err u404)
    )
  )
)

;; Get a specific step for a technique
(define-read-only (get-technique-step (technique-id uint) (step-number uint))
  (map-get? technique-steps { technique-id: technique-id, step-number: step-number })
)

;; Register a new ingredient
(define-public (register-ingredient
    (name (string-ascii 100))
    (category (string-ascii 50))
    (description (string-ascii 200)))
  (let
    ((new-id (+ (var-get last-ingredient-id) u1)))
    (var-set last-ingredient-id new-id)
    (map-set ingredients { id: new-id } {
      name: name,
      category: category,
      description: description
    })
    (ok new-id)
  )
)

;; Get ingredient details by ID
(define-read-only (get-ingredient (id uint))
  (map-get? ingredients { id: id })
)

;; Link an ingredient to a technique
(define-public (add-technique-ingredient
    (technique-id uint)
    (ingredient-id uint)
    (quantity (string-ascii 50))
    (preparation (string-ascii 200))
    (substitutes (string-ascii 200)))
  (let ((technique-data (map-get? preservation-techniques { id: technique-id })))
    (match technique-data
      technique (if (is-eq tx-sender (get owner technique))
        (begin
          (map-set technique-ingredients { technique-id: technique-id, ingredient-id: ingredient-id } {
            quantity: quantity,
            preparation: preparation,
            substitutes: substitutes
          })
          (ok { technique-id: technique-id, ingredient-id: ingredient-id })
        )
        (err u403))
      (err u404)
    )
  )
)

;; Get ingredient details for a technique
(define-read-only (get-technique-ingredient (technique-id uint) (ingredient-id uint))
  (map-get? technique-ingredients { technique-id: technique-id, ingredient-id: ingredient-id })
)

