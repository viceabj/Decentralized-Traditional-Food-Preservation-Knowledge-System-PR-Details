import { describe, it, expect, beforeEach } from "vitest"

// Mock implementation for testing Clarity contracts
const mockPrincipal = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
const mockStudentPrincipal = "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG"
const mockBlockHeight = 100

// Mock state
let lastTeacherId = 0
let lastClassId = 0
let lastCertificationId = 0
let lastResourceId = 0
const teachers = new Map()
const classes = new Map()
const classParticipants = new Map()
const certifications = new Map()
const educationalResources = new Map()

// Mock contract functions
const registerTeacher = (name, expertise, experienceYears, region, contactInfo, bio) => {
  const newId = lastTeacherId + 1
  lastTeacherId = newId
  
  teachers.set(newId, {
    owner: mockPrincipal,
    name,
    expertise,
    experienceYears,
    region,
    contactInfo,
    bio,
    registrationDate: mockBlockHeight,
  })
  
  return { value: newId }
}

const getTeacher = (id) => {
  const teacher = teachers.get(id)
  return teacher ? teacher : null
}

const updateTeacher = (id, expertise, experienceYears, contactInfo, bio) => {
  const teacher = teachers.get(id)
  if (!teacher) return { error: 404 }
  if (teacher.owner !== mockPrincipal) return { error: 403 }
  
  teachers.set(id, {
    ...teacher,
    expertise,
    experienceYears,
    contactInfo,
    bio,
  })
  
  return { value: id }
}

const createClass = (
    teacherId,
    techniqueId,
    title,
    description,
    maxParticipants,
    durationHours,
    prerequisites,
    materialsNeeded,
    location,
    scheduledDate,
) => {
  const teacher = teachers.get(teacherId)
  if (!teacher) return { error: 404 }
  if (teacher.owner !== mockPrincipal) return { error: 403 }
  
  const newId = lastClassId + 1
  lastClassId = newId
  
  classes.set(newId, {
    teacherId,
    techniqueId,
    title,
    description,
    maxParticipants,
    durationHours,
    prerequisites,
    materialsNeeded,
    location,
    scheduledDate,
    status: "open",
    createdAt: mockBlockHeight,
  })
  
  return { value: newId }
}

const getClass = (id) => {
  const classInfo = classes.get(id)
  return classInfo ? classInfo : null
}

const registerForClass = (classId, notes, participant = mockStudentPrincipal) => {
  const classInfo = classes.get(classId)
  if (!classInfo) return { error: 404 }
  if (classInfo.status !== "open") return { error: 400 }
  
  const key = `${classId}-${participant}`
  classParticipants.set(key, {
    registrationDate: mockBlockHeight,
    attendanceStatus: "registered",
    notes,
  })
  
  return { value: { classId, participant } }
}

const updateClassStatus = (classId, status) => {
  const classInfo = classes.get(classId)
  if (!classInfo) return { error: 404 }
  
  const teacher = teachers.get(classInfo.teacherId)
  if (!teacher) return { error: 404 }
  if (teacher.owner !== mockPrincipal) return { error: 403 }
  
  classes.set(classId, {
    ...classInfo,
    status,
  })
  
  return { value: classId }
}

const issueCertification = (recipient, teacherId, techniqueId, expiryDate, skillLevel, assessmentNotes) => {
  const teacher = teachers.get(teacherId)
  if (!teacher) return { error: 404 }
  if (teacher.owner !== mockPrincipal) return { error: 403 }
  
  const newId = lastCertificationId + 1
  lastCertificationId = newId
  
  certifications.set(newId, {
    recipient,
    teacherId,
    techniqueId,
    certificationDate: mockBlockHeight,
    expiryDate,
    skillLevel,
    assessmentNotes,
  })
  
  return { value: newId }
}

const getCertification = (id) => {
  const certification = certifications.get(id)
  return certification ? certification : null
}

const addEducationalResource = (title, description, resourceType, techniqueId, contentHash) => {
  const newId = lastResourceId + 1
  lastResourceId = newId
  
  educationalResources.set(newId, {
    title,
    description,
    resourceType,
    techniqueId,
    contentHash,
    author: mockPrincipal,
    createdAt: mockBlockHeight,
  })
  
  return { value: newId }
}

const getEducationalResource = (id) => {
  const resource = educationalResources.get(id)
  return resource ? resource : null
}

describe("Knowledge Transfer Contract", () => {
  beforeEach(() => {
    // Reset state before each test
    lastTeacherId = 0
    lastClassId = 0
    lastCertificationId = 0
    lastResourceId = 0
    teachers.clear()
    classes.clear()
    classParticipants.clear()
    certifications.clear()
    educationalResources.clear()
  })
  
  it("should register a new teacher", () => {
    const result = registerTeacher(
        "Maria Garcia",
        "Traditional fermentation, pickling, and canning",
        35,
        "Southern Europe",
        "maria@example.com",
        "Third-generation preserver with expertise in Mediterranean preservation techniques",
    )
    
    expect(result.value).toBe(1)
    expect(teachers.size).toBe(1)
    
    const teacher = getTeacher(1)
    expect(teacher).not.toBeNull()
    expect(teacher.name).toBe("Maria Garcia")
    expect(teacher.expertise).toBe("Traditional fermentation, pickling, and canning")
    expect(teacher.experienceYears).toBe(35)
    expect(teacher.region).toBe("Southern Europe")
  })
  
  it("should update teacher information", () => {
    // First register a teacher
    registerTeacher(
        "Maria Garcia",
        "Traditional fermentation, pickling, and canning",
        35,
        "Southern Europe",
        "maria@example.com",
        "Third-generation preserver with expertise in Mediterranean preservation techniques",
    )
    
    // Then update it
    const updateResult = updateTeacher(
        1,
        "Traditional fermentation, pickling, canning, and olive curing",
        40,
        "maria@example.com, +1-555-123-4567",
        'Third-generation preserver with expertise in Mediterranean preservation techniques. Author of "Mediterranean Preservation Methods"',
    )
    
    expect(updateResult.value).toBe(1)
    
    const teacher = getTeacher(1)
    expect(teacher.expertise).toBe("Traditional fermentation, pickling, canning, and olive curing")
    expect(teacher.experienceYears).toBe(40)
    expect(teacher.contactInfo).toBe("maria@example.com, +1-555-123-4567")
    expect(teacher.bio).toContain('Author of "Mediterranean Preservation Methods"')
  })
  
  it("should create a class", () => {
    // First register a teacher
    registerTeacher(
        "Maria Garcia",
        "Traditional fermentation, pickling, and canning",
        35,
        "Southern Europe",
        "maria@example.com",
        "Third-generation preserver with expertise in Mediterranean preservation techniques",
    )
    
    // Then create a class
    const result = createClass(
        1, // teacher ID
        1, // technique ID (fermentation)
        "Introduction to Lacto-Fermentation",
        "Learn the basics of vegetable fermentation using salt brine",
        15, // max participants
        3, // duration hours
        "None, beginners welcome",
        "Vegetables, salt, jars (provided)",
        "Community Kitchen, 456 Oak St",
        1630444800, // September 1, 2021 (example timestamp)
    )
    
    expect(result.value).toBe(1)
    expect(classes.size).toBe(1)
    
    const classInfo = getClass(1)
    expect(classInfo).not.toBeNull()
    expect(classInfo.teacherId).toBe(1)
    expect(classInfo.title).toBe("Introduction to Lacto-Fermentation")
    expect(classInfo.maxParticipants).toBe(15)
    expect(classInfo.durationHours).toBe(3)
    expect(classInfo.status).toBe("open")
  })
  
  it("should allow registration for a class", () => {
    // Setup teacher and class
    registerTeacher(
        "Maria Garcia",
        "Traditional fermentation, pickling, and canning",
        35,
        "Southern Europe",
        "maria@example.com",
        "Third-generation preserver with expertise in Mediterranean preservation techniques",
    )
    
    createClass(
        1, // teacher ID
        1, // technique ID (fermentation)
        "Introduction to Lacto-Fermentation",
        "Learn the basics of vegetable fermentation using salt brine",
        15, // max participants
        3, // duration hours
        "None, beginners welcome",
        "Vegetables, salt, jars (provided)",
        "Community Kitchen, 456 Oak St",
        1630444800, // September 1, 2021 (example timestamp)
    )
    
    // Register for the class
    const result = registerForClass(
        1, // class ID
        "Interested in learning about kimchi specifically",
    )
    
    expect(result.value).toEqual({ classId: 1, participant: mockStudentPrincipal })
    
    // Update class status
    const updateResult = updateClassStatus(1, "full")
    
    expect(updateResult.value).toBe(1)
    
    const classInfo = getClass(1)
    expect(classInfo.status).toBe("full")
  })
  
  it("should issue certifications", () => {
    // Setup teacher
    registerTeacher(
        "Maria Garcia",
        "Traditional fermentation, pickling, and canning",
        35,
        "Southern Europe",
        "maria@example.com",
        "Third-generation preserver with expertise in Mediterranean preservation techniques",
    )
    
    // Issue certification
    const result = issueCertification(
        mockStudentPrincipal,
        1, // teacher ID
        1, // technique ID (fermentation)
        mockBlockHeight + 31536000, // 1 year expiry
        "Intermediate",
        "Successfully demonstrated understanding of fermentation principles and completed three different fermentation projects",
    )
    
    expect(result.value).toBe(1)
    expect(certifications.size).toBe(1)
    
    const certification = getCertification(1)
    expect(certification).not.toBeNull()
    expect(certification.recipient).toBe(mockStudentPrincipal)
    expect(certification.teacherId).toBe(1)
    expect(certification.techniqueId).toBe(1)
    expect(certification.skillLevel).toBe("Intermediate")
    expect(certification.assessmentNotes).toContain("Successfully demonstrated understanding")
  })
  
  it("should add educational resources", () => {
    const result = addEducationalResource(
        "Fermentation Safety Guide",
        "Comprehensive guide to ensuring safety in fermented foods",
        "PDF",
        1, // technique ID (fermentation)
        "bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi", // example IPFS hash
    )
    
    expect(result.value).toBe(1)
    expect(educationalResources.size).toBe(1)
    
    const resource = getEducationalResource(1)
    expect(resource).not.toBeNull()
    expect(resource.title).toBe("Fermentation Safety Guide")
    expect(resource.resourceType).toBe("PDF")
    expect(resource.techniqueId).toBe(1)
    expect(resource.author).toBe(mockPrincipal)
  })
})

