;; Seasonal Scheduling Contract
;; Tracks optimal timing for preservation activities

;; Define data variables
(define-data-var last-season-id uint u0)
(define-data-var last-schedule-id uint u0)
(define-data-var last-event-id uint u0)

;; Map to store seasons
(define-map seasons
  { id: uint }
  {
    name: (string-ascii 50),
    start-month: uint,
    start-day: uint,
    end-month: uint,
    end-day: uint,
    region: (string-ascii 100),
    climate-notes: (string-ascii 200),
    added-by: principal,
    added-at: uint
  }
)

;; Map to store preservation schedules
(define-map preservation-schedules
  { id: uint }
  {
    technique-id: uint,
    season-id: uint,
    food-item: (string-ascii 100),
    optimal-start-month: uint,
    optimal-start-day: uint,
    optimal-end-month: uint,
    optimal-end-day: uint,
    notes: (string-ascii 500),
    created-by: principal,
    created-at: uint
  }
)

;; Map to store scheduled events
(define-map scheduled-events
  { id: uint }
  {
    schedule-id: uint,
    event-name: (string-ascii 100),
    event-date: uint,
    location: (string-ascii 200),
    participants: (string-ascii 200),
    status: (string-ascii 20),
    created-by: principal,
    created-at: uint
  }
)

;; Get the last assigned season ID
(define-read-only (get-last-season-id)
  (ok (var-get last-season-id))
)

;; Get season details by ID
(define-read-only (get-season (id uint))
  (map-get? seasons { id: id })
)

;; Register a new season
(define-public (register-season
    (name (string-ascii 50))
    (start-month uint)
    (start-day uint)
    (end-month uint)
    (end-day uint)
    (region (string-ascii 100))
    (climate-notes (string-ascii 200)))
  (let
    ((new-id (+ (var-get last-season-id) u1)))
    (var-set last-season-id new-id)
    (map-set seasons { id: new-id } {
      name: name,
      start-month: start-month,
      start-day: start-day,
      end-month: end-month,
      end-day: end-day,
      region: region,
      climate-notes: climate-notes,
      added-by: tx-sender,
      added-at: block-height
    })
    (ok new-id)
  )
)

;; Update season information
(define-public (update-season
    (id uint)
    (start-month uint)
    (start-day uint)
    (end-month uint)
    (end-day uint)
    (climate-notes (string-ascii 200)))
  (let ((season-data (map-get? seasons { id: id })))
    (match season-data
      season (if (is-eq tx-sender (get added-by season))
        (begin
          (map-set seasons { id: id } {
            name: (get name season),
            start-month: start-month,
            start-day: start-day,
            end-month: end-month,
            end-day: end-day,
            region: (get region season),
            climate-notes: climate-notes,
            added-by: (get added-by season),
            added-at: (get added-at season)
          })
          (ok id)
        )
        (err u403))
      (err u404)
    )
  )
)

;; Create a preservation schedule
(define-public (create-schedule
    (technique-id uint)
    (season-id uint)
    (food-item (string-ascii 100))
    (optimal-start-month uint)
    (optimal-start-day uint)
    (optimal-end-month uint)
    (optimal-end-day uint)
    (notes (string-ascii 500)))
  (let
    ((new-id (+ (var-get last-schedule-id) u1)))
    (var-set last-schedule-id new-id)
    (map-set preservation-schedules { id: new-id } {
      technique-id: technique-id,
      season-id: season-id,
      food-item: food-item,
      optimal-start-month: optimal-start-month,
      optimal-start-day: optimal-start-day,
      optimal-end-month: optimal-end-month,
      optimal-end-day: optimal-end-day,
      notes: notes,
      created-by: tx-sender,
      created-at: block-height
    })
    (ok new-id)
  )
)

;; Get schedule details by ID
(define-read-only (get-schedule (id uint))
  (map-get? preservation-schedules { id: id })
)

;; Create a scheduled event
(define-public (create-event
    (schedule-id uint)
    (event-name (string-ascii 100))
    (event-date uint)
    (location (string-ascii 200))
    (participants (string-ascii 200)))
  (let
    ((new-id (+ (var-get last-event-id) u1)))
    (var-set last-event-id new-id)
    (map-set scheduled-events { id: new-id } {
      schedule-id: schedule-id,
      event-name: event-name,
      event-date: event-date,
      location: location,
      participants: participants,
      status: "scheduled",
      created-by: tx-sender,
      created-at: block-height
    })
    (ok new-id)
  )
)

;; Get event details by ID
(define-read-only (get-event (id uint))
  (map-get? scheduled-events { id: id })
)

;; Update event status
(define-public (update-event-status
    (id uint)
    (status (string-ascii 20)))
  (let ((event-data (map-get? scheduled-events { id: id })))
    (match event-data
      event (if (is-eq tx-sender (get created-by event))
        (begin
          (map-set scheduled-events { id: id } {
            schedule-id: (get schedule-id event),
            event-name: (get event-name event),
            event-date: (get event-date event),
            location: (get location event),
            participants: (get participants event),
            status: status,
            created-by: (get created-by event),
            created-at: (get created-at event)
          })
          (ok id)
        )
        (err u403))
      (err u404)
    )
  )
)

;; Check if a food item is in season - simplified version
(define-read-only (is-food-in-season (food-item (string-ascii 100)) (month uint) (day uint) (region (string-ascii 100)))
  ;; In a real implementation, this would check against seasons and schedules
  ;; For simplicity, we return a placeholder
  (ok false)
)

;; Get upcoming events - simplified version
(define-read-only (get-upcoming-events (current-date uint))
  ;; In a real implementation, this would filter events by date
  ;; For simplicity, we return an empty list
  (ok (list))
)

