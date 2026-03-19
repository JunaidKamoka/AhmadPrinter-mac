import Foundation

// MARK: - Field Model
struct TemplateField: Identifiable, Codable {
    var id = UUID()
    let key: String
    let label: String
    let placeholder: String
    let fieldType: FieldType
    var value: String = ""
    var isRequired: Bool

    enum FieldType: String, Codable {
        case singleLine, multiLine, date, currency, number, email, phone
    }

    init(key: String, label: String, placeholder: String = "",
         type: FieldType = .singleLine, required: Bool = false) {
        self.key = key
        self.label = label
        self.placeholder = placeholder.isEmpty ? label : placeholder
        self.fieldType = type
        self.isRequired = required
    }
}

// MARK: - Section Model
struct TemplateSection: Identifiable {
    let id = UUID()
    let title: String
    var fields: [TemplateField]
}

// MARK: - Template Model
struct PrintTemplate: Identifiable, Equatable {
    let templateID: String     // stable type key
    let name: String
    let category: Category
    let country: String
    let isPremium: Bool
    var sections: [TemplateSection]

    var id: String { "\(templateID)_\(country)" }

    enum Category: String, CaseIterable {
        case business  = "Business"
        case health    = "Health"
        case education = "Education"
        case legal     = "Legal"

        var icon: String {
            switch self {
            case .business:  return "briefcase.fill"
            case .health:    return "heart.text.square.fill"
            case .education: return "graduationcap.fill"
            case .legal:     return "building.columns.fill"
            }
        }
    }

    static func == (lhs: PrintTemplate, rhs: PrintTemplate) -> Bool {
        lhs.id == rhs.id
    }

    func value(for key: String) -> String {
        for section in sections {
            if let f = section.fields.first(where: { $0.key == key }) { return f.value }
        }
        return ""
    }
}

// MARK: - Factory
extension PrintTemplate {

    static let allCountries = ["USA", "UK", "Canada", "France", "Germany", "Italy"]

    private static func cur(_ country: String) -> String {
        switch country {
        case "UK": return "£"; case "Canada": return "CA$"
        case "France", "Germany", "Italy": return "€"
        default: return "$"
        }
    }
    private static func df(_ country: String) -> String { country == "USA" ? "MM/DD/YYYY" : "DD/MM/YYYY" }

    static let samples: [PrintTemplate] = allCountries.flatMap { templatesFor($0) }

    static func templates(for country: String, category: Category? = nil) -> [PrintTemplate] {
        let all = templatesFor(country)
        guard let cat = category else { return all }
        return all.filter { $0.category == cat }
    }

    // swiftlint:disable function_body_length
    static func templatesFor(_ c: String) -> [PrintTemplate] {
        let cur = cur(c), df = df(c)
        return [
            // ─── BUSINESS ────────────────────────────────────────
            PrintTemplate(templateID: "invoice", name: "Invoice", category: .business, country: c, isPremium: false, sections: [
                TemplateSection(title: "Seller", fields: [
                    TemplateField(key:"sellerName",    label:"Company / Name",      required:true),
                    TemplateField(key:"sellerAddress", label:"Address",              type:.multiLine),
                    TemplateField(key:"sellerEmail",   label:"Email",               type:.email),
                    TemplateField(key:"sellerPhone",   label:"Phone",               type:.phone),
                ]),
                TemplateSection(title: "Bill To", fields: [
                    TemplateField(key:"clientName",    label:"Client Name",          required:true),
                    TemplateField(key:"clientAddress", label:"Client Address",       type:.multiLine),
                    TemplateField(key:"clientEmail",   label:"Client Email",         type:.email),
                ]),
                TemplateSection(title: "Invoice Details", fields: [
                    TemplateField(key:"invoiceNo",   label:"Invoice #",             placeholder:"INV-001", required:true),
                    TemplateField(key:"invoiceDate", label:"Invoice Date (\(df))",  type:.date, required:true),
                    TemplateField(key:"dueDate",     label:"Due Date (\(df))",      type:.date),
                    TemplateField(key:"poNumber",    label:"PO Number",             placeholder:"PO-001"),
                ]),
                TemplateSection(title: "Line Items", fields: [
                    TemplateField(key:"lineItems",  label:"Description  |  Qty  |  Unit Price",  type:.multiLine, required:true),
                ]),
                TemplateSection(title: "Totals", fields: [
                    TemplateField(key:"subtotal",  label:"Subtotal (\(cur))",   type:.currency),
                    TemplateField(key:"taxRate",   label:"Tax Rate (%)",         placeholder:"10", type:.number),
                    TemplateField(key:"taxAmount", label:"Tax Amount (\(cur))",  type:.currency),
                    TemplateField(key:"total",     label:"Total (\(cur))",       type:.currency, required:true),
                ]),
                TemplateSection(title: "Notes & Payment", fields: [
                    TemplateField(key:"paymentTerms", label:"Payment Terms",     placeholder:"Net 30"),
                    TemplateField(key:"bankDetails",  label:"Bank / Payment Info", type:.multiLine),
                    TemplateField(key:"notes",        label:"Notes",              type:.multiLine),
                ]),
            ]),
            PrintTemplate(templateID: "purchase_order", name: "Purchase Order", category: .business, country: c, isPremium: false, sections: [
                TemplateSection(title: "PO Info", fields: [
                    TemplateField(key:"poNumber",      label:"PO Number",              placeholder:"PO-001", required:true),
                    TemplateField(key:"poDate",        label:"Date (\(df))",            type:.date, required:true),
                    TemplateField(key:"deliveryDate",  label:"Delivery Date (\(df))",   type:.date),
                ]),
                TemplateSection(title: "Buyer", fields: [
                    TemplateField(key:"buyerName",     label:"Company Name",            required:true),
                    TemplateField(key:"buyerAddress",  label:"Address",                 type:.multiLine),
                    TemplateField(key:"buyerContact",  label:"Contact Person"),
                    TemplateField(key:"buyerPhone",    label:"Phone",                   type:.phone),
                    TemplateField(key:"buyerEmail",    label:"Email",                   type:.email),
                ]),
                TemplateSection(title: "Supplier", fields: [
                    TemplateField(key:"supplierName",    label:"Supplier Name",         required:true),
                    TemplateField(key:"supplierAddress", label:"Supplier Address",      type:.multiLine),
                    TemplateField(key:"supplierContact", label:"Contact Person"),
                ]),
                TemplateSection(title: "Items & Terms", fields: [
                    TemplateField(key:"items",          label:"Item  |  Qty  |  Unit Price  |  Total", type:.multiLine, required:true),
                    TemplateField(key:"total",          label:"Order Total (\(cur))",    type:.currency, required:true),
                    TemplateField(key:"paymentTerms",   label:"Payment Terms",           placeholder:"Net 30"),
                    TemplateField(key:"shippingTerms",  label:"Shipping Terms",          placeholder:"FOB"),
                    TemplateField(key:"notes",          label:"Special Instructions",    type:.multiLine),
                ]),
            ]),
            PrintTemplate(templateID: "business_letter", name: "Business Letter", category: .business, country: c, isPremium: false, sections: [
                TemplateSection(title: "Sender", fields: [
                    TemplateField(key:"senderName",    label:"Your Name",             required:true),
                    TemplateField(key:"senderTitle",   label:"Title / Position"),
                    TemplateField(key:"senderCompany", label:"Company"),
                    TemplateField(key:"senderAddress", label:"Address",               type:.multiLine),
                    TemplateField(key:"senderEmail",   label:"Email",                 type:.email),
                    TemplateField(key:"senderPhone",   label:"Phone",                 type:.phone),
                    TemplateField(key:"letterDate",    label:"Date (\(df))",            type:.date, required:true),
                ]),
                TemplateSection(title: "Recipient", fields: [
                    TemplateField(key:"recipientName",    label:"Recipient Name",      required:true),
                    TemplateField(key:"recipientTitle",   label:"Title"),
                    TemplateField(key:"recipientCompany", label:"Company"),
                    TemplateField(key:"recipientAddress", label:"Address",             type:.multiLine),
                ]),
                TemplateSection(title: "Letter", fields: [
                    TemplateField(key:"subject",    label:"Subject",                   required:true),
                    TemplateField(key:"salutation", label:"Salutation",                placeholder:"Dear Sir/Madam,"),
                    TemplateField(key:"body",       label:"Body",                      type:.multiLine, required:true),
                    TemplateField(key:"closing",    label:"Closing",                   placeholder:"Sincerely,"),
                ]),
            ]),
            PrintTemplate(templateID: "receipt", name: "Receipt", category: .business, country: c, isPremium: false, sections: [
                TemplateSection(title: "Business", fields: [
                    TemplateField(key:"businessName",    label:"Business Name",        required:true),
                    TemplateField(key:"businessAddress", label:"Address",              type:.multiLine),
                    TemplateField(key:"businessPhone",   label:"Phone",               type:.phone),
                    TemplateField(key:"businessEmail",   label:"Email",               type:.email),
                ]),
                TemplateSection(title: "Receipt Details", fields: [
                    TemplateField(key:"receiptNo",    label:"Receipt #",              placeholder:"REC-001", required:true),
                    TemplateField(key:"receiptDate",  label:"Date (\(df))",            type:.date, required:true),
                    TemplateField(key:"customerName", label:"Customer Name"),
                    TemplateField(key:"items",        label:"Item  |  Qty  |  Price", type:.multiLine, required:true),
                    TemplateField(key:"subtotal",     label:"Subtotal (\(cur))",       type:.currency),
                    TemplateField(key:"tax",          label:"Tax (\(cur))",            type:.currency),
                    TemplateField(key:"total",        label:"Total (\(cur))",          type:.currency, required:true),
                    TemplateField(key:"paymentMethod",label:"Payment Method",          placeholder:"Cash / Card"),
                ]),
            ]),
            PrintTemplate(templateID: "quotation", name: "Quotation / Proposal", category: .business, country: c, isPremium: true, sections: [
                TemplateSection(title: "Company", fields: [
                    TemplateField(key:"companyName",    label:"Company Name",          required:true),
                    TemplateField(key:"companyAddress", label:"Address",               type:.multiLine),
                    TemplateField(key:"companyEmail",   label:"Email",                 type:.email),
                    TemplateField(key:"companyPhone",   label:"Phone",                 type:.phone),
                ]),
                TemplateSection(title: "Quote", fields: [
                    TemplateField(key:"quoteNo",     label:"Quote #",                 placeholder:"QUO-001", required:true),
                    TemplateField(key:"quoteDate",   label:"Date (\(df))",              type:.date),
                    TemplateField(key:"validUntil",  label:"Valid Until (\(df))",       type:.date),
                    TemplateField(key:"clientName",  label:"Client Name",              required:true),
                    TemplateField(key:"clientEmail", label:"Client Email",             type:.email),
                    TemplateField(key:"items",       label:"Description  |  Qty  |  Rate  |  Amount", type:.multiLine, required:true),
                    TemplateField(key:"total",       label:"Total (\(cur))",            type:.currency, required:true),
                    TemplateField(key:"terms",       label:"Terms & Conditions",       type:.multiLine),
                ]),
            ]),
            // ─── HEALTH ──────────────────────────────────────────
            PrintTemplate(templateID: "patient_intake", name: "Patient Intake Form", category: .health, country: c, isPremium: false, sections: [
                TemplateSection(title: "Patient Information", fields: [
                    TemplateField(key:"patientName", label:"Full Name",              required:true),
                    TemplateField(key:"dob",         label:"Date of Birth (\(df))",   type:.date, required:true),
                    TemplateField(key:"gender",      label:"Gender",                 placeholder:"Male / Female / Other"),
                    TemplateField(key:"address",     label:"Address",                type:.multiLine),
                    TemplateField(key:"phone",       label:"Phone",                  type:.phone, required:true),
                    TemplateField(key:"email",       label:"Email",                  type:.email),
                ]),
                TemplateSection(title: "Emergency Contact", fields: [
                    TemplateField(key:"emergencyName",     label:"Emergency Contact", required:true),
                    TemplateField(key:"emergencyRelation", label:"Relationship"),
                    TemplateField(key:"emergencyPhone",    label:"Phone",             type:.phone, required:true),
                ]),
                TemplateSection(title: "Insurance", fields: [
                    TemplateField(key:"insuranceProvider", label:"Insurance Provider"),
                    TemplateField(key:"policyNumber",      label:"Policy Number"),
                    TemplateField(key:"groupNumber",       label:"Group Number"),
                ]),
                TemplateSection(title: "Medical History", fields: [
                    TemplateField(key:"reasonForVisit", label:"Reason for Visit",    type:.multiLine, required:true),
                    TemplateField(key:"medications",    label:"Current Medications", type:.multiLine),
                    TemplateField(key:"allergies",      label:"Allergies",           type:.multiLine),
                    TemplateField(key:"conditions",     label:"Known Conditions",    type:.multiLine),
                ]),
            ]),
            PrintTemplate(templateID: "medical_consent", name: "Medical Consent Form", category: .health, country: c, isPremium: false, sections: [
                TemplateSection(title: "Patient", fields: [
                    TemplateField(key:"patientName", label:"Patient Full Name",      required:true),
                    TemplateField(key:"dob",         label:"Date of Birth (\(df))",   type:.date),
                    TemplateField(key:"address",     label:"Address",                type:.multiLine),
                ]),
                TemplateSection(title: "Treatment", fields: [
                    TemplateField(key:"procedure",     label:"Procedure / Treatment", type:.multiLine, required:true),
                    TemplateField(key:"provider",      label:"Healthcare Provider",   required:true),
                    TemplateField(key:"risks",         label:"Risks Explained",       type:.multiLine),
                    TemplateField(key:"alternatives",  label:"Alternatives Discussed",type:.multiLine),
                    TemplateField(key:"consentDate",   label:"Consent Date (\(df))",   type:.date, required:true),
                    TemplateField(key:"witness",       label:"Witness Name"),
                ]),
            ]),
            PrintTemplate(templateID: "prescription", name: "Prescription Form", category: .health, country: c, isPremium: true, sections: [
                TemplateSection(title: "Provider", fields: [
                    TemplateField(key:"providerName",    label:"Doctor / Provider Name", required:true),
                    TemplateField(key:"providerAddress", label:"Clinic / Hospital",       type:.multiLine),
                    TemplateField(key:"licenseNo",       label:"License Number",          required:true),
                    TemplateField(key:"phone",           label:"Phone",                   type:.phone),
                ]),
                TemplateSection(title: "Patient", fields: [
                    TemplateField(key:"patientName", label:"Patient Name",              required:true),
                    TemplateField(key:"dob",         label:"DOB (\(df))",               type:.date),
                    TemplateField(key:"address",     label:"Address",                   type:.multiLine),
                ]),
                TemplateSection(title: "Prescription", fields: [
                    TemplateField(key:"rxDate",       label:"Date (\(df))",              type:.date, required:true),
                    TemplateField(key:"medication",   label:"Medication",                required:true),
                    TemplateField(key:"dosage",       label:"Dosage",                    placeholder:"e.g., 500mg"),
                    TemplateField(key:"frequency",    label:"Frequency",                 placeholder:"Twice daily"),
                    TemplateField(key:"duration",     label:"Duration",                  placeholder:"7 days"),
                    TemplateField(key:"refills",      label:"Refills",                   placeholder:"0", type:.number),
                    TemplateField(key:"instructions", label:"Special Instructions",      type:.multiLine),
                ]),
            ]),
            PrintTemplate(templateID: "insurance_claim", name: "Insurance Claim", category: .health, country: c, isPremium: true, sections: [
                TemplateSection(title: "Claimant", fields: [
                    TemplateField(key:"patientName",  label:"Patient Name",            required:true),
                    TemplateField(key:"dob",          label:"DOB (\(df))",              type:.date),
                    TemplateField(key:"policyNumber", label:"Policy Number",            required:true),
                    TemplateField(key:"memberID",     label:"Member ID"),
                ]),
                TemplateSection(title: "Claim", fields: [
                    TemplateField(key:"serviceDate",   label:"Date of Service (\(df))", type:.date, required:true),
                    TemplateField(key:"provider",      label:"Provider / Facility",     required:true),
                    TemplateField(key:"diagnosis",     label:"Diagnosis / ICD Code"),
                    TemplateField(key:"description",   label:"Description of Service",  type:.multiLine),
                    TemplateField(key:"amount",        label:"Amount Billed (\(cur))",   type:.currency, required:true),
                ]),
            ]),
            // ─── EDUCATION ───────────────────────────────────────
            PrintTemplate(templateID: "lesson_plan", name: "Lesson Plan", category: .education, country: c, isPremium: false, sections: [
                TemplateSection(title: "Course", fields: [
                    TemplateField(key:"subject",    label:"Subject",               required:true),
                    TemplateField(key:"gradeLevel", label:"Grade / Level"),
                    TemplateField(key:"teacher",    label:"Teacher Name",          required:true),
                    TemplateField(key:"date",       label:"Date (\(df))",            type:.date),
                    TemplateField(key:"duration",   label:"Duration (minutes)",    type:.number),
                ]),
                TemplateSection(title: "Lesson", fields: [
                    TemplateField(key:"title",        label:"Lesson Title",         required:true),
                    TemplateField(key:"objectives",   label:"Learning Objectives",  type:.multiLine, required:true),
                    TemplateField(key:"materials",    label:"Materials Needed",     type:.multiLine),
                    TemplateField(key:"introduction", label:"Introduction / Hook",  type:.multiLine),
                    TemplateField(key:"mainActivity", label:"Main Activity",        type:.multiLine, required:true),
                    TemplateField(key:"assessment",   label:"Assessment / Closure", type:.multiLine),
                    TemplateField(key:"homework",     label:"Homework",             type:.multiLine),
                ]),
            ]),
            PrintTemplate(templateID: "report_card", name: "Report Card", category: .education, country: c, isPremium: false, sections: [
                TemplateSection(title: "School Info", fields: [
                    TemplateField(key:"schoolName",   label:"School Name",          required:true),
                    TemplateField(key:"studentName",  label:"Student Name",         required:true),
                    TemplateField(key:"gradeLevel",   label:"Grade / Year"),
                    TemplateField(key:"teacher",      label:"Class Teacher"),
                    TemplateField(key:"reportPeriod", label:"Report Period",         placeholder:"Term 1 / Semester 1"),
                    TemplateField(key:"academicYear", label:"Academic Year"),
                ]),
                TemplateSection(title: "Grades", fields: [
                    TemplateField(key:"grades",         label:"Subject  |  Grade  |  Comments", type:.multiLine, required:true),
                    TemplateField(key:"attendance",     label:"Attendance"),
                    TemplateField(key:"conduct",        label:"Conduct / Behaviour"),
                    TemplateField(key:"teacherComment", label:"Teacher's Comments",  type:.multiLine),
                ]),
            ]),
            PrintTemplate(templateID: "assignment", name: "Assignment Sheet", category: .education, country: c, isPremium: false, sections: [
                TemplateSection(title: "Details", fields: [
                    TemplateField(key:"subject",     label:"Subject",               required:true),
                    TemplateField(key:"teacher",     label:"Teacher"),
                    TemplateField(key:"dueDate",     label:"Due Date (\(df))",        type:.date, required:true),
                    TemplateField(key:"totalMarks",  label:"Total Marks",            type:.number),
                    TemplateField(key:"studentName", label:"Student Name",           required:true),
                    TemplateField(key:"studentID",   label:"Student ID"),
                ]),
                TemplateSection(title: "Instructions", fields: [
                    TemplateField(key:"title",        label:"Assignment Title",      required:true),
                    TemplateField(key:"description",  label:"Description",           type:.multiLine, required:true),
                    TemplateField(key:"requirements", label:"Requirements",          type:.multiLine),
                    TemplateField(key:"resources",    label:"Resources / References",type:.multiLine),
                ]),
            ]),
            // ─── LEGAL ───────────────────────────────────────────
            PrintTemplate(templateID: "nda", name: "Non-Disclosure Agreement", category: .legal, country: c, isPremium: true, sections: [
                TemplateSection(title: "Parties", fields: [
                    TemplateField(key:"disclosingParty",   label:"Disclosing Party",   required:true),
                    TemplateField(key:"disclosingAddress", label:"Address",             type:.multiLine),
                    TemplateField(key:"receivingParty",    label:"Receiving Party",     required:true),
                    TemplateField(key:"receivingAddress",  label:"Address",             type:.multiLine),
                ]),
                TemplateSection(title: "Terms", fields: [
                    TemplateField(key:"effectiveDate",    label:"Effective Date (\(df))",   type:.date, required:true),
                    TemplateField(key:"expirationDate",   label:"Expiration Date (\(df))",  type:.date),
                    TemplateField(key:"purpose",          label:"Purpose of Agreement",      type:.multiLine, required:true),
                    TemplateField(key:"confidentialInfo", label:"Definition of Confidential Info", type:.multiLine),
                    TemplateField(key:"exclusions",       label:"Exclusions",                type:.multiLine),
                    TemplateField(key:"jurisdiction",     label:"Governing Law",             placeholder:c),
                ]),
            ]),
            PrintTemplate(templateID: "lease_agreement", name: "Lease Agreement", category: .legal, country: c, isPremium: true, sections: [
                TemplateSection(title: "Parties", fields: [
                    TemplateField(key:"landlordName",    label:"Landlord Name",          required:true),
                    TemplateField(key:"landlordAddress", label:"Landlord Address",       type:.multiLine),
                    TemplateField(key:"tenantName",      label:"Tenant Name(s)",         required:true),
                    TemplateField(key:"tenantPhone",     label:"Tenant Phone",           type:.phone),
                    TemplateField(key:"tenantEmail",     label:"Tenant Email",           type:.email),
                ]),
                TemplateSection(title: "Property & Rent", fields: [
                    TemplateField(key:"propertyAddress", label:"Property Address",       type:.multiLine, required:true),
                    TemplateField(key:"leaseStart",      label:"Lease Start (\(df))",     type:.date, required:true),
                    TemplateField(key:"leaseEnd",        label:"Lease End (\(df))",       type:.date, required:true),
                    TemplateField(key:"rentAmount",      label:"Monthly Rent (\(cur))",   type:.currency, required:true),
                    TemplateField(key:"dueDay",          label:"Rent Due Day",            placeholder:"1st of each month"),
                    TemplateField(key:"securityDeposit", label:"Security Deposit (\(cur))",type:.currency),
                    TemplateField(key:"additionalTerms", label:"Additional Terms",        type:.multiLine),
                    TemplateField(key:"jurisdiction",    label:"Governing Law",           placeholder:c),
                ]),
            ]),
            PrintTemplate(templateID: "employment_contract", name: "Employment Contract", category: .legal, country: c, isPremium: true, sections: [
                TemplateSection(title: "Employer", fields: [
                    TemplateField(key:"employerName",    label:"Employer / Company",     required:true),
                    TemplateField(key:"employerAddress", label:"Company Address",        type:.multiLine),
                ]),
                TemplateSection(title: "Employee", fields: [
                    TemplateField(key:"employeeName",   label:"Employee Full Name",      required:true),
                    TemplateField(key:"employeeAddress",label:"Address",                 type:.multiLine),
                    TemplateField(key:"jobTitle",       label:"Job Title",               required:true),
                    TemplateField(key:"department",     label:"Department"),
                    TemplateField(key:"startDate",      label:"Start Date (\(df))",       type:.date, required:true),
                ]),
                TemplateSection(title: "Compensation", fields: [
                    TemplateField(key:"salary",          label:"Salary (\(cur))",         type:.currency, required:true),
                    TemplateField(key:"payFrequency",    label:"Pay Frequency",           placeholder:"Monthly / Bi-weekly"),
                    TemplateField(key:"workHours",       label:"Working Hours",           placeholder:"40 hrs/week"),
                    TemplateField(key:"benefits",        label:"Benefits",                type:.multiLine),
                    TemplateField(key:"contractType",    label:"Employment Type",         placeholder:"Full-time / Part-time"),
                    TemplateField(key:"noticePeriod",    label:"Notice Period"),
                    TemplateField(key:"additionalTerms", label:"Additional Terms",        type:.multiLine),
                    TemplateField(key:"jurisdiction",    label:"Governing Law",           placeholder:c),
                ]),
            ]),
            PrintTemplate(templateID: "service_agreement", name: "Service Agreement", category: .legal, country: c, isPremium: false, sections: [
                TemplateSection(title: "Parties", fields: [
                    TemplateField(key:"providerName",    label:"Service Provider",       required:true),
                    TemplateField(key:"providerAddress", label:"Provider Address",       type:.multiLine),
                    TemplateField(key:"clientName",      label:"Client Name",            required:true),
                    TemplateField(key:"clientAddress",   label:"Client Address",         type:.multiLine),
                ]),
                TemplateSection(title: "Services & Payment", fields: [
                    TemplateField(key:"startDate",       label:"Start Date (\(df))",      type:.date, required:true),
                    TemplateField(key:"endDate",         label:"End Date (\(df))",        type:.date),
                    TemplateField(key:"servicesDesc",    label:"Description of Services",type:.multiLine, required:true),
                    TemplateField(key:"feeAmount",       label:"Fee (\(cur))",            type:.currency, required:true),
                    TemplateField(key:"paymentSchedule", label:"Payment Schedule"),
                    TemplateField(key:"terminationClause",label:"Termination Clause",    type:.multiLine),
                    TemplateField(key:"jurisdiction",    label:"Governing Law",           placeholder:c),
                ]),
            ]),
        ]
    }
    // swiftlint:enable function_body_length
}
