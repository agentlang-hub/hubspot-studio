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

record CRMDataSnapshot {
    existingCompanyId String @optional,
    existingCompanyName String @optional,
    existingContactId String @optional,
    hasCompany Boolean @default(false),
    hasContact Boolean @default(false)
}

event retrieveCRMData {
    companyDomain String @optional,
    contactEmail String @optional
}

workflow retrieveCRMData {
    if (retrieveCRMData.companyDomain) {
        {Company {domain? retrieveCRMData.companyDomain}} @as companies;

        if (retrieveCRMData.contactEmail) {
            {Contact {email? retrieveCRMData.contactEmail}} @as contact;

            if (companies.length > 0) {
                companies @as [comp];
                if (contact.length > 0 ) {
                    contact @as [cont];
                    {CRMDataSnapshot {
                        existingCompanyId comp.id,
                        existingCompanyName comp.name,
                        existingContactId cont.id,
                        hasCompany true,
                        hasContact true
                    }}
                } else {
                    {CRMDataSnapshot {
                        existingCompanyId comp.id,
                        existingCompanyName comp.name,
                        existingContactId "",
                        hasCompany true,
                        hasContact false
                    }}
                }
            } else {
                if (contact.length > 0 ) {
                    contact @as [cont];

                    {CRMDataSnapshot {
                        existingCompanyId "",
                        existingCompanyName "",
                        existingContactId cont.id,
                        hasCompany false,
                        hasContact true
                    }}
                } else {
                    {CRMDataSnapshot {
                        existingCompanyId "",
                        existingCompanyName "",
                        existingContactId "",
                        hasCompany false,
                        hasContact false
                    }}
                }
            }
        }  else {
            if (companies.length > 0) {
                companies @as [comp];
                {CRMDataSnapshot {
                        existingCompanyId comp.id,
                        existingCompanyName comp.name,
                        existingContactId "",
                        hasCompany true,
                        hasContact false
                }}
            } else {
                {CRMDataSnapshot {
                        existingCompanyId "",
                        existingCompanyName "",
                        existingContactId "",
                        hasCompany true,
                        hasContact false
                }}
            }
        }

    } else {
        if (retrieveCRMData.contactEmail) {
            {Contact {email? retrieveCRMData.contactEmail}} @as contact;
            if (contact.length > 0 ) {
                contact @as [cont];
                {CRMDataSnapshot {
                    existingCompanyId "",
                    existingCompanyName "",
                    existingContactId cont.id,
                    hasCompany false,
                    hasContact true
                }}
            } else {
                {CRMDataSnapshot {
                    existingCompanyId "",
                    existingCompanyName "",
                    existingContactId "",
                    hasCompany false,
                    hasContact false
                }}
            }
        } else {
            {CRMDataSnapshot {
                    existingCompanyId "",
                    existingCompanyName "",
                    existingContactId "",
                    hasCompany false,
                    hasContact false
            }}
        }
    }
}

event upsertCompanyRecord {
    name String,
    domain String,
    lifecycle_stage String @optional,
    ai_lead_score Int @optional
}

workflow upsertCompanyRecord {
    
    // Check if both domain and name are empty/null - if so, skip company operations
    if ((upsertCompanyRecord.domain == "") and (upsertCompanyRecord.name == "")) {
        // Return empty result - AgentLang will handle this gracefully
        nil
    } else {
        {Company {domain? upsertCompanyRecord.domain}} @as companies;
        
        
        if (companies.length > 0) {
            companies @as [company];
            
            
            {Company {
                id? company.id,
                lifecycle_stage upsertCompanyRecord.lifecycle_stage,
                ai_lead_score upsertCompanyRecord.ai_lead_score
            }} @as result;
            
            result
        } else {
            
            {Company {
                domain upsertCompanyRecord.domain,
                name upsertCompanyRecord.name,
                lifecycle_stage upsertCompanyRecord.lifecycle_stage,
                ai_lead_score upsertCompanyRecord.ai_lead_score
            }} @as result;
            
            result
        }
    }
}

event upsertContactRecord {
    email String,
    first_name String,
    last_name String,
    company String @optional
}

workflow upsertContactRecord {
    
    {Contact {email? upsertContactRecord.email}} @as contacts;
    
    
    if (contacts.length > 0) {
        contacts @as [contact];
        contact
    } else {
        
        {Contact {
            email upsertContactRecord.email,
            first_name upsertContactRecord.first_name,
            last_name upsertContactRecord.last_name,
            company upsertContactRecord.company
        }} @as result;
        
        result
    }
}

record CRMSyncResult {
    companyId String @optional,
    companyName String @optional,
    contactId String,
    contactEmail String,
    dealId String @optional,
    dealCreated Boolean @default(false),
    noteId String,
    taskId String,
    meetingId String @optional
}

event syncLeadToCRM {
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

workflow syncLeadToCRM {
    if (syncLeadToCRM.leadStage == "QUALIFIED") {
        "salesqualifiedlead" @as lifecycle
    } else if (syncLeadToCRM.leadStage == "ENGAGED") {
        "marketingqualifiedlead" @as lifecycle
    } else {
        "lead" @as lifecycle
    };
    
    if (syncLeadToCRM.dealStage == "DISCOVERY") {
        "appointmentscheduled" @as hubspotDealStage
    } else if (syncLeadToCRM.dealStage == "MEETING") {
        "qualifiedtobuy" @as hubspotDealStage
    } else if (syncLeadToCRM.dealStage == "PROPOSAL") {
        "presentationscheduled" @as hubspotDealStage
    } else if (syncLeadToCRM.dealStage == "NEGOTIATION") {
        "decisionmakerboughtin" @as hubspotDealStage
    } else if (syncLeadToCRM.dealStage == "CLOSED_WON") {
        "closedwon" @as hubspotDealStage
    } else if (syncLeadToCRM.dealStage == "CLOSED_LOST") {
        "closedlost" @as hubspotDealStage
    } else {
        "appointmentscheduled" @as hubspotDealStage
    };
    
    if (syncLeadToCRM.shouldCreateCompany) {
        {upsertCompanyRecord {
            name syncLeadToCRM.companyName,
            domain syncLeadToCRM.companyDomain,
            lifecycle_stage lifecycle,
            ai_lead_score syncLeadToCRM.leadScore
        }} @as company;
        
        if (syncLeadToCRM.shouldCreateContact) {
            {upsertContactRecord {
                email syncLeadToCRM.contactEmail,
                first_name syncLeadToCRM.contactFirstName,
                last_name syncLeadToCRM.contactLastName,
                company company.id
            }} @as contact;
            
            if (syncLeadToCRM.shouldCreateDeal) {
                {Deal {
                    deal_name syncLeadToCRM.dealName,
                    deal_stage hubspotDealStage,
                    owner syncLeadToCRM.ownerId,
                    associated_company company.id,
                    associated_contacts [contact.id],
                    description "Deal created from email thread"
                }} @as deal;
                
                {Note {
                    note_body "Deal Created: " + deal.deal_name + "\nStage: " + syncLeadToCRM.dealStage + "\n\nLead Analysis: " + syncLeadToCRM.reasoning + "\nScore: " + syncLeadToCRM.leadScore + "\nNext Action: " + syncLeadToCRM.nextAction,
                    timestamp now(),
                    owner syncLeadToCRM.ownerId,
                    associated_company company.id,
                    associated_contacts [contact.id],
                    associated_deal deal.id
                }} @as note;
                
                {Task {
                    hs_task_subject "Follow up: " + syncLeadToCRM.nextAction,
                    hs_task_body "Lead: " + company.name + "\nStage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nAction: " + syncLeadToCRM.nextAction + "\n\nReasoning: " + syncLeadToCRM.reasoning,
                    hs_timestamp now() + (24 * 3600000),
                    hubspot_owner_id syncLeadToCRM.ownerId,
                    hs_task_status "NOT_STARTED",
                    hs_task_type "EMAIL",
                    hs_task_priority "MEDIUM",
                    associated_company company.id,
                    associated_contacts [contact.id],
                    associated_deal deal.id
                }} @as task;
                
                {Meeting {
                    meeting_title "Follow-up Discussion: " + syncLeadToCRM.nextAction,
                    meeting_body "Lead Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nDiscussion Points:\n- " + syncLeadToCRM.nextAction + "\n\nBackground:\n" + syncLeadToCRM.reasoning,
                    timestamp now() + (2 * 24 * 3600000),
                    meeting_start_time now() + (2 * 24 * 3600000),
                    meeting_end_time now() + (2 * 24 * 3600000) + (3600000),
                    owner syncLeadToCRM.ownerId,
                    meeting_outcome "SCHEDULED",
                    activity_type "MEETING",
                    associated_contacts [contact.id],
                    associated_companies [company.id],
                    associated_deals [deal.id]
                }} @as meeting;
                
                {CRMSyncResult {
                    companyId company.id,
                    companyName company.name,
                    contactId contact.id,
                    contactEmail contact.email,
                    dealId deal.id,
                    dealCreated true,
                    noteId note.id,
                    taskId task.id,
                    meetingId meeting.id
                }}
            } else {
                {Note {
                    note_body "Lead Analysis: " + syncLeadToCRM.reasoning + "\nScore: " + syncLeadToCRM.leadScore + "\nStage: " + syncLeadToCRM.leadStage + "\nNext Action: " + syncLeadToCRM.nextAction,
                    timestamp now(),
                    owner syncLeadToCRM.ownerId,
                    associated_company company.id,
                    associated_contacts [contact.id]
                }} @as note;
                
                {Task {
                    hs_task_subject "Follow up: " + syncLeadToCRM.nextAction,
                    hs_task_body "Lead: " + company.name + "\nStage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nAction: " + syncLeadToCRM.nextAction + "\n\nReasoning: " + syncLeadToCRM.reasoning,
                    hs_timestamp now() + (24 * 3600000),
                    hubspot_owner_id syncLeadToCRM.ownerId,
                    hs_task_status "NOT_STARTED",
                    hs_task_type "EMAIL",
                    hs_task_priority "MEDIUM",
                    associated_company company.id,
                    associated_contacts [contact.id]
                }} @as task;
                
                if (syncLeadToCRM.dealStage != "NONE") {
                    {Meeting {
                        meeting_title "Follow-up Discussion: " + syncLeadToCRM.nextAction,
                        meeting_body "Lead Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nDiscussion Points:\n- " + syncLeadToCRM.nextAction + "\n\nBackground:\n" + syncLeadToCRM.reasoning,
                        timestamp now() + (2 * 24 * 3600000),
                        meeting_start_time now() + (2 * 24 * 3600000),
                        meeting_end_time now() + (2 * 24 * 3600000) + (3600000),
                        owner syncLeadToCRM.ownerId,
                        meeting_outcome "SCHEDULED",
                        activity_type "MEETING",
                        associated_contacts [contact.id],
                        associated_companies [company.id]
                    }} @as meeting;
                    
                    {CRMSyncResult {
                        companyId company.id,
                        companyName company.name,
                        contactId contact.id,
                        contactEmail contact.email,
                        dealId "",
                        dealCreated false,
                        noteId note.id,
                        taskId task.id,
                        meetingId meeting.id
                    }}
                } else {
                    {CRMSyncResult {
                        companyId company.id,
                        companyName company.name,
                        contactId contact.id,
                        contactEmail contact.email,
                        dealId "",
                        dealCreated false,
                        noteId note.id,
                        taskId task.id,
                        meetingId ""
                    }}
                }
            }
        } else {
            if (syncLeadToCRM.existingContactId) {
                {Contact {id? syncLeadToCRM.existingContactId}} @as existingContacts;
                existingContacts @as [contact];
                
                if (syncLeadToCRM.shouldCreateDeal) {
                    {Deal {
                        deal_name syncLeadToCRM.dealName,
                        deal_stage hubspotDealStage,
                        owner syncLeadToCRM.ownerId,
                        associated_company company.id,
                        associated_contacts [contact.id],
                        description "Deal created from email thread"
                    }} @as deal;
                    
                    {Note {
                        note_body "Deal Created: " + deal.deal_name + "\nStage: " + syncLeadToCRM.dealStage + "\n\nLead Analysis: " + syncLeadToCRM.reasoning + "\nScore: " + syncLeadToCRM.leadScore + "\nNext Action: " + syncLeadToCRM.nextAction,
                        timestamp now(),
                        owner syncLeadToCRM.ownerId,
                        associated_company company.id,
                        associated_contacts [contact.id],
                        associated_deal deal.id
                    }} @as note;
                    
                    {Task {
                        hs_task_subject "Follow up: " + syncLeadToCRM.nextAction,
                        hs_task_body "Lead: " + company.name + "\nStage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nAction: " + syncLeadToCRM.nextAction + "\n\nReasoning: " + syncLeadToCRM.reasoning,
                        hs_timestamp now() + (24 * 3600000),
                        hubspot_owner_id syncLeadToCRM.ownerId,
                        hs_task_status "NOT_STARTED",
                        hs_task_type "EMAIL",
                        hs_task_priority "MEDIUM",
                        associated_company company.id,
                        associated_contacts [contact.id],
                        associated_deal deal.id
                    }} @as task;
                    
                    {Meeting {
                        meeting_title "Follow-up Discussion: " + syncLeadToCRM.nextAction,
                        meeting_body "Lead Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nDiscussion Points:\n- " + syncLeadToCRM.nextAction + "\n\nBackground:\n" + syncLeadToCRM.reasoning,
                        timestamp now() + (2 * 24 * 3600000),
                        meeting_start_time now() + (2 * 24 * 3600000),
                        meeting_end_time now() + (2 * 24 * 3600000) + (3600000),
                        owner syncLeadToCRM.ownerId,
                        meeting_outcome "SCHEDULED",
                        activity_type "MEETING",
                        associated_contacts [contact.id],
                        associated_companies [company.id],
                        associated_deals [deal.id]
                    }} @as meeting;
                    
                    {CRMSyncResult {
                        companyId company.id,
                        companyName company.name,
                        contactId contact.id,
                        contactEmail contact.email,
                        dealId deal.id,
                        dealCreated true,
                        noteId note.id,
                        taskId task.id,
                        meetingId meeting.id
                    }}
                } else {
                    {Note {
                        note_body "Lead Analysis: " + syncLeadToCRM.reasoning + "\nScore: " + syncLeadToCRM.leadScore + "\nStage: " + syncLeadToCRM.leadStage + "\nNext Action: " + syncLeadToCRM.nextAction,
                        timestamp now(),
                        owner syncLeadToCRM.ownerId,
                        associated_company company.id,
                        associated_contacts [contact.id]
                    }} @as note;
                    
                    {Task {
                        hs_task_subject "Follow up: " + syncLeadToCRM.nextAction,
                        hs_task_body "Lead: " + company.name + "\nStage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nAction: " + syncLeadToCRM.nextAction + "\n\nReasoning: " + syncLeadToCRM.reasoning,
                        hs_timestamp now() + (24 * 3600000),
                        hubspot_owner_id syncLeadToCRM.ownerId,
                        hs_task_status "NOT_STARTED",
                        hs_task_type "EMAIL",
                        hs_task_priority "MEDIUM",
                        associated_company company.id,
                        associated_contacts [contact.id]
                    }} @as task;
                    
                    if (syncLeadToCRM.dealStage != "NONE") {
                        {Meeting {
                            meeting_title "Follow-up Discussion: " + syncLeadToCRM.nextAction,
                            meeting_body "Lead Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nDiscussion Points:\n- " + syncLeadToCRM.nextAction + "\n\nBackground:\n" + syncLeadToCRM.reasoning,
                            timestamp now() + (2 * 24 * 3600000),
                            meeting_start_time now() + (2 * 24 * 3600000),
                            meeting_end_time now() + (2 * 24 * 3600000) + (3600000),
                            owner syncLeadToCRM.ownerId,
                            meeting_outcome "SCHEDULED",
                            activity_type "MEETING",
                            associated_contacts [contact.id],
                            associated_companies [company.id]
                        }} @as meeting;
                        
                        {CRMSyncResult {
                            companyId company.id,
                            companyName company.name,
                            contactId contact.id,
                            contactEmail contact.email,
                            dealId "",
                            dealCreated false,
                            noteId note.id,
                            taskId task.id,
                            meetingId meeting.id
                        }}
                    } else {
                        {CRMSyncResult {
                            companyId company.id,
                            companyName company.name,
                            contactId contact.id,
                            contactEmail contact.email,
                            dealId "",
                            dealCreated false,
                            noteId note.id,
                            taskId task.id,
                            meetingId ""
                        }}
                    }
                }
            } else {
                {upsertContactRecord {
                    email syncLeadToCRM.contactEmail,
                    first_name syncLeadToCRM.contactFirstName,
                    last_name syncLeadToCRM.contactLastName,
                    company company.id
                }} @as contact;
                
                if (syncLeadToCRM.shouldCreateDeal) {
                    {Deal {
                        deal_name syncLeadToCRM.dealName,
                        deal_stage hubspotDealStage,
                        owner syncLeadToCRM.ownerId,
                        associated_company company.id,
                        associated_contacts [contact.id],
                        description "Deal created from email thread"
                    }} @as deal;
                    
                    {Note {
                        note_body "Deal Created: " + deal.deal_name + "\nStage: " + syncLeadToCRM.dealStage + "\n\nLead Analysis: " + syncLeadToCRM.reasoning + "\nScore: " + syncLeadToCRM.leadScore + "\nNext Action: " + syncLeadToCRM.nextAction,
                        timestamp now(),
                        owner syncLeadToCRM.ownerId,
                        associated_company company.id,
                        associated_contacts [contact.id],
                        associated_deal deal.id
                    }} @as note;
                    
                    {Task {
                        hs_task_subject "Follow up: " + syncLeadToCRM.nextAction,
                        hs_task_body "Lead: " + company.name + "\nStage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nAction: " + syncLeadToCRM.nextAction + "\n\nReasoning: " + syncLeadToCRM.reasoning,
                        hs_timestamp now() + (24 * 3600000),
                        hubspot_owner_id syncLeadToCRM.ownerId,
                        hs_task_status "NOT_STARTED",
                        hs_task_type "EMAIL",
                        hs_task_priority "MEDIUM",
                        associated_company company.id,
                        associated_contacts [contact.id],
                        associated_deal deal.id
                    }} @as task;
                    
                    {Meeting {
                        meeting_title "Follow-up Discussion: " + syncLeadToCRM.nextAction,
                        meeting_body "Lead Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nDiscussion Points:\n- " + syncLeadToCRM.nextAction + "\n\nBackground:\n" + syncLeadToCRM.reasoning,
                        timestamp now() + (2 * 24 * 3600000),
                        meeting_start_time now() + (2 * 24 * 3600000),
                        meeting_end_time now() + (2 * 24 * 3600000) + (3600000),
                        owner syncLeadToCRM.ownerId,
                        meeting_outcome "SCHEDULED",
                        activity_type "MEETING",
                        associated_contacts [contact.id],
                        associated_companies [company.id],
                        associated_deals [deal.id]
                    }} @as meeting;
                    
                    {CRMSyncResult {
                        companyId company.id,
                        companyName company.name,
                        contactId contact.id,
                        contactEmail contact.email,
                        dealId deal.id,
                        dealCreated true,
                        noteId note.id,
                        taskId task.id,
                        meetingId meeting.id
                    }}
                } else {
                    {Note {
                        note_body "Lead Analysis: " + syncLeadToCRM.reasoning + "\nScore: " + syncLeadToCRM.leadScore + "\nStage: " + syncLeadToCRM.leadStage + "\nNext Action: " + syncLeadToCRM.nextAction,
                        timestamp now(),
                        owner syncLeadToCRM.ownerId,
                        associated_company company.id,
                        associated_contacts [contact.id]
                    }} @as note;
                    
                    {Task {
                        hs_task_subject "Follow up: " + syncLeadToCRM.nextAction,
                        hs_task_body "Lead: " + company.name + "\nStage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nAction: " + syncLeadToCRM.nextAction + "\n\nReasoning: " + syncLeadToCRM.reasoning,
                        hs_timestamp now() + (24 * 3600000),
                        hubspot_owner_id syncLeadToCRM.ownerId,
                        hs_task_status "NOT_STARTED",
                        hs_task_type "EMAIL",
                        hs_task_priority "MEDIUM",
                        associated_company company.id,
                        associated_contacts [contact.id]
                    }} @as task;
                    
                    if (syncLeadToCRM.dealStage != "NONE") {
                        {Meeting {
                            meeting_title "Follow-up Discussion: " + syncLeadToCRM.nextAction,
                            meeting_body "Lead Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nDiscussion Points:\n- " + syncLeadToCRM.nextAction + "\n\nBackground:\n" + syncLeadToCRM.reasoning,
                            timestamp now() + (2 * 24 * 3600000),
                            meeting_start_time now() + (2 * 24 * 3600000),
                            meeting_end_time now() + (2 * 24 * 3600000) + (3600000),
                            owner syncLeadToCRM.ownerId,
                            meeting_outcome "SCHEDULED",
                            activity_type "MEETING",
                            associated_contacts [contact.id],
                            associated_companies [company.id]
                        }} @as meeting;
                        
                        {CRMSyncResult {
                            companyId company.id,
                            companyName company.name,
                            contactId contact.id,
                            contactEmail contact.email,
                            dealId "",
                            dealCreated false,
                            noteId note.id,
                            taskId task.id,
                            meetingId meeting.id
                        }}
                    } else {
                        {CRMSyncResult {
                            companyId company.id,
                            companyName company.name,
                            contactId contact.id,
                            contactEmail contact.email,
                            dealId "",
                            dealCreated false,
                            noteId note.id,
                            taskId task.id,
                            meetingId ""
                        }}
                    }
                }
            }
        }
    } else {
        if (syncLeadToCRM.existingCompanyId) {
            if (syncLeadToCRM.shouldCreateContact) {
                {upsertContactRecord {
                    email syncLeadToCRM.contactEmail,
                    first_name syncLeadToCRM.contactFirstName,
                    last_name syncLeadToCRM.contactLastName,
                    company syncLeadToCRM.existingCompanyId
                }} @as contact;
                
                if (syncLeadToCRM.shouldCreateDeal) {
                    {Deal {
                        deal_name syncLeadToCRM.dealName,
                        deal_stage hubspotDealStage,
                        owner syncLeadToCRM.ownerId,
                        associated_company syncLeadToCRM.existingCompanyId,
                        associated_contacts [contact.id],
                        description "Deal created from email thread"
                    }} @as deal;
                    
                    {Note {
                        note_body "Deal Created: " + deal.deal_name + "\nStage: " + syncLeadToCRM.dealStage + "\n\nLead Analysis: " + syncLeadToCRM.reasoning + "\nScore: " + syncLeadToCRM.leadScore + "\nNext Action: " + syncLeadToCRM.nextAction,
                        timestamp now(),
                        owner syncLeadToCRM.ownerId,
                        associated_company syncLeadToCRM.existingCompanyId,
                        associated_contacts [contact.id],
                        associated_deal deal.id
                    }} @as note;
                    
                    {Task {
                        hs_task_subject "Follow up: " + syncLeadToCRM.nextAction,
                        hs_task_body "Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nAction: " + syncLeadToCRM.nextAction + "\n\nReasoning: " + syncLeadToCRM.reasoning,
                        hs_timestamp now() + (24 * 3600000),
                        hubspot_owner_id syncLeadToCRM.ownerId,
                        hs_task_status "NOT_STARTED",
                        hs_task_type "EMAIL",
                        hs_task_priority "MEDIUM",
                        associated_company syncLeadToCRM.existingCompanyId,
                        associated_contacts [contact.id],
                        associated_deal deal.id
                    }} @as task;
                    
                    {Meeting {
                        meeting_title "Follow-up Discussion: " + syncLeadToCRM.nextAction,
                        meeting_body "Lead Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nDiscussion Points:\n- " + syncLeadToCRM.nextAction + "\n\nBackground:\n" + syncLeadToCRM.reasoning,
                        timestamp now() + (2 * 24 * 3600000),
                        meeting_start_time now() + (2 * 24 * 3600000),
                        meeting_end_time now() + (2 * 24 * 3600000) + (3600000),
                        owner syncLeadToCRM.ownerId,
                        meeting_outcome "SCHEDULED",
                        activity_type "MEETING",
                        associated_contacts [contact.id],
                        associated_companies [syncLeadToCRM.existingCompanyId],
                        associated_deals [deal.id]
                    }} @as meeting;
                    
                    {CRMSyncResult {
                        companyId company.id,
                        companyName company.name,
                        contactId contact.id,
                        contactEmail contact.email,
                        dealId deal.id,
                        dealCreated true,
                        noteId note.id,
                        taskId task.id,
                        meetingId meeting.id
                    }}
                } else {
                    {Note {
                        note_body "Lead Analysis: " + syncLeadToCRM.reasoning + "\nScore: " + syncLeadToCRM.leadScore + "\nStage: " + syncLeadToCRM.leadStage + "\nNext Action: " + syncLeadToCRM.nextAction,
                        timestamp now(),
                        owner syncLeadToCRM.ownerId,
                        associated_company syncLeadToCRM.existingCompanyId,
                        associated_contacts [contact.id]
                    }} @as note;
                    
                    {Task {
                        hs_task_subject "Follow up: " + syncLeadToCRM.nextAction,
                        hs_task_body "Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nAction: " + syncLeadToCRM.nextAction + "\n\nReasoning: " + syncLeadToCRM.reasoning,
                        hs_timestamp now() + (24 * 3600000),
                        hubspot_owner_id syncLeadToCRM.ownerId,
                        hs_task_status "NOT_STARTED",
                        hs_task_type "EMAIL",
                        hs_task_priority "MEDIUM",
                        associated_company syncLeadToCRM.existingCompanyId,
                        associated_contacts [contact.id]
                    }} @as task;
                    
                    if (syncLeadToCRM.dealStage != "NONE") {
                        {Meeting {
                            meeting_title "Follow-up Discussion: " + syncLeadToCRM.nextAction,
                            meeting_body "Lead Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nDiscussion Points:\n- " + syncLeadToCRM.nextAction + "\n\nBackground:\n" + syncLeadToCRM.reasoning,
                            timestamp now() + (2 * 24 * 3600000),
                            meeting_start_time now() + (2 * 24 * 3600000),
                            meeting_end_time now() + (2 * 24 * 3600000) + (3600000),
                            owner syncLeadToCRM.ownerId,
                            meeting_outcome "SCHEDULED",
                            activity_type "MEETING",
                            associated_contacts [contact.id],
                            associated_companies [syncLeadToCRM.existingCompanyId]
                        }} @as meeting;
                        
                        {CRMSyncResult {
                            companyId syncLeadToCRM.existingCompanyId,
                            companyName "",
                            contactId contact.id,
                            contactEmail contact.email,
                            dealId "",
                            dealCreated false,
                            noteId note.id,
                            taskId task.id,
                            meetingId meeting.id
                        }}
                    } else {
                        {CRMSyncResult {
                            companyId syncLeadToCRM.existingCompanyId,
                            companyName "",
                            contactId contact.id,
                            contactEmail contact.email,
                            dealId "",
                            dealCreated false,
                            noteId note.id,
                            taskId task.id,
                            meetingId ""
                        }}
                    }
                }
            } else {
                if (syncLeadToCRM.existingContactId) {
                    {Contact {id? syncLeadToCRM.existingContactId}} @as existingContacts;
                    existingContacts @as [contact];
                    
                    if (syncLeadToCRM.shouldCreateDeal) {
                        {Deal {
                            deal_name syncLeadToCRM.dealName,
                            deal_stage hubspotDealStage,
                            owner syncLeadToCRM.ownerId,
                            associated_company syncLeadToCRM.existingCompanyId,
                            associated_contacts [contact.id],
                            description "Deal created from email thread"
                        }} @as deal;
                        
                        {Note {
                            note_body "Deal Created: " + deal.deal_name + "\nStage: " + syncLeadToCRM.dealStage + "\n\nLead Analysis: " + syncLeadToCRM.reasoning + "\nScore: " + syncLeadToCRM.leadScore + "\nNext Action: " + syncLeadToCRM.nextAction,
                            timestamp now(),
                            owner syncLeadToCRM.ownerId,
                            associated_company syncLeadToCRM.existingCompanyId,
                            associated_contacts [contact.id],
                            associated_deal deal.id
                        }} @as note;
                        
                        {Task {
                            hs_task_subject "Follow up: " + syncLeadToCRM.nextAction,
                            hs_task_body "Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nAction: " + syncLeadToCRM.nextAction + "\n\nReasoning: " + syncLeadToCRM.reasoning,
                            hs_timestamp now() + (24 * 3600000),
                            hubspot_owner_id syncLeadToCRM.ownerId,
                            hs_task_status "NOT_STARTED",
                            hs_task_type "EMAIL",
                            hs_task_priority "MEDIUM",
                            associated_company syncLeadToCRM.existingCompanyId,
                            associated_contacts [contact.id],
                            associated_deal deal.id
                        }} @as task;
                        
                        {Meeting {
                            meeting_title "Follow-up Discussion: " + syncLeadToCRM.nextAction,
                            meeting_body "Lead Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nDiscussion Points:\n- " + syncLeadToCRM.nextAction + "\n\nBackground:\n" + syncLeadToCRM.reasoning,
                            timestamp now() + (2 * 24 * 3600000),
                            meeting_start_time now() + (2 * 24 * 3600000),
                            meeting_end_time now() + (2 * 24 * 3600000) + (3600000),
                            owner syncLeadToCRM.ownerId,
                            meeting_outcome "SCHEDULED",
                            activity_type "MEETING",
                            associated_contacts [contact.id],
                            associated_companies [syncLeadToCRM.existingCompanyId],
                            associated_deals [deal.id]
                        }} @as meeting;
                        
                        {CRMSyncResult {
                            companyId syncLeadToCRM.existingCompanyId,
                            companyName "",
                            contactId contact.id,
                            contactEmail contact.email,
                            dealId deal.id,
                            dealCreated true,
                            noteId note.id,
                            taskId task.id,
                            meetingId meeting.id
                        }}
                    } else {
                        {Note {
                            note_body "Lead Analysis: " + syncLeadToCRM.reasoning + "\nScore: " + syncLeadToCRM.leadScore + "\nStage: " + syncLeadToCRM.leadStage + "\nNext Action: " + syncLeadToCRM.nextAction,
                            timestamp now(),
                            owner syncLeadToCRM.ownerId,
                            associated_company syncLeadToCRM.existingCompanyId,
                            associated_contacts [contact.id]
                        }} @as note;
                        
                        {Task {
                            hs_task_subject "Follow up: " + syncLeadToCRM.nextAction,
                            hs_task_body "Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nAction: " + syncLeadToCRM.nextAction + "\n\nReasoning: " + syncLeadToCRM.reasoning,
                            hs_timestamp now() + (24 * 3600000),
                            hubspot_owner_id syncLeadToCRM.ownerId,
                            hs_task_status "NOT_STARTED",
                            hs_task_type "EMAIL",
                            hs_task_priority "MEDIUM",
                            associated_company syncLeadToCRM.existingCompanyId,
                            associated_contacts [contact.id]
                        }} @as task;
                        
                        if (syncLeadToCRM.dealStage != "NONE") {
                            {Meeting {
                                meeting_title "Follow-up Discussion: " + syncLeadToCRM.nextAction,
                                meeting_body "Lead Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nDiscussion Points:\n- " + syncLeadToCRM.nextAction + "\n\nBackground:\n" + syncLeadToCRM.reasoning,
                                timestamp now() + (2 * 24 * 3600000),
                                meeting_start_time now() + (2 * 24 * 3600000),
                                meeting_end_time now() + (2 * 24 * 3600000) + (3600000),
                                owner syncLeadToCRM.ownerId,
                                meeting_outcome "SCHEDULED",
                                activity_type "MEETING",
                                associated_contacts [contact.id],
                                associated_companies [syncLeadToCRM.existingCompanyId]
                            }} @as meeting;
                            
                            {CRMSyncResult {
                                companyId syncLeadToCRM.existingCompanyId,
                                companyName "",
                                contactId contact.id,
                                contactEmail contact.email,
                                dealId "",
                                dealCreated false,
                                noteId note.id,
                                taskId task.id,
                                meetingId meeting.id
                            }}
                        } else {
                            {CRMSyncResult {
                                companyId syncLeadToCRM.existingCompanyId,
                                companyName "",
                                contactId contact.id,
                                contactEmail contact.email,
                                dealId "",
                                dealCreated false,
                                noteId note.id,
                                taskId task.id,
                                meetingId ""
                            }}
                        }
                    }
                } else {
                    {upsertContactRecord {
                        email syncLeadToCRM.contactEmail,
                        first_name syncLeadToCRM.contactFirstName,
                        last_name syncLeadToCRM.contactLastName,
                        company syncLeadToCRM.existingCompanyId
                    }} @as contact;
                    
                    if (syncLeadToCRM.shouldCreateDeal) {
                        {Deal {
                            deal_name syncLeadToCRM.dealName,
                            deal_stage hubspotDealStage,
                            owner syncLeadToCRM.ownerId,
                            associated_company syncLeadToCRM.existingCompanyId,
                            associated_contacts [contact.id],
                            description "Deal created from email thread"
                        }} @as deal;
                        
                        {Note {
                            note_body "Deal Created: " + deal.deal_name + "\nStage: " + syncLeadToCRM.dealStage + "\n\nLead Analysis: " + syncLeadToCRM.reasoning + "\nScore: " + syncLeadToCRM.leadScore + "\nNext Action: " + syncLeadToCRM.nextAction,
                            timestamp now(),
                            owner syncLeadToCRM.ownerId,
                            associated_company syncLeadToCRM.existingCompanyId,
                            associated_contacts [contact.id],
                            associated_deal deal.id
                        }} @as note;
                        
                        {Task {
                            hs_task_subject "Follow up: " + syncLeadToCRM.nextAction,
                            hs_task_body "Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nAction: " + syncLeadToCRM.nextAction + "\n\nReasoning: " + syncLeadToCRM.reasoning,
                            hs_timestamp now() + (24 * 3600000),
                            hubspot_owner_id syncLeadToCRM.ownerId,
                            hs_task_status "NOT_STARTED",
                            hs_task_type "EMAIL",
                            hs_task_priority "MEDIUM",
                            associated_company syncLeadToCRM.existingCompanyId,
                            associated_contacts [contact.id],
                            associated_deal deal.id
                        }} @as task;
                        
                        {Meeting {
                            meeting_title "Follow-up Discussion: " + syncLeadToCRM.nextAction,
                            meeting_body "Lead Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nDiscussion Points:\n- " + syncLeadToCRM.nextAction + "\n\nBackground:\n" + syncLeadToCRM.reasoning,
                            timestamp now() + (2 * 24 * 3600000),
                            meeting_start_time now() + (2 * 24 * 3600000),
                            meeting_end_time now() + (2 * 24 * 3600000) + (3600000),
                            owner syncLeadToCRM.ownerId,
                            meeting_outcome "SCHEDULED",
                            activity_type "MEETING",
                            associated_contacts [contact.id],
                            associated_companies [syncLeadToCRM.existingCompanyId],
                            associated_deals [deal.id]
                        }} @as meeting;
                        
                        {CRMSyncResult {
                            companyId syncLeadToCRM.existingCompanyId,
                            companyName "",
                            contactId contact.id,
                            contactEmail contact.email,
                            dealId deal.id,
                            dealCreated true,
                            noteId note.id,
                            taskId task.id,
                            meetingId meeting.id
                        }}
                    } else {
                        {Note {
                            note_body "Lead Analysis: " + syncLeadToCRM.reasoning + "\nScore: " + syncLeadToCRM.leadScore + "\nStage: " + syncLeadToCRM.leadStage + "\nNext Action: " + syncLeadToCRM.nextAction,
                            timestamp now(),
                            owner syncLeadToCRM.ownerId,
                            associated_company syncLeadToCRM.existingCompanyId,
                            associated_contacts [contact.id]
                        }} @as note;
                        
                        {Task {
                            hs_task_subject "Follow up: " + syncLeadToCRM.nextAction,
                            hs_task_body "Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nAction: " + syncLeadToCRM.nextAction + "\n\nReasoning: " + syncLeadToCRM.reasoning,
                            hs_timestamp now() + (24 * 3600000),
                            hubspot_owner_id syncLeadToCRM.ownerId,
                            hs_task_status "NOT_STARTED",
                            hs_task_type "EMAIL",
                            hs_task_priority "MEDIUM",
                            associated_company syncLeadToCRM.existingCompanyId,
                            associated_contacts [contact.id]
                        }} @as task;
                        
                        if (syncLeadToCRM.dealStage != "NONE") {
                            {Meeting {
                                meeting_title "Follow-up Discussion: " + syncLeadToCRM.nextAction,
                                meeting_body "Lead Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nDiscussion Points:\n- " + syncLeadToCRM.nextAction + "\n\nBackground:\n" + syncLeadToCRM.reasoning,
                                timestamp now() + (2 * 24 * 3600000),
                                meeting_start_time now() + (2 * 24 * 3600000),
                                meeting_end_time now() + (2 * 24 * 3600000) + (3600000),
                                owner syncLeadToCRM.ownerId,
                                meeting_outcome "SCHEDULED",
                                activity_type "MEETING",
                                associated_contacts [contact.id],
                                associated_companies [syncLeadToCRM.existingCompanyId]
                            }} @as meeting;
                            
                            {CRMSyncResult {
                                companyId syncLeadToCRM.existingCompanyId,
                                companyName "",
                                contactId contact.id,
                                contactEmail contact.email,
                                dealId "",
                                dealCreated false,
                                noteId note.id,
                                taskId task.id,
                                meetingId meeting.id
                            }}
                        } else {
                            {CRMSyncResult {
                                companyId syncLeadToCRM.existingCompanyId,
                                companyName "",
                                contactId contact.id,
                                contactEmail contact.email,
                                dealId "",
                                dealCreated false,
                                noteId note.id,
                                taskId task.id,
                                meetingId ""
                            }}
                        }
                    }
                }
            }
        } else {
            if (syncLeadToCRM.shouldCreateContact) {
                {upsertContactRecord {
                    email syncLeadToCRM.contactEmail,
                    first_name syncLeadToCRM.contactFirstName,
                    last_name syncLeadToCRM.contactLastName,
                    company ""
                }} @as contact;
                
                if (syncLeadToCRM.shouldCreateDeal) {
                    {Deal {
                        deal_name syncLeadToCRM.dealName,
                        deal_stage hubspotDealStage,
                        owner syncLeadToCRM.ownerId,
                        associated_contacts [contact.id],
                        description "Deal created from email thread"
                    }} @as deal;
                    
                    {Note {
                        note_body "Deal Created: " + deal.deal_name + "\nStage: " + syncLeadToCRM.dealStage + "\n\nLead Analysis: " + syncLeadToCRM.reasoning + "\nScore: " + syncLeadToCRM.leadScore + "\nNext Action: " + syncLeadToCRM.nextAction,
                        timestamp now(),
                        owner syncLeadToCRM.ownerId,
                        associated_contacts [contact.id],
                        associated_deal deal.id
                    }} @as note;
                    
                    {Task {
                        hs_task_subject "Follow up: " + syncLeadToCRM.nextAction,
                        hs_task_body "Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nAction: " + syncLeadToCRM.nextAction + "\n\nReasoning: " + syncLeadToCRM.reasoning,
                        hs_timestamp now() + (24 * 3600000),
                        hubspot_owner_id syncLeadToCRM.ownerId,
                        hs_task_status "NOT_STARTED",
                        hs_task_type "EMAIL",
                        hs_task_priority "MEDIUM",
                        associated_contacts [contact.id],
                        associated_deal deal.id
                    }} @as task;
                    
                    {Meeting {
                        meeting_title "Follow-up Discussion: " + syncLeadToCRM.nextAction,
                        meeting_body "Lead Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nDiscussion Points:\n- " + syncLeadToCRM.nextAction + "\n\nBackground:\n" + syncLeadToCRM.reasoning,
                        timestamp now() + (2 * 24 * 3600000),
                        meeting_start_time now() + (2 * 24 * 3600000),
                        meeting_end_time now() + (2 * 24 * 3600000) + (3600000),
                        owner syncLeadToCRM.ownerId,
                        meeting_outcome "SCHEDULED",
                        activity_type "MEETING",
                        associated_contacts [contact.id],
                        associated_deals [deal.id]
                    }} @as meeting;
                    
                    {CRMSyncResult {
                        companyId "",
                        companyName "",
                        contactId contact.id,
                        contactEmail contact.email,
                        dealId deal.id,
                        dealCreated true,
                        noteId note.id,
                        taskId task.id,
                        meetingId meeting.id
                    }}
                } else {
                    {Note {
                        note_body "Lead Analysis: " + syncLeadToCRM.reasoning + "\nScore: " + syncLeadToCRM.leadScore + "\nStage: " + syncLeadToCRM.leadStage + "\nNext Action: " + syncLeadToCRM.nextAction,
                        timestamp now(),
                        owner syncLeadToCRM.ownerId,
                        associated_contacts [contact.id]
                    }} @as note;
                    
                    {Task {
                        hs_task_subject "Follow up: " + syncLeadToCRM.nextAction,
                        hs_task_body "Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nAction: " + syncLeadToCRM.nextAction + "\n\nReasoning: " + syncLeadToCRM.reasoning,
                        hs_timestamp now() + (24 * 3600000),
                        hubspot_owner_id syncLeadToCRM.ownerId,
                        hs_task_status "NOT_STARTED",
                        hs_task_type "EMAIL",
                        hs_task_priority "MEDIUM",
                        associated_contacts [contact.id]
                    }} @as task;
                    
                    if (syncLeadToCRM.dealStage != "NONE") {
                        {Meeting {
                            meeting_title "Follow-up Discussion: " + syncLeadToCRM.nextAction,
                            meeting_body "Lead Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nDiscussion Points:\n- " + syncLeadToCRM.nextAction + "\n\nBackground:\n" + syncLeadToCRM.reasoning,
                            timestamp now() + (2 * 24 * 3600000),
                            meeting_start_time now() + (2 * 24 * 3600000),
                            meeting_end_time now() + (2 * 24 * 3600000) + (3600000),
                            owner syncLeadToCRM.ownerId,
                            meeting_outcome "SCHEDULED",
                            activity_type "MEETING",
                            associated_contacts [contact.id]
                        }} @as meeting;
                        
                        {CRMSyncResult {
                            companyId "",
                            companyName "",
                            contactId contact.id,
                            contactEmail contact.email,
                            dealId "",
                            dealCreated false,
                            noteId note.id,
                            taskId task.id,
                            meetingId meeting.id
                        }}
                    } else {
                        {CRMSyncResult {
                            companyId "",
                            companyName "",
                            contactId contact.id,
                            contactEmail contact.email,
                            dealId "",
                            dealCreated false,
                            noteId note.id,
                            taskId task.id,
                            meetingId ""
                        }}
                    }
                }
            } else {
                if (syncLeadToCRM.existingContactId) {
                    {Contact {id? syncLeadToCRM.existingContactId}} @as existingContacts;
                    existingContacts @as [contact];
                    
                    if (syncLeadToCRM.shouldCreateDeal) {
                        {Deal {
                            deal_name syncLeadToCRM.dealName,
                            deal_stage hubspotDealStage,
                            owner syncLeadToCRM.ownerId,
                            associated_contacts [contact.id],
                            description "Deal created from email thread"
                        }} @as deal;
                        
                        {Note {
                            note_body "Deal Created: " + deal.deal_name + "\nStage: " + syncLeadToCRM.dealStage + "\n\nLead Analysis: " + syncLeadToCRM.reasoning + "\nScore: " + syncLeadToCRM.leadScore + "\nNext Action: " + syncLeadToCRM.nextAction,
                            timestamp now(),
                            owner syncLeadToCRM.ownerId,
                            associated_contacts [contact.id],
                            associated_deal deal.id
                        }} @as note;
                        
                        {Task {
                            hs_task_subject "Follow up: " + syncLeadToCRM.nextAction,
                            hs_task_body "Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nAction: " + syncLeadToCRM.nextAction + "\n\nReasoning: " + syncLeadToCRM.reasoning,
                            hs_timestamp now() + (24 * 3600000),
                            hubspot_owner_id syncLeadToCRM.ownerId,
                            hs_task_status "NOT_STARTED",
                            hs_task_type "EMAIL",
                            hs_task_priority "MEDIUM",
                            associated_contacts [contact.id],
                            associated_deal deal.id
                        }} @as task;
                        
                        {Meeting {
                            meeting_title "Follow-up Discussion: " + syncLeadToCRM.nextAction,
                            meeting_body "Lead Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nDiscussion Points:\n- " + syncLeadToCRM.nextAction + "\n\nBackground:\n" + syncLeadToCRM.reasoning,
                            timestamp now() + (2 * 24 * 3600000),
                            meeting_start_time now() + (2 * 24 * 3600000),
                            meeting_end_time now() + (2 * 24 * 3600000) + (3600000),
                            owner syncLeadToCRM.ownerId,
                            meeting_outcome "SCHEDULED",
                            activity_type "MEETING",
                            associated_contacts [contact.id],
                            associated_deals [deal.id]
                        }} @as meeting;
                        
                        {CRMSyncResult {
                            companyId "",
                            companyName "",
                            contactId contact.id,
                            contactEmail contact.email,
                            dealId deal.id,
                            dealCreated true,
                            noteId note.id,
                            taskId task.id,
                            meetingId meeting.id
                        }}
                    } else {
                        {Note {
                            note_body "Lead Analysis: " + syncLeadToCRM.reasoning + "\nScore: " + syncLeadToCRM.leadScore + "\nStage: " + syncLeadToCRM.leadStage + "\nNext Action: " + syncLeadToCRM.nextAction,
                            timestamp now(),
                            owner syncLeadToCRM.ownerId,
                            associated_contacts [contact.id]
                        }} @as note;
                        
                        {Task {
                            hs_task_subject "Follow up: " + syncLeadToCRM.nextAction,
                            hs_task_body "Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nAction: " + syncLeadToCRM.nextAction + "\n\nReasoning: " + syncLeadToCRM.reasoning,
                            hs_timestamp now() + (24 * 3600000),
                            hubspot_owner_id syncLeadToCRM.ownerId,
                            hs_task_status "NOT_STARTED",
                            hs_task_type "EMAIL",
                            hs_task_priority "MEDIUM",
                            associated_contacts [contact.id]
                        }} @as task;
                        
                        if (syncLeadToCRM.dealStage != "NONE") {
                            {Meeting {
                                meeting_title "Follow-up Discussion: " + syncLeadToCRM.nextAction,
                                meeting_body "Lead Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nDiscussion Points:\n- " + syncLeadToCRM.nextAction + "\n\nBackground:\n" + syncLeadToCRM.reasoning,
                                timestamp now() + (2 * 24 * 3600000),
                                meeting_start_time now() + (2 * 24 * 3600000),
                                meeting_end_time now() + (2 * 24 * 3600000) + (3600000),
                                owner syncLeadToCRM.ownerId,
                                meeting_outcome "SCHEDULED",
                                activity_type "MEETING",
                                associated_contacts [contact.id]
                            }} @as meeting;
                            
                            {CRMSyncResult {
                                companyId "",
                                companyName "",
                                contactId contact.id,
                                contactEmail contact.email,
                                dealId "",
                                dealCreated false,
                                noteId note.id,
                                taskId task.id,
                                meetingId meeting.id
                            }}
                        } else {
                            {CRMSyncResult {
                                companyId "",
                                companyName "",
                                contactId contact.id,
                                contactEmail contact.email,
                                dealId "",
                                dealCreated false,
                                noteId note.id,
                                taskId task.id,
                                meetingId ""
                            }}
                        }
                    }
                } else {
                    {upsertContactRecord {
                        email syncLeadToCRM.contactEmail,
                        first_name syncLeadToCRM.contactFirstName,
                        last_name syncLeadToCRM.contactLastName,
                        company ""
                    }} @as contact;
                    
                    if (syncLeadToCRM.shouldCreateDeal) {
                        {Deal {
                            deal_name syncLeadToCRM.dealName,
                            deal_stage hubspotDealStage,
                            owner syncLeadToCRM.ownerId,
                            associated_contacts [contact.id],
                            description "Deal created from email thread"
                        }} @as deal;
                        
                        {Note {
                            note_body "Deal Created: " + deal.deal_name + "\nStage: " + syncLeadToCRM.dealStage + "\n\nLead Analysis: " + syncLeadToCRM.reasoning + "\nScore: " + syncLeadToCRM.leadScore + "\nNext Action: " + syncLeadToCRM.nextAction,
                            timestamp now(),
                            owner syncLeadToCRM.ownerId,
                            associated_contacts [contact.id],
                            associated_deal deal.id
                        }} @as note;
                        
                        {Task {
                            hs_task_subject "Follow up: " + syncLeadToCRM.nextAction,
                            hs_task_body "Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nAction: " + syncLeadToCRM.nextAction + "\n\nReasoning: " + syncLeadToCRM.reasoning,
                            hs_timestamp now() + (24 * 3600000),
                            hubspot_owner_id syncLeadToCRM.ownerId,
                            hs_task_status "NOT_STARTED",
                            hs_task_type "EMAIL",
                            hs_task_priority "MEDIUM",
                            associated_contacts [contact.id],
                            associated_deal deal.id
                        }} @as task;
                        
                        {Meeting {
                            meeting_title "Follow-up Discussion: " + syncLeadToCRM.nextAction,
                            meeting_body "Lead Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nDiscussion Points:\n- " + syncLeadToCRM.nextAction + "\n\nBackground:\n" + syncLeadToCRM.reasoning,
                            timestamp now() + (2 * 24 * 3600000),
                            meeting_start_time now() + (2 * 24 * 3600000),
                            meeting_end_time now() + (2 * 24 * 3600000) + (3600000),
                            owner syncLeadToCRM.ownerId,
                            meeting_outcome "SCHEDULED",
                            activity_type "MEETING",
                            associated_contacts [contact.id],
                            associated_deals [deal.id]
                        }} @as meeting;
                        
                        {CRMSyncResult {
                            companyId "",
                            companyName "",
                            contactId contact.id,
                            contactEmail contact.email,
                            dealId deal.id,
                            dealCreated true,
                            noteId note.id,
                            taskId task.id,
                            meetingId meeting.id
                        }}
                    } else {
                        {Note {
                            note_body "Lead Analysis: " + syncLeadToCRM.reasoning + "\nScore: " + syncLeadToCRM.leadScore + "\nStage: " + syncLeadToCRM.leadStage + "\nNext Action: " + syncLeadToCRM.nextAction,
                            timestamp now(),
                            owner syncLeadToCRM.ownerId,
                            associated_contacts [contact.id]
                        }} @as note;
                        
                        {Task {
                            hs_task_subject "Follow up: " + syncLeadToCRM.nextAction,
                            hs_task_body "Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nAction: " + syncLeadToCRM.nextAction + "\n\nReasoning: " + syncLeadToCRM.reasoning,
                            hs_timestamp now() + (24 * 3600000),
                            hubspot_owner_id syncLeadToCRM.ownerId,
                            hs_task_status "NOT_STARTED",
                            hs_task_type "EMAIL",
                            hs_task_priority "MEDIUM",
                            associated_contacts [contact.id]
                        }} @as task;
                        
                        if (syncLeadToCRM.dealStage != "NONE") {
                            {Meeting {
                                meeting_title "Follow-up Discussion: " + syncLeadToCRM.nextAction,
                                meeting_body "Lead Stage: " + syncLeadToCRM.leadStage + " (Score: " + syncLeadToCRM.leadScore + ")\n\nDiscussion Points:\n- " + syncLeadToCRM.nextAction + "\n\nBackground:\n" + syncLeadToCRM.reasoning,
                                timestamp now() + (2 * 24 * 3600000),
                                meeting_start_time now() + (2 * 24 * 3600000),
                                meeting_end_time now() + (2 * 24 * 3600000) + (3600000),
                                owner syncLeadToCRM.ownerId,
                                meeting_outcome "SCHEDULED",
                                activity_type "MEETING",
                                associated_contacts [contact.id]
                            }} @as meeting;
                            
                            {CRMSyncResult {
                                companyId "",
                                companyName "",
                                contactId contact.id,
                                contactEmail contact.email,
                                dealId "",
                                dealCreated false,
                                noteId note.id,
                                taskId task.id,
                                meetingId meeting.id
                            }}
                        } else {
                            {CRMSyncResult {
                                companyId "",
                                companyName "",
                                contactId contact.id,
                                contactEmail contact.email,
                                dealId "",
                                dealCreated false,
                                noteId note.id,
                                taskId task.id,
                                meetingId ""
                            }}
                        }
                    }
                }
            }
        }
    }
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
