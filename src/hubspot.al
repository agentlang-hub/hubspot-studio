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
    archived Boolean @optional
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
    associated_contacts String @optional,
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
    task_type String @optional,
    title String @optional,
    priority String @optional,
    assigned_to String @optional,
    due_date String @optional,
    status String @optional,
    description String @optional,
    owner String @optional,
    associated_contact String @optional,
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
    associated_contacts String @optional,
    associated_companies String @optional,
    associated_deals String @optional,
    properties Map @optional,
    createdAt String @optional,
    updatedAt String @optional,
    archived Boolean @optional
}

entity Note {
    id String @id @default(uuid()),
    created_date String @optional,
    note_body String @optional,
    owner String @optional,
    associated_contact String @optional,
    associated_contacts String @optional,
    associated_company String @optional,
    associated_deal String @optional,
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

                    For notes, you can associate them with contacts, companies, or deals by providing IDs in associated_contact, associated_company, or associated_deal fields.

                    Use the appropriate tool based on the entity type and operation requested.
                    For queries, you can search by ID or retrieve all records.
                    For updates, provide the entity ID and the fields to update.
                    For deletions, provide the entity ID to remove.",
    tools [hubspot/Contact, hubspot/Company, hubspot/Deal, hubspot/Owner, hubspot/Task, hubspot/Note, hubspot/Meeting, hubspot/MeetingAssociation, hubspot/MeetingDisassociation, hubspot/MeetingAssociationQuery]
}
