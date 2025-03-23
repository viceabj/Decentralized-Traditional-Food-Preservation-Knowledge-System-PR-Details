;; Knowledge Transfer Contract
;; Facilitates teaching of preservation skills

;; Define data variables
(define-data-var last-teacher-id uint u0)
(define-data-var last-class-id uint u0)
(define-data-var last-certification-id uint u0)
(define-data-var last-resource-id uint u0)

;; Map to store teachers
(define-map teachers
  { id: uint }
  {
    owner: principal,
    name: (string-ascii 100),
    expertise: (string-ascii 200),
    experience-years: uint,
    region: (string-ascii 100),
    contact-info: (string-ascii 200),
    bio: (string-ascii 500),
    registration-date: uint
  }
)

;; Map to store classes
(define-map classes
  { id: uint }
  {
    teacher-id: uint,
    technique-id: uint,
    title: (string-ascii 100),
    description: (string-ascii 500),
    max-participants: uint,
    duration-hours: uint,
    prerequisites: (string-ascii 200),
    materials-needed: (string-ascii 200),
    location: (string-ascii 200),
    scheduled-date: uint,
    status: (string-ascii 20),
    created-at: uint
  }
)

;; Map to store class participants
(define-map class-participants
  { class-id: uint, participant: principal }
  {
    registration-date: uint,
    attendance-status: (string-ascii 20),
    notes: (string-ascii 200)
  }
)

;; Map to store certifications
(define-map certifications
  { id: uint }
  {
    recipient: principal,
    teacher-id: uint,
    technique-id: uint,
    certification-date: uint,
    expiry-date: uint,
    skill-level: (string-ascii 20),
    assessment-notes: (string-ascii 500)
  }
)

;; Map to store educational resources
(define-map educational-resources
  { id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    resource-type: (string-ascii 50),
    technique-id: uint,
    content-hash: (string-ascii 64),
    author: principal,
    created-at: uint
  }
)

;; Get the last assigned teacher ID
(define-read-only (get-last-teacher-id)
  (ok (var-get last-teacher-id))
)

;; Get teacher details by ID
(define-read-only (get-teacher (id uint))
  (map-get? teachers { id: id })
)

;; Register as a teacher
(define-public (register-teacher
    (name (string-ascii 100))
    (expertise (string-ascii 200))
    (experience-years uint)
    (region (string-ascii 100))
    (contact-info (string-ascii 200))
    (bio (string-ascii 500)))
  (let
    ((new-id (+ (var-get last-teacher-id) u1)))
    (var-set last-teacher-id new-id)
    (map-set teachers { id: new-id } {
      owner: tx-sender,
      name: name,
      expertise: expertise,
      experience-years: experience-years,
      region: region,
      contact-info: contact-info,
      bio: bio,
      registration-date: block-height
    })
    (ok new-id)
  )
)

;; Update teacher information
(define-public (update-teacher
    (id uint)
    (expertise (string-ascii 200))
    (experience-years uint)
    (contact-info (string-ascii 200))
    (bio (string-ascii 500)))
  (let ((teacher-data (map-get? teachers { id: id })))
    (match teacher-data
      teacher (if (is-eq tx-sender (get owner teacher))
        (begin
          (map-set teachers { id: id } {
            owner: (get owner teacher),
            name: (get name teacher),
            expertise: expertise,
            experience-years: experience-years,
            region: (get region teacher),
            contact-info: contact-info,
            bio: bio,
            registration-date: (get registration-date teacher)
          })
          (ok id)
        )
        (err u403))
      (err u404)
    )
  )
)

;; Create a class
(define-public (create-class
    (teacher-id uint)
    (technique-id uint)
    (title (string-ascii 100))
    (description (string-ascii 500))
    (max-participants uint)
    (duration-hours uint)
    (prerequisites (string-ascii 200))
    (materials-needed (string-ascii 200))
    (location (string-ascii 200))
    (scheduled-date uint))
  (let ((teacher-data (map-get? teachers { id: teacher-id })))
    (match teacher-data
      teacher (if (is-eq tx-sender (get owner teacher))
        (let ((new-id (+ (var-get last-class-id) u1)))
          (var-set last-class-id new-id)
          (map-set classes { id: new-id } {
            teacher-id: teacher-id,
            technique-id: technique-id,
            title: title,
            description: description,
            max-participants: max-participants,
            duration-hours: duration-hours,
            prerequisites: prerequisites,
            materials-needed: materials-needed,
            location: location,
            scheduled-date: scheduled-date,
            status: "open",
            created-at: block-height
          })
          (ok new-id)
        )
        (err u403))
      (err u404)
    )
  )
)

;; Get class details by ID
(define-read-only (get-class (id uint))
  (map-get? classes { id: id })
)

;; Register for a class
(define-public (register-for-class
    (class-id uint)
    (notes (string-ascii 200)))
  (let ((class-data (map-get? classes { id: class-id })))
    (match class-data
      class-info (if (is-eq (get status class-info) "open")
        (begin
          (map-set class-participants { class-id: class-id, participant: tx-sender } {
            registration-date: block-height,
            attendance-status: "registered",
            notes: notes
          })
          (ok { class-id: class-id, participant: tx-sender })
        )
        (err u400)) ;; Class not open
      (err u404)
    )
  )
)

;; Update class status
(define-public (update-class-status
    (class-id uint)
    (status (string-ascii 20)))
  (let ((class-data (map-get? classes { id: class-id })))
    (match class-data
      class-info (let ((teacher-data (map-get? teachers { id: (get teacher-id class-info) })))
        (match teacher-data
          teacher (if (is-eq tx-sender (get owner teacher))
            (begin
              (map-set classes { id: class-id } {
                teacher-id: (get teacher-id class-info),
                technique-id: (get technique-id class-info),
                title: (get title class-info),
                description: (get description class-info),
                max-participants: (get max-participants class-info),
                duration-hours: (get duration-hours class-info),
                prerequisites: (get prerequisites class-info),
                materials-needed: (get materials-needed class-info),
                location: (get location class-info),
                scheduled-date: (get scheduled-date class-info),
                status: status,
                created-at: (get created-at class-info)
              })
              (ok class-id)
            )
            (err u403))
          (err u404)
        )
      )
      (err u404)
    )
  )
)

;; Issue a certification
(define-public (issue-certification
    (recipient principal)
    (teacher-id uint)
    (technique-id uint)
    (expiry-date uint)
    (skill-level (string-ascii 20))
    (assessment-notes (string-ascii 500)))
  (let ((teacher-data (map-get? teachers { id: teacher-id })))
    (match teacher-data
      teacher (if (is-eq tx-sender (get owner teacher))
        (let ((new-id (+ (var-get last-certification-id) u1)))
          (var-set last-certification-id new-id)
          (map-set certifications { id: new-id } {
            recipient: recipient,
            teacher-id: teacher-id,
            technique-id: technique-id,
            certification-date: block-height,
            expiry-date: expiry-date,
            skill-level: skill-level,
            assessment-notes: assessment-notes
          })
          (ok new-id)
        )
        (err u403))
      (err u404)
    )
  )
)

;; Get certification details by ID
(define-read-only (get-certification (id uint))
  (map-get? certifications { id: id })
)

;; Add an educational resource
(define-public (add-educational-resource
    (title (string-ascii 100))
    (description (string-ascii 500))
    (resource-type (string-ascii 50))
    (technique-id uint)
    (content-hash (string-ascii 64)))
  (let
    ((new-id (+ (var-get last-resource-id) u1)))
    (var-set last-resource-id new-id)
    (map-set educational-resources { id: new-id } {
      title: title,
      description: description,
      resource-type: resource-type,
      technique-id: technique-id,
      content-hash: content-hash,
      author: tx-sender,
      created-at: block-height
    })
    (ok new-id)
  )
)

;; Get resource details by ID
(define-read-only (get-educational-resource (id uint))
  (map-get? educational-resources { id: id })
)

;; Check if a person is certified for a technique
(define-read-only (is-person-certified (person principal) (technique-id uint))
  ;; In a real implementation, this would search through certifications
  ;; For simplicity, we return a placeholder
  (ok false)
)

;; Get all classes by a teacher - simplified version
(define-read-only (get-teacher-classes (teacher-id uint))
  ;; In a real implementation, this would filter classes by teacher
  ;; For simplicity, we return an empty list
  (ok (list))
)

;; Get all certifications for a person - simplified version
(define-read-only (get-person-certifications (person principal))
  ;; In a real implementation, this would filter certifications by recipient
  ;; For simplicity, we return an empty list
  (ok (list))
)

