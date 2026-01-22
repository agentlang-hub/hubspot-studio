module hubspot

import "resolver.js" @as hsr

entity HubSpotConfig {
    id UUID @id @default(uuid()),
    accessToken String,
    corsProxyUrl String @optional,
    apiTimeout Int @optional,
    pollIntervalMinutes Int @optional,
    searchResultLimit Int @optional,
    name String @optional,
    description String @optional,
    active Boolean @optional
}

entity Contact {
    id String @id @default(uuid()),
    created_date String @optional,
    first_name String @optional,
    last_name String @optional,
    email String @optional,
    job_title String @optional,
    last_contacted String @optional,
    last_activity_date String @optional,
    lead_status String @optional,
    lifecycle_stage String @optional,
    salutation String @optional,
    mobile_phone_number String @optional,
    website_url String @optional,
    owner String @optional,
    company String @optional,
    properties Map @optional,
    createdAt String @optional,
    updatedAt String @optional,
    archived Boolean @optional,
    url String @optional
}

entity Company {
    id String @id,
    created_date String @optional,
    name String @optional,
    domain String @optional,
    industry String @optional,
    description String @optional,
    country String @optional,
    city String @optional,
    lead_status String @optional,
    lifecycle_stage String @optional,
    ai_lead_score Int @optional,
    owner String @optional,
    year_founded String @optional,
    website_url String @optional,
    properties Map @optional,
    createdAt String @optional,
    updatedAt String @optional,
    archived Boolean @optional,
    url String @optional
}

entity Deal {
    id String @id @default(uuid()),
    created_date String @optional,
    deal_name String @optional,
    deal_stage String @optional,
    amount String @optional,
    close_date String @optional,
    deal_type String @optional,
    description String @optional,
    owner String @optional,
    pipeline String @optional,
    priority String @optional,
    associated_company String @optional,
    associated_contacts String[] @optional,
    properties Map @optional,
    createdAt String @optional,
    updatedAt String @optional,
    archived Boolean @optional
}

entity Owner {
    id String @id @default(uuid()),
    email String @optional,
    first_name String @optional,
    last_name String @optional,
    user_id Int @optional,
    created_at String @optional,
    updated_at String @optional,
    archived Boolean @optional
}

entity Task {
    id String @id @default(uuid()),
    created_date String @optional,
    hs_task_type String @optional,
    hs_task_subject String @optional,
    hs_task_priority String @optional,
    hs_timestamp String @optional,
    hs_task_status String @optional,
    hs_task_body String @optional,
    hubspot_owner_id String @optional,
    hs_task_reminders String @optional,
    associated_contacts String[] @optional,
    associated_company String @optional,
    associated_deal String @optional,
    properties Map @optional,
    createdAt String @optional,
    updatedAt String @optional,
    archived Boolean @optional
}

entity Note {
    id String @id @default(uuid()),
    created_date String @optional,
    timestamp String @optional,
    note_body String @optional,
    owner String @optional,
    associated_contact String @optional,
    associated_contacts String[] @optional,
    associated_company String @optional,
    associated_deal String @optional,
    properties Map @optional,
    createdAt String @optional,
    updatedAt String @optional,
    archived Boolean @optional
}

entity Meeting {
    id String @id @default(uuid()),
    meeting_date String @optional,
    timestamp String @optional,
    meeting_title String @optional,
    owner String @optional,
    meeting_body String @optional,
    internal_meeting_notes String @optional,
    meeting_external_url String @optional,
    meeting_location String @optional,
    meeting_start_time String @optional,
    meeting_end_time String @optional,
    meeting_outcome String @optional,
    activity_type String @optional,
    attachment_ids String @optional,
    associated_contacts String[] @optional,
    associated_companies String[] @optional,
    associated_deals String[] @optional,
    properties Map @optional,
    createdAt String @optional,
    updatedAt String @optional,
    archived Boolean @optional
}

entity MeetingAssociation {
    id String @id @default(uuid()),
    meeting_id String,
    to_object_type String,
    to_object_id String,
    association_type_id Int @optional
}

entity MeetingDisassociation {
    id String @id @default(uuid()),
    meeting_id String,
    to_object_type String,
    to_object_id String,
    association_type_id Int @optional
}

entity MeetingAssociationQuery {
    id String @id @default(uuid()),
    meeting_id String,
    to_object_type String
}

resolver hubspot1 [hubspot/Contact] {
    create hsr.createContact,
    query hsr.queryContact,
    update hsr.updateContact,
    delete hsr.deleteContact,
    subscribe hsr.subsContacts
}

resolver hubspot2 [hubspot/Company] {
    create hsr.createCompany,
    query hsr.queryCompany,
    update hsr.updateCompany,
    delete hsr.deleteCompany,
    subscribe hsr.subsCompanies
}

resolver hubspot3 [hubspot/Deal] {
    create hsr.createDeal,
    query hsr.queryDeal,
    update hsr.updateDeal,
    delete hsr.deleteDeal,
    subscribe hsr.subsDeals
}

resolver hubspot4 [hubspot/Owner] {
    create hsr.createOwner,
    query hsr.queryOwner,
    update hsr.updateOwner,
    delete hsr.deleteOwner,
    subscribe hsr.subsOwners
}

resolver hubspot5 [hubspot/Task] {
    create hsr.createTask,
    query hsr.queryTask,
    update hsr.updateTask,
    delete hsr.deleteTask,
    subscribe hsr.subsTasks
}

resolver hubspot6 [hubspot/Meeting] {
    create hsr.createMeeting,
    query hsr.queryMeeting,
    update hsr.updateMeeting,
    delete hsr.deleteMeeting,
    subscribe hsr.subsMeetings
}

resolver hubspot7 [hubspot/Note] {
    create hsr.createNote,
    query hsr.queryNote,
    update hsr.updateNote,
    delete hsr.deleteNote,
    subscribe hsr.subsNotes
}

resolver hubspot8 [hubspot/MeetingAssociation] {
    create hsr.associateMeeting
}

resolver hubspot9 [hubspot/MeetingDisassociation] {
    create hsr.disassociateMeeting
}

resolver hubspot10 [hubspot/MeetingAssociationQuery] {
    query hsr.getMeetingAssociationsResolver
}

record CRMContext {
    existingCompanyId String @optional,
    existingCompanyName String @optional,
    existingContactId String @optional,
    hasCompany Boolean @default(false),
    hasContact Boolean @default(false)
}

event fetchCRMContext {
    companyDomain String @optional,
    contactEmail String @optional
}

workflow fetchCRMContext {
    "" @as existingCompanyId;
    "" @as existingCompanyName;
    "" @as existingContactId;
    false @as hasCompany;
    false @as hasContact;
    
    if (fetchCRMContext.companyDomain) {
        {Company {domain? fetchCRMContext.companyDomain}} @as companies;
        
        if (companies.length > 0) {
            companies @as [comp, __];
            comp.id @as existingCompanyId;
            comp.name @as existingCompanyName;
            true @as hasCompany
        }
    };
    
    if (fetchCRMContext.contactEmail) {
        {Contact {email? fetchCRMContext.contactEmail}} @as contacts;
        
        if (contacts.length > 0) {
            contacts @as [cont, __];
            cont.id @as existingContactId;
            true @as hasContact
        }
    };
    
    {CRMContext {
        existingCompanyId existingCompanyId,
        existingCompanyName existingCompanyName,
        existingContactId existingContactId,
        hasCompany hasCompany,
        hasContact hasContact
    }}
}

event upsertCompany {
    name String,
    domain String,
    lifecycle_stage String @optional,
    ai_lead_score Int @optional
}

workflow upsertCompany {
    console.log("🏢 HUBSPOT: upsertCompany called with domain: " + upsertCompany.domain + ", name: " + upsertCompany.name);
    
    {Company {domain? upsertCompany.domain}} @as companies;
    
    console.log("🏢 HUBSPOT: Query returned " + companies.length + " companies");
    
    if (companies.length > 0) {
        companies @as [company, __];
        
        console.log("🏢 HUBSPOT: Updating existing company ID: " + company.id);
        
        {Company {
            id? company.id,
            lifecycle_stage upsertCompany.lifecycle_stage,
            ai_lead_score upsertCompany.ai_lead_score
        }} @as result;
        
        console.log("🏢 HUBSPOT: Company updated, ID: " + result.id);
        result
    } else {
        console.log("🏢 HUBSPOT: Creating new company");
        
        {Company {
            domain upsertCompany.domain,
            name upsertCompany.name,
            lifecycle_stage upsertCompany.lifecycle_stage,
            ai_lead_score upsertCompany.ai_lead_score
        }} @as result;
        
        console.log("🏢 HUBSPOT: Company created, ID: " + result.id);
        result
    }
}

event upsertContact {
    email String,
    first_name String,
    last_name String,
    company String @optional
}

workflow upsertContact {
    console.log("👤 HUBSPOT: upsertContact workflow executing");
    console.log("👤 HUBSPOT: Received parameters:");
    console.log("  - email parameter value: " + upsertContact.email);
    console.log("  - first_name parameter value: " + upsertContact.first_name);
    console.log("  - last_name parameter value: " + upsertContact.last_name);
    console.log("  - company parameter value: " + upsertContact.company);
    console.log("👤 HUBSPOT: About to query Contact with email filter");
    
    {Contact {email? upsertContact.email}} @as contacts;
    
    console.log("👤 HUBSPOT: Query completed, returned " + contacts.length + " contacts");
    
    if (contacts.length > 0) {
        contacts @as [contact, __];
        console.log("👤 HUBSPOT: Found existing contact - ID: " + contact.id + ", Email: " + contact.email);
        contact
    } else {
        console.log("👤 HUBSPOT: No match found, creating new contact");
        console.log("  email: " + upsertContact.email);
        console.log("  first_name: " + upsertContact.first_name);
        console.log("  last_name: " + upsertContact.last_name);
        console.log("  company: " + upsertContact.company);
        
        {Contact {
            email upsertContact.email,
            first_name upsertContact.first_name,
            last_name upsertContact.last_name,
            company upsertContact.company
        }} @as result;
        
        console.log("👤 HUBSPOT: Contact created, ID: " + result.id);
        result
    }
}

record CRMUpdateResult {
    companyId String @optional,
    companyName String @optional,
    contactId String,
    contactEmail String,
    dealId String @optional,
    dealCreated Boolean @default(false),
    noteId String,
    taskId String
}

event updateCRMFromLead {
    shouldCreateCompany Boolean,
    shouldCreateContact Boolean,
    shouldCreateDeal Boolean,
    companyName String @optional,
    companyDomain String @optional,
    contactEmail String,
    contactFirstName String,
    contactLastName String,
    leadStage String,
    leadScore Int,
    dealStage String @optional,
    dealName String @optional,
    reasoning String,
    nextAction String,
    ownerId String,
    existingCompanyId String @optional,
    existingContactId String @optional
}

workflow updateCRMFromLead {
    console.log("=== HUBSPOT updateCRMFromLead START ===");

    updateCRMFromLead.shouldCreateCompany @as flagCompany;
    updateCRMFromLead.shouldCreateContact @as flagContact;
    updateCRMFromLead.shouldCreateDeal @as flagDeal;
    updateCRMFromLead.contactEmail @as emailParam;
    updateCRMFromLead.contactFirstName @as firstNameParam;
    updateCRMFromLead.companyDomain @as domainParam;

    console.log("FLAGS: Company=" + flagCompany + " Contact=" + flagContact + " Deal=" + flagDeal);
    console.log("CONTACT: email=" + emailParam + " firstName=" + firstNameParam);
    console.log("COMPANY: domain=" + domainParam);

    "" @as companyId;
    "" @as companyName;

    if (updateCRMFromLead.shouldCreateCompany) {
        console.log("🏢 HUBSPOT: Creating/updating company");

        if (updateCRMFromLead.leadStage == "QUALIFIED") {
            "salesqualifiedlead" @as lifecycle
        } else if (updateCRMFromLead.leadStage == "ENGAGED") {
            "marketingqualifiedlead" @as lifecycle
        } else {
            "lead" @as lifecycle
        };

        {upsertCompany {
            name updateCRMFromLead.companyName,
            domain updateCRMFromLead.companyDomain,
            lifecycle_stage lifecycle,
            ai_lead_score updateCRMFromLead.leadScore
        }} @as company;

        company.id @as companyId;
        company.name @as companyName;

        console.log("🏢 HUBSPOT: Company result - ID: " + companyId + ", Name: " + companyName)
    } else {
        console.log("🏢 HUBSPOT: Skipping company creation");

        if (updateCRMFromLead.existingCompanyId) {
            updateCRMFromLead.existingCompanyId @as companyId;
            updateCRMFromLead.companyName @as companyName;
            console.log("🏢 HUBSPOT: Using existing company ID: " + companyId)
        } else {
            nil @as companyId;
            "" @as companyName;
            console.log("🏢 HUBSPOT: No company ID available (neither created nor existing)")
        }
    };

    if (updateCRMFromLead.shouldCreateContact) {
        console.log("👤 HUBSPOT: shouldCreateContact is TRUE, calling upsertContact");
        console.log("  Passing email: '" + updateCRMFromLead.contactEmail + "'");
        console.log("  Passing first_name: '" + updateCRMFromLead.contactFirstName + "'");
        console.log("  Passing last_name: '" + updateCRMFromLead.contactLastName + "'");
        console.log("  Passing companyId: '" + companyId + "'");

        {upsertContact {
            email updateCRMFromLead.contactEmail,
            first_name updateCRMFromLead.contactFirstName,
            last_name updateCRMFromLead.contactLastName,
            company companyId
        }} @as contact;

        console.log("👤 HUBSPOT: upsertContact returned - ID: " + contact.id + ", Email: " + contact.email)
    } else {
        console.log("👤 HUBSPOT: shouldCreateContact is FALSE");

        if (updateCRMFromLead.existingContactId) {
            console.log("👤 HUBSPOT: Fetching existing contact ID: " + updateCRMFromLead.existingContactId);

            {Contact {id? updateCRMFromLead.existingContactId}} @as existingContacts;
            existingContacts @as [contact, __];

            console.log("👤 HUBSPOT: Fetched existing contact - ID: " + contact.id)
        } else {
            console.log("⚠️  HUBSPOT: No existing contact ID provided but shouldCreateContact is false - this is an error state");
            console.log("⚠️  HUBSPOT: Creating contact anyway with email: " + updateCRMFromLead.contactEmail);

            {upsertContact {
                email updateCRMFromLead.contactEmail,
                first_name updateCRMFromLead.contactFirstName,
                last_name updateCRMFromLead.contactLastName,
                company companyId
            }} @as contact
        }
    };

    "" @as dealId;
    false @as dealCreated;

    if (updateCRMFromLead.shouldCreateDeal) {
        console.log("💼 HUBSPOT: Creating deal: " + updateCRMFromLead.dealName);

        {Deal {
            deal_name updateCRMFromLead.dealName,
            deal_stage updateCRMFromLead.dealStage,
            owner updateCRMFromLead.ownerId,
            associated_company companyId,
            associated_contacts [contact.id],
            description "Deal created from email thread"
        }} @as deal;

        deal.id @as dealId;
        true @as dealCreated;

        console.log("💼 HUBSPOT: Deal created, ID: " + dealId);
        console.log("📝 HUBSPOT: Creating deal note");

        {Note {
            note_body "Deal Created: " + deal.deal_name + "\nStage: " + updateCRMFromLead.dealStage + "\n\nLead Analysis: " + updateCRMFromLead.reasoning + "\nScore: " + updateCRMFromLead.leadScore + "\nNext Action: " + updateCRMFromLead.nextAction,
            timestamp now(),
            owner updateCRMFromLead.ownerId,
            associated_company companyId,
            associated_contacts [contact.id],
            associated_deal deal.id
        }} @as note
    } else {
        console.log("💼 HUBSPOT: Skipping deal creation");
        console.log("📝 HUBSPOT: Creating analysis note");

        {Note {
            note_body "Lead Analysis: " + updateCRMFromLead.reasoning + "\nScore: " + updateCRMFromLead.leadScore + "\nStage: " + updateCRMFromLead.leadStage + "\nNext Action: " + updateCRMFromLead.nextAction,
            timestamp now(),
            owner updateCRMFromLead.ownerId,
            associated_company companyId,
            associated_contacts [contact.id]
        }} @as note
    };

    console.log("📋 HUBSPOT: Creating follow-up task");

    {Task {
        hs_task_subject "Follow up: " + updateCRMFromLead.nextAction,
        hs_task_body "Lead: " + companyName + "\nStage: " + updateCRMFromLead.leadStage + " (Score: " + updateCRMFromLead.leadScore + ")\n\nAction: " + updateCRMFromLead.nextAction + "\n\nReasoning: " + updateCRMFromLead.reasoning,
        hs_timestamp now() + (24 * 3600000),
        hubspot_owner_id updateCRMFromLead.ownerId,
        hs_task_status "NOT_STARTED",
        hs_task_type "EMAIL",
        hs_task_priority "MEDIUM",
        associated_company companyId,
        associated_contacts [contact.id],
        associated_deal dealId
    }} @as task;

    console.log("📋 HUBSPOT: Task created, ID: " + task.id);
    console.log("✅ HUBSPOT: CRM Update complete - Company: " + companyId + ", Contact: " + contact.id + ", Deal: " + dealId);

    {CRMUpdateResult {
        companyId companyId,
        companyName companyName,
        contactId contact.id,
        contactEmail contact.email,
        dealId dealId,
        dealCreated dealCreated,
        noteId note.id,
        taskId task.id
    }}
}

agent hubspotAgent {
    llm "ticketflow_llm",
    role "You are an app responsible for managing HubSpot CRM data including contacts, companies, deals, owners, tasks, notes, and meetings with full association support."
    instruction "You are an app responsible for managing HubSpot CRM data. You can create, read, update, and delete:
                    - Contacts: Customer contact information and details
                    - Companies: Business account information
                    - Deals: Sales opportunities and pipeline management
                    - Owners: HubSpot user accounts and team members
                    - Tasks: Activities and follow-up items
                    - Notes: Notes attached to contacts, companies, or deals
                    - Meetings: Meeting engagements with scheduling and outcome tracking

                    For meetings, you can also manage associations:
                    - When creating meetings, you can associate them with contacts, companies, or deals by providing comma-separated IDs in associated_contacts, associated_companies, or associated_deals fields
                    - Use MeetingAssociation to associate an existing meeting with contacts, companies, or deals
                    - Use MeetingDisassociation to remove associations
                    - Use MeetingAssociationQuery to query existing associations

                    Use the appropriate tool based on the entity type and operation requested.
                    For queries, you can search by ID or retrieve all records.
                    For updates, provide the entity ID and the fields to update.
                    For deletions, provide the entity ID to remove.",
    tools [hubspot/Contact, hubspot/Company, hubspot/Deal, hubspot/Owner, hubspot/Task, hubspot/Note, hubspot/Meeting, hubspot/MeetingAssociation, hubspot/MeetingDisassociation, hubspot/MeetingAssociationQuery]
}
