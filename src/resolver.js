// Import agentlang modules
import { makeInstance } from "agentlang/out/runtime/module.js";
import { getLocalEnv } from "agentlang/out/runtime/auth/defs.js";

function asInstance(entity, entityType) {
    const instanceMap = new Map(Object.entries(entity));
    return makeInstance("hubspot", entityType, instanceMap);
}

// Field mappings for each entity type (AgentLang field -> HubSpot property)
const FIELD_MAPPINGS = {
    Contact: {
        email: "email",
        first_name: "firstname",
        last_name: "lastname",
        job_title: "jobtitle",
        mobile_phone_number: "mobilephone",
        website_url: "website",
        lead_status: "hs_lead_status",
        lifecycle_stage: "lifecyclestage",
        owner: "hubspot_owner_id",
        last_contacted: "lastcontacted",
        last_activity_date: "lastactivitydate",
        salutation: "salutation",
    },
    Company: {
        name: "name",
        industry: "industry",
        description: "description",
        country: "country",
        city: "city",
        lead_status: "hs_lead_status",
        lifecycle_stage: "lifecyclestage",
        owner: "hubspot_owner_id",
        year_founded: "founded_year",
        website_url: "website",
    },
    Deal: {
        deal_name: "dealname",
        deal_stage: "dealstage",
        amount: "amount",
        close_date: "closedate",
        deal_type: "dealtype",
        description: "description",
        owner: "hubspot_owner_id",
        pipeline: "pipeline",
        priority: "priority",
    },
    Task: {
        task_type: "hs_task_type",
        title: "hs_task_subject",
        priority: "hs_task_priority",
        assigned_to: "hs_task_assigned_to",
        due_date: "hs_task_due_date",
        status: "hs_task_status",
        description: "hs_task_body",
        owner: "hubspot_owner_id",
    },
    Meeting: {
        timestamp: "hs_timestamp",
        meeting_title: "hs_meeting_title",
        owner: "hubspot_owner_id",
        meeting_body: "hs_meeting_body",
        internal_meeting_notes: "hs_internal_meeting_notes",
        meeting_external_url: "hs_meeting_external_url",
        meeting_location: "hs_meeting_location",
        meeting_start_time: "hs_meeting_start_time",
        meeting_end_time: "hs_meeting_end_time",
        meeting_outcome: "hs_meeting_outcome",
        activity_type: "hs_activity_type",
    },
    Owner: {
        email: "email",
        first_name: "firstName",
        last_name: "lastName",
        user_id: "userId",
    },
};

/**
 * Generic query function that supports filtering by properties using HubSpot Search API
 * @param {string} objectType - The HubSpot object type (contacts, companies, deals, tasks, meetings, owners)
 * @param {string} entityType - The AgentLang entity type (Contact, Company, Deal, etc.)
 * @param {object} attrs - Query attributes from AgentLang
 * @returns {Array} Array of entity instances
 */
async function queryWithFilters(objectType, entityType, attrs) {
    const id =
        attrs.queryAttributeValues?.get("__path__")?.split("/")?.pop() ?? null;

    try {
        let inst;

        // Case 1: Query by ID
        if (id) {
            inst = await makeGetRequest(`/crm/v3/objects/${objectType}/${id}`);
            if (!(inst instanceof Array)) {
                inst = [inst];
            }
        }
        // Case 2: Query by property filters or get all
        else {
            const filters = [];
            const fieldMapping = FIELD_MAPPINGS[entityType] || {};

            // Build filters from query attributes
            if (attrs.queryAttributeValues) {
                for (const [
                    key,
                    value,
                ] of attrs.queryAttributeValues.entries()) {
                    // Skip internal fields
                    if (key.startsWith("__")) continue;

                    const hubspotProperty = fieldMapping[key] || key;

                    if (value !== null && value !== undefined) {
                        filters.push({
                            propertyName: hubspotProperty,
                            operator: "EQ",
                            value: String(value),
                        });
                    }
                }
            }

            // If we have filters, use Search API
            if (filters.length > 0) {
                const searchBody = {
                    filterGroups: [
                        {
                            filters: filters,
                        },
                    ],
                    limit: 100,
                };

                const result = await makePostRequest(
                    `/crm/v3/objects/${objectType}/search`,
                    searchBody,
                );
                inst = result.results || [];
            }
            // No filters - get all records
            else {
                const result = await makeGetRequest(
                    `/crm/v3/objects/${objectType}`,
                );
                inst = result.results || [];
            }
        }

        if (!(inst instanceof Array)) {
            inst = [inst];
        }

        return inst.map((data) => {
            return asInstance(data, entityType);
        });
    } catch (error) {
        console.error(
            `HUBSPOT RESOLVER: Failed to query ${objectType}: ${error}`,
        );
        return { result: "error", message: error.message };
    }
}

const getResponseBody = async (response) => {
    try {
        try {
            return await response.json();
        } catch (e) {
            return await response.text();
        }
    } catch (error) {
        console.error("HUBSPOT RESOLVER: Error reading response body:", error);
        return {};
    }
};

// Generic HTTP functions
const makeRequest = async (endpoint, options = {}) => {
    // Get configuration from agentlang environment
    const accessToken = getLocalEnv("HUBSPOT_ACCESS_TOKEN");
    const corsProxyUrl =
        getLocalEnv("VITE_API_CORS_PROXY_URL") || "http://localhost:9999";

    if (!accessToken) {
        throw new Error(
            "HubSpot access token is required. Set HUBSPOT_ACCESS_TOKEN in environment keys.",
        );
    }

    // Route through CORS proxy: http://localhost:9999/proxy/hubspot/crm/v3/...
    const url = `${corsProxyUrl}/proxy/hubspot${endpoint}`;

    const defaultOptions = {
        headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${accessToken}`,
        },
    };

    const config = { ...defaultOptions, ...options };

    // Remove Content-Type header for GET requests without body
    if (config.method === "GET") {
        delete config.headers["Content-Type"];
    }

    const timeoutMs = 30000;
    const controller = new AbortController();
    const timeoutId = setTimeout(() => {
        console.error(
            `HUBSPOT RESOLVER: Request timeout after ${timeoutMs}ms - ${url} - ${JSON.stringify(options)}`,
        );
        controller.abort();
    }, timeoutMs);

    try {
        const response = await fetch(url, {
            ...config,
            signal: controller.signal,
        });

        const body = await getResponseBody(response);

        clearTimeout(timeoutId);

        if (!response.ok) {
            console.error(
                `HUBSPOT RESOLVER: HTTP Error ${response.status} - ${url} - ${JSON.stringify(options)}`,
            );
            throw new Error(
                `HTTP Error: ${response.status} - ${JSON.stringify(body)}`,
            );
        }

        return body;
    } catch (error) {
        clearTimeout(timeoutId);

        if (error.name === "AbortError") {
            console.error(
                `HUBSPOT RESOLVER: Request timeout - ${url} - ${JSON.stringify(options)}`,
            );
        } else if (
            error.code === "ENOTFOUND" ||
            error.code === "ECONNREFUSED" ||
            error.code === "EHOSTUNREACH"
        ) {
            console.error(
                `HUBSPOT RESOLVER: Network unreachable (${error.code}) - ${url} - ${JSON.stringify(options)}`,
            );
        } else if (error.code === "ECONNRESET" || error.code === "ETIMEDOUT") {
            console.error(
                `HUBSPOT RESOLVER: Connection error (${error.code}) - ${url} - ${JSON.stringify(options)}`,
            );
        } else {
            console.error(
                `HUBSPOT RESOLVER: Request failed (${error.name}) - ${url} - ${JSON.stringify(options)}`,
            );
        }

        throw error;
    }
};

const makeGetRequest = async (endpoint) => {
    return await makeRequest(endpoint, { method: "GET" });
};

const makePostRequest = async (endpoint, body) => {
    return await makeRequest(endpoint, {
        method: "POST",
        body: JSON.stringify(body),
    });
};

const makePatchRequest = async (endpoint, body) => {
    return await makeRequest(endpoint, {
        method: "PATCH",
        body: JSON.stringify(body),
    });
};

const makeDeleteRequest = async (endpoint) => {
    return await makeRequest(endpoint, { method: "DELETE" });
};

const makePutRequest = async (endpoint, body = null) => {
    const options = { method: "PUT" };
    if (body) {
        options.body = JSON.stringify(body);
    }
    return await makeRequest(endpoint, options);
};

// Contact functions
export const createContact = async (env, attributes) => {
    const data = {
        properties: {
            firstname: attributes.attributes.get("first_name"),
            lastname: attributes.attributes.get("last_name"),
            email: attributes.attributes.get("email"),
            jobtitle: attributes.attributes.get("job_title"),
            lastcontacted: attributes.attributes.get("last_contacted"),
            lastactivitydate: attributes.attributes.get("last_activity_date"),
            hs_lead_status: attributes.attributes.get("lead_status"),
            lifecyclestage: attributes.attributes.get("lifecycle_stage"),
            salutation: attributes.attributes.get("salutation"),
            mobilephone: attributes.attributes.get("mobile_phone_number"),
            website: attributes.attributes.get("website_url"),
            hubspot_owner_id: attributes.attributes.get("owner"),
        },
    };

    try {
        const result = await makePostRequest("/crm/v3/objects/contacts", data);
        return { result: "success", id: result.id };
    } catch (error) {
        console.error(`HUBSPOT RESOLVER: Failed to create contact: ${error}`);
        return { result: "error", message: error.message };
    }
};

export const queryContact = async (env, attrs) => {
    return await queryWithFilters("contacts", "Contact", attrs);
};

export const updateContact = async (env, attributes, newAttrs) => {
    const id = attributes.attributes.get("id");
    if (!id) {
        return {
            result: "error",
            message: "Contact ID is required for update",
        };
    }

    const data = {
        properties: {
            firstname: newAttrs.get("first_name"),
            lastname: newAttrs.get("last_name"),
            email: newAttrs.get("email"),
            jobtitle: newAttrs.get("job_title"),
            lastcontacted: newAttrs.get("last_contacted"),
            lastactivitydate: newAttrs.get("last_activity_date"),
            hs_lead_status: newAttrs.get("lead_status"),
            lifecyclestage: newAttrs.get("lifecycle_stage"),
            salutation: newAttrs.get("salutation"),
            mobilephone: newAttrs.get("mobile_phone_number"),
            website: newAttrs.get("website_url"),
            hubspot_owner_id: newAttrs.get("owner"),
        },
    };

    try {
        const result = await makePatchRequest(
            `/crm/v3/objects/contacts/${id}`,
            data,
        );
        return asInstance(result, "Contact");
    } catch (error) {
        console.error(`HUBSPOT RESOLVER: Failed to update contact: ${error}`);
        return { result: "error", message: error.message };
    }
};

export const deleteContact = async (env, attributes) => {
    const id = attributes.attributes.get("id");
    if (!id) {
        return {
            result: "error",
            message: "Contact ID is required for deletion",
        };
    }

    try {
        await makeDeleteRequest(`/crm/v3/objects/contacts/${id}`);
        return { result: "success" };
    } catch (error) {
        console.error(`HUBSPOT RESOLVER: Failed to delete contact: ${error}`);
        return { result: "error", message: error.message };
    }
};

// Company functions
export const createCompany = async (env, attributes) => {
    const data = {
        properties: {
            name: attributes.attributes.get("name"),
            industry: attributes.attributes.get("industry"),
            description: attributes.attributes.get("description"),
            country: attributes.attributes.get("country"),
            city: attributes.attributes.get("city"),
            hs_lead_status: attributes.attributes.get("lead_status"),
            lifecyclestage: attributes.attributes.get("lifecycle_stage"),
            hubspot_owner_id: attributes.attributes.get("owner"),
            founded_year: attributes.attributes.get("year_founded"),
            website: attributes.attributes.get("website_url"),
        },
    };

    try {
        const result = await makePostRequest("/crm/v3/objects/companies", data);
        return { result: "success", id: result.id };
    } catch (error) {
        console.error(`HUBSPOT RESOLVER: Failed to create company: ${error}`);
        return { result: "error", message: error.message };
    }
};

export const queryCompany = async (env, attrs) => {
    return await queryWithFilters("companies", "Company", attrs);
};

export const updateCompany = async (env, attributes, newAttrs) => {
    const id = attributes.attributes.get("id");
    if (!id) {
        return {
            result: "error",
            message: "Company ID is required for update",
        };
    }

    const data = {
        properties: {
            name: newAttrs.get("name"),
            industry: newAttrs.get("industry"),
            description: newAttrs.get("description"),
            country: newAttrs.get("country"),
            city: newAttrs.get("city"),
            hs_lead_status: newAttrs.get("lead_status"),
            lifecyclestage: newAttrs.get("lifecycle_stage"),
            hubspot_owner_id: newAttrs.get("owner"),
            founded_year: newAttrs.get("year_founded"),
            website: newAttrs.get("website_url"),
        },
    };

    try {
        const result = await makePatchRequest(
            `/crm/v3/objects/companies/${id}`,
            data,
        );
        return asInstance(result, "Company");
    } catch (error) {
        console.error(`HUBSPOT RESOLVER: Failed to update company: ${error}`);
        return { result: "error", message: error.message };
    }
};

export const deleteCompany = async (env, attributes) => {
    const id = attributes.attributes.get("id");
    if (!id) {
        return {
            result: "error",
            message: "Company ID is required for deletion",
        };
    }

    try {
        await makeDeleteRequest(`/crm/v3/objects/companies/${id}`);
        return { result: "success" };
    } catch (error) {
        console.error(`HUBSPOT RESOLVER: Failed to delete company: ${error}`);
        return { result: "error", message: error.message };
    }
};

// Deal functions
export const createDeal = async (env, attributes) => {
    const data = {
        properties: {
            dealname: attributes.attributes.get("deal_name"),
            dealstage: attributes.attributes.get("deal_stage"),
            amount: attributes.attributes.get("amount"),
            closedate: attributes.attributes.get("close_date"),
            dealtype: attributes.attributes.get("deal_type"),
            description: attributes.attributes.get("description"),
            hubspot_owner_id: attributes.attributes.get("owner"),
            pipeline: attributes.attributes.get("pipeline"),
            priority: attributes.attributes.get("priority"),
        },
    };

    try {
        const result = await makePostRequest("/crm/v3/objects/deals", data);
        return { result: "success", id: result.id };
    } catch (error) {
        console.error(`HUBSPOT RESOLVER: Failed to create deal: ${error}`);
        return { result: "error", message: error.message };
    }
};

export const queryDeal = async (env, attrs) => {
    return await queryWithFilters("deals", "Deal", attrs);
};

export const updateDeal = async (env, attributes, newAttrs) => {
    const id = attributes.attributes.get("id");
    if (!id) {
        return { result: "error", message: "Deal ID is required for update" };
    }

    const data = {
        properties: {
            dealname: newAttrs.get("deal_name"),
            dealstage: newAttrs.get("deal_stage"),
            amount: newAttrs.get("amount"),
            closedate: newAttrs.get("close_date"),
            dealtype: newAttrs.get("deal_type"),
            description: newAttrs.get("description"),
            hubspot_owner_id: newAttrs.get("owner"),
            pipeline: newAttrs.get("pipeline"),
            priority: newAttrs.get("priority"),
        },
    };

    try {
        const result = await makePatchRequest(
            `/crm/v3/objects/deals/${id}`,
            data,
        );
        return asInstance(result, "Deal");
    } catch (error) {
        console.error(`HUBSPOT RESOLVER: Failed to update deal: ${error}`);
        return { result: "error", message: error.message };
    }
};

export const deleteDeal = async (env, attributes) => {
    const id = attributes.attributes.get("id");
    if (!id) {
        return { result: "error", message: "Deal ID is required for deletion" };
    }

    try {
        await makeDeleteRequest(`/crm/v3/objects/deals/${id}`);
        return { result: "success" };
    } catch (error) {
        console.error(`HUBSPOT RESOLVER: Failed to delete deal: ${error}`);
        return { result: "error", message: error.message };
    }
};

// Owner functions
export const createOwner = async (env, attributes) => {
    const data = {
        email: attributes.attributes.get("email"),
        firstName: attributes.attributes.get("first_name"),
        lastName: attributes.attributes.get("last_name"),
    };

    try {
        const result = await makePostRequest("/crm/v3/owners", data);
        return { result: "success", id: result.id };
    } catch (error) {
        console.error(`HUBSPOT RESOLVER: Failed to create owner: ${error}`);
        return { result: "error", message: error.message };
    }
};

export const queryOwner = async (env, attrs) => {
    const id =
        attrs.queryAttributeValues?.get("__path__")?.split("/")?.pop() ?? null;

    try {
        let inst;

        // Case 1: Query by ID
        if (id) {
            inst = await makeGetRequest(`/crm/v3/owners/${id}`);
            if (!(inst instanceof Array)) {
                inst = [inst];
            }
        }
        // Case 2: Query by email or get all
        else {
            const email = attrs.queryAttributeValues?.get("email");

            if (email) {
                // Get all owners and filter by email client-side
                // HubSpot owners API doesn't support search filters like contacts

                const result = await makeGetRequest(`/crm/v3/owners/`);
                const allOwners = result.results || [];

                // Filter by email
                inst = allOwners.filter((owner) => owner.email === email);
            } else {
                // No filters - get all owners
                const result = await makeGetRequest(`/crm/v3/owners/`);
                inst = result.results || [];
            }
        }

        if (!(inst instanceof Array)) {
            inst = [inst];
        }

        return inst.map((data) => {
            // Transform HubSpot API response (camelCase) to AgentLang entity schema (snake_case)
            const transformed = {
                id: data.id,
                email: data.email,
                first_name: data.firstName,
                last_name: data.lastName,
                user_id: data.userId,
                created_at: data.createdAt,
                updated_at: data.updatedAt,
                archived: data.archived,
            };
            return asInstance(transformed, "Owner");
        });
    } catch (error) {
        console.error(`HUBSPOT RESOLVER: Failed to query owners: ${error}`);
        return { result: "error", message: error.message };
    }
};

export const updateOwner = async (env, attributes, newAttrs) => {
    const id = attributes.attributes.get("id");
    if (!id) {
        return { result: "error", message: "Owner ID is required for update" };
    }

    const data = {
        email: newAttrs.get("email"),
        firstName: newAttrs.get("first_name"),
        lastName: newAttrs.get("last_name"),
    };

    try {
        const result = await makePatchRequest(`/crm/v3/owners/${id}`, data);
        return asInstance(result, "Owner");
    } catch (error) {
        console.error(`HUBSPOT RESOLVER: Failed to update owner: ${error}`);
        return { result: "error", message: error.message };
    }
};

export const deleteOwner = async (env, attributes) => {
    const id = attributes.attributes.get("id");
    if (!id) {
        return {
            result: "error",
            message: "Owner ID is required for deletion",
        };
    }

    try {
        await makeDeleteRequest(`/crm/v3/owners/${id}`);
        return { result: "success" };
    } catch (error) {
        console.error(`HUBSPOT RESOLVER: Failed to delete owner: ${error}`);
        return { result: "error", message: error.message };
    }
};

// Task functions
export const createTask = async (env, attributes) => {
    const data = {
        properties: {
            hs_task_type: attributes.attributes.get("task_type"),
            hs_task_subject: attributes.attributes.get("title"),
            hs_task_priority: attributes.attributes.get("priority"),
            hs_task_assigned_to: attributes.attributes.get("assigned_to"),
            hs_task_due_date: attributes.attributes.get("due_date"),
            hs_task_status: attributes.attributes.get("status"),
            hs_task_body: attributes.attributes.get("description"),
            hubspot_owner_id: attributes.attributes.get("owner"),
        },
    };

    try {
        const result = await makePostRequest("/crm/v3/objects/tasks", data);
        return { result: "success", id: result.id };
    } catch (error) {
        console.error(`HUBSPOT RESOLVER: Failed to create task: ${error}`);
        return { result: "error", message: error.message };
    }
};

export const queryTask = async (env, attrs) => {
    return await queryWithFilters("tasks", "Task", attrs);
};

export const updateTask = async (env, attributes, newAttrs) => {
    const id = attributes.attributes.get("id");
    if (!id) {
        return { result: "error", message: "Task ID is required for update" };
    }

    const data = {
        properties: {
            hs_task_type: newAttrs.get("task_type"),
            hs_task_subject: newAttrs.get("title"),
            hs_task_priority: newAttrs.get("priority"),
            hs_task_assigned_to: newAttrs.get("assigned_to"),
            hs_task_due_date: newAttrs.get("due_date"),
            hs_task_status: newAttrs.get("status"),
            hs_task_body: newAttrs.get("description"),
            hubspot_owner_id: newAttrs.get("owner"),
        },
    };

    try {
        const result = await makePatchRequest(
            `/crm/v3/objects/tasks/${id}`,
            data,
        );
        return asInstance(result, "Task");
    } catch (error) {
        console.error(`HUBSPOT RESOLVER: Failed to update task: ${error}`);
        return { result: "error", message: error.message };
    }
};

export const deleteTask = async (env, attributes) => {
    const id = attributes.attributes.get("id");
    if (!id) {
        return { result: "error", message: "Task ID is required for deletion" };
    }

    try {
        await makeDeleteRequest(`/crm/v3/objects/tasks/${id}`);
        return { result: "success" };
    } catch (error) {
        console.error(`HUBSPOT RESOLVER: Failed to delete task: ${error}`);
        return { result: "error", message: error.message };
    }
};

// Subscription functions for real-time updates
async function getAndProcessRecords(resolver, entityType) {
    try {
        let endpoint;
        switch (entityType) {
            case "contacts":
                endpoint = "/crm/v3/objects/contacts";
                break;
            case "companies":
                endpoint = "/crm/v3/objects/companies";
                break;
            case "deals":
                endpoint = "/crm/v3/objects/deals";
                break;
            case "owners":
                endpoint = "/crm/v3/owners";
                break;
            case "tasks":
                endpoint = "/crm/v3/objects/tasks";
                break;
            case "meetings":
                endpoint = "/crm/v3/objects/meetings";
                break;
            default:
                console.error(
                    `HUBSPOT RESOLVER: Unknown entity type: ${entityType}`,
                );
                return;
        }

        const result = await makeGetRequest(endpoint);

        if (result && result.results && Array.isArray(result.results)) {
            for (let i = 0; i < result.results.length; ++i) {
                const record = result.results[i];

                // Create instance for subscription
                const inst = {
                    id: record.id,
                    type: entityType,
                    data: record,
                    timestamp: new Date().toISOString(),
                };

                await resolver.onSubscription(inst, true);
            }
        }
    } catch (error) {
        console.error(
            `HUBSPOT RESOLVER: Failed to process ${entityType} records: ${error}`,
        );
    }
}

async function handleSubsContacts(resolver) {
    await getAndProcessRecords(resolver, "contacts");
}

async function handleSubsCompanies(resolver) {
    await getAndProcessRecords(resolver, "companies");
}

async function handleSubsDeals(resolver) {
    await getAndProcessRecords(resolver, "deals");
}

async function handleSubsOwners(resolver) {
    await getAndProcessRecords(resolver, "owners");
}

async function handleSubsTasks(resolver) {
    await getAndProcessRecords(resolver, "tasks");
}

export async function subsContacts(resolver) {
    await handleSubsContacts(resolver);
    const intervalMinutes =
        parseInt(getLocalEnv("HUBSPOT_POLL_INTERVAL_MINUTES")) || 15;
    const intervalMs = intervalMinutes * 60 * 1000;
    setInterval(async () => {
        await handleSubsContacts(resolver);
    }, intervalMs);
}

export async function subsCompanies(resolver) {
    await handleSubsCompanies(resolver);
    const intervalMinutes =
        parseInt(getLocalEnv("HUBSPOT_POLL_INTERVAL_MINUTES")) || 15;
    const intervalMs = intervalMinutes * 60 * 1000;
    setInterval(async () => {
        await handleSubsCompanies(resolver);
    }, intervalMs);
}

export async function subsDeals(resolver) {
    await handleSubsDeals(resolver);
    const intervalMinutes =
        parseInt(getLocalEnv("HUBSPOT_POLL_INTERVAL_MINUTES")) || 15;
    const intervalMs = intervalMinutes * 60 * 1000;
    setInterval(async () => {
        await handleSubsDeals(resolver);
    }, intervalMs);
}

export async function subsOwners(resolver) {
    await handleSubsOwners(resolver);
    const intervalMinutes =
        parseInt(getLocalEnv("HUBSPOT_POLL_INTERVAL_MINUTES")) || 15;
    const intervalMs = intervalMinutes * 60 * 1000;
    setInterval(async () => {
        await handleSubsOwners(resolver);
    }, intervalMs);
}

export async function subsTasks(resolver) {
    await handleSubsTasks(resolver);
    const intervalMinutes =
        parseInt(getLocalEnv("HUBSPOT_POLL_INTERVAL_MINUTES")) || 15;
    const intervalMs = intervalMinutes * 60 * 1000;
    setInterval(async () => {
        await handleSubsTasks(resolver);
    }, intervalMs);
}

// Association helper functions
// Standard HubSpot association type IDs for meetings
const ASSOCIATION_TYPES = {
    MEETING_TO_CONTACT: 200,
    CONTACT_TO_MEETING: 201,
    MEETING_TO_COMPANY: 202,
    COMPANY_TO_MEETING: 203,
    MEETING_TO_DEAL: 206,
    DEAL_TO_MEETING: 207,
};

/**
 * Create an association between a meeting and another object
 * @param {string} meetingId - The meeting ID
 * @param {string} toObjectType - The target object type (contacts, companies, deals)
 * @param {string} toObjectId - The target object ID
 * @param {number} associationTypeId - The association type ID (optional, will use default if not provided)
 */
const createMeetingAssociation = async (
    meetingId,
    toObjectType,
    toObjectId,
    associationTypeId = null,
) => {
    // Determine the association type ID if not provided
    let typeId = associationTypeId;
    if (!typeId) {
        switch (toObjectType) {
            case "contacts":
                typeId = ASSOCIATION_TYPES.MEETING_TO_CONTACT;
                break;
            case "companies":
                typeId = ASSOCIATION_TYPES.MEETING_TO_COMPANY;
                break;
            case "deals":
                typeId = ASSOCIATION_TYPES.MEETING_TO_DEAL;
                break;
            default:
                throw new Error(
                    `Unknown object type for association: ${toObjectType}`,
                );
        }
    }

    const endpoint = `/crm/v3/objects/meetings/${meetingId}/associations/${toObjectType}/${toObjectId}/${typeId}`;

    try {
        await makePutRequest(endpoint);
        return { result: "success" };
    } catch (error) {
        console.error(
            `HUBSPOT RESOLVER: Failed to create association: ${error.message}`,
        );
        throw error;
    }
};

/**
 * Create multiple associations for a meeting
 * @param {string} meetingId - The meeting ID
 * @param {Object} associations - Object with arrays of IDs for contacts, companies, deals
 * Example: { contacts: ["123", "456"], companies: ["789"], deals: ["012"] }
 */
const createMeetingAssociations = async (meetingId, associations) => {
    const results = [];

    if (associations.contacts && Array.isArray(associations.contacts)) {
        for (const contactId of associations.contacts) {
            try {
                await createMeetingAssociation(
                    meetingId,
                    "contacts",
                    contactId,
                );
                results.push({
                    type: "contact",
                    id: contactId,
                    status: "success",
                });
            } catch (error) {
                results.push({
                    type: "contact",
                    id: contactId,
                    status: "error",
                    message: error.message,
                });
            }
        }
    }

    if (associations.companies && Array.isArray(associations.companies)) {
        for (const companyId of associations.companies) {
            try {
                await createMeetingAssociation(
                    meetingId,
                    "companies",
                    companyId,
                );
                results.push({
                    type: "company",
                    id: companyId,
                    status: "success",
                });
            } catch (error) {
                results.push({
                    type: "company",
                    id: companyId,
                    status: "error",
                    message: error.message,
                });
            }
        }
    }

    if (associations.deals && Array.isArray(associations.deals)) {
        for (const dealId of associations.deals) {
            try {
                await createMeetingAssociation(meetingId, "deals", dealId);
                results.push({ type: "deal", id: dealId, status: "success" });
            } catch (error) {
                results.push({
                    type: "deal",
                    id: dealId,
                    status: "error",
                    message: error.message,
                });
            }
        }
    }

    return results;
};

/**
 * Remove an association between a meeting and another object
 */
const removeMeetingAssociation = async (
    meetingId,
    toObjectType,
    toObjectId,
    associationTypeId = null,
) => {
    let typeId = associationTypeId;
    if (!typeId) {
        switch (toObjectType) {
            case "contacts":
                typeId = ASSOCIATION_TYPES.MEETING_TO_CONTACT;
                break;
            case "companies":
                typeId = ASSOCIATION_TYPES.MEETING_TO_COMPANY;
                break;
            case "deals":
                typeId = ASSOCIATION_TYPES.MEETING_TO_DEAL;
                break;
            default:
                throw new Error(
                    `Unknown object type for association: ${toObjectType}`,
                );
        }
    }

    const endpoint = `/crm/v3/objects/meetings/${meetingId}/associations/${toObjectType}/${toObjectId}/${typeId}`;

    try {
        await makeDeleteRequest(endpoint);
        return { result: "success" };
    } catch (error) {
        console.error(
            `HUBSPOT RESOLVER: Failed to remove association: ${error.message}`,
        );
        throw error;
    }
};

/**
 * Get all associations for a meeting
 */
const getMeetingAssociations = async (meetingId, toObjectType) => {
    const endpoint = `/crm/v3/objects/meetings/${meetingId}/associations/${toObjectType}`;

    try {
        const result = await makeGetRequest(endpoint);
        return result;
    } catch (error) {
        console.error(
            `HUBSPOT RESOLVER: Failed to get associations: ${error.message}`,
        );
        throw error;
    }
};

/**
 * Convert ISO 8601 date string to Unix milliseconds
 * @param {string} isoDate - ISO 8601 date string
 * @returns {string} Unix milliseconds as string
 */
const isoToUnixMs = (isoDate) => {
    return String(new Date(isoDate).getTime());
};

// Meeting functions
export const createMeeting = async (env, attributes) => {

    // Get the meeting date (could be ISO 8601 or already Unix milliseconds)
    const meetingDate = attributes.attributes.get("meeting_date");
    const timestamp = attributes.attributes.get("timestamp");
    const startTime = attributes.attributes.get("meeting_start_time");
    const endTime = attributes.attributes.get("meeting_end_time");

    // Calculate times with smart defaults
    let calculatedTimestamp;
    let calculatedStartTime;
    let calculatedEndTime;

    // Priority: meeting_date -> timestamp -> meeting_start_time
    if (meetingDate) {
        // If meeting_date is provided, use it as the primary source
        calculatedTimestamp =
            meetingDate.includes("T") || meetingDate.includes("-")
                ? isoToUnixMs(meetingDate)
                : meetingDate;
        calculatedStartTime = startTime || calculatedTimestamp;
    } else if (timestamp) {
        calculatedTimestamp =
            timestamp.includes("T") || timestamp.includes("-")
                ? isoToUnixMs(timestamp)
                : timestamp;
        calculatedStartTime = startTime || calculatedTimestamp;
    } else if (startTime) {
        calculatedStartTime =
            startTime.includes("T") || startTime.includes("-")
                ? isoToUnixMs(startTime)
                : startTime;
        calculatedTimestamp = calculatedStartTime;
    } else {
        // No time provided at all, use current time
        const now = String(Date.now());
        calculatedTimestamp = now;
        calculatedStartTime = now;
    }

    // Calculate end time: if not provided, default to start + 1 hour (3600000ms)
    if (endTime) {
        calculatedEndTime =
            endTime.includes("T") || endTime.includes("-")
                ? isoToUnixMs(endTime)
                : endTime;
    } else {
        // Default to 1 hour meeting duration
        calculatedEndTime = String(parseInt(calculatedStartTime) + 3600000);
    }

    // Build properties object, filtering out undefined/null values
    const rawProperties = {
        hs_timestamp: calculatedTimestamp,
        hs_meeting_title: attributes.attributes.get("meeting_title"),
        hubspot_owner_id: attributes.attributes.get("owner"),
        hs_meeting_body: attributes.attributes.get("meeting_body"),
        hs_internal_meeting_notes: attributes.attributes.get(
            "internal_meeting_notes",
        ),
        hs_meeting_external_url: attributes.attributes.get(
            "meeting_external_url",
        ),
        hs_meeting_location: attributes.attributes.get("meeting_location"),
        hs_meeting_start_time: calculatedStartTime,
        hs_meeting_end_time: calculatedEndTime,
        hs_meeting_outcome:
            attributes.attributes.get("meeting_outcome") || "COMPLETED",
        hs_activity_type: attributes.attributes.get("activity_type"),
        hs_attachment_ids: attributes.attributes.get("attachment_ids"),
    };

    // Filter out undefined and null values
    const properties = Object.fromEntries(
        Object.entries(rawProperties).filter(([_, value]) => value != null),
    );

    const data = { properties };

    // Validate required fields for meeting creation
    const requiredFields = {
        hs_timestamp: properties.hs_timestamp,
        hs_meeting_title: properties.hs_meeting_title,
        hs_meeting_outcome: properties.hs_meeting_outcome,
        hs_meeting_start_time: properties.hs_meeting_start_time,
        hs_meeting_end_time: properties.hs_meeting_end_time,
    };

    const missingFields = Object.entries(requiredFields)
        .filter(([_, value]) => !value)
        .map(([key]) => key);

    if (missingFields.length > 0) {
        const error = `Missing required fields for meeting creation: ${missingFields.join(", ")}`;
        console.error("HUBSPOT RESOLVER:", error);
        return { result: "error", message: error };
    }

    // Warn if owner is missing (reduces UI visibility but doesn't prevent creation)
    if (!properties.hubspot_owner_id) {
        console.warn(
            "HUBSPOT RESOLVER: Meeting created without owner - may have reduced UI visibility",
        );
    }

    try {
        // Handle associations if provided - build the associations array using HubSpot's native format
        const associatedContacts = attributes.attributes.get(
            "associated_contacts",
        );
        const associatedCompanies = attributes.attributes.get(
            "associated_companies",
        );
        const associatedDeals = attributes.attributes.get("associated_deals");

        const associations = [];

        // Process contacts associations
        if (associatedContacts) {
            const contactIds =
                typeof associatedContacts === "string"
                    ? associatedContacts.split(",").map((id) => id.trim())
                    : Array.isArray(associatedContacts)
                        ? associatedContacts
                        : [associatedContacts];

            contactIds.forEach((contactId) => {
                associations.push({
                    to: { id: contactId },
                    types: [
                        {
                            associationCategory: "HUBSPOT_DEFINED",
                            associationTypeId:
                                ASSOCIATION_TYPES.MEETING_TO_CONTACT,
                        },
                    ],
                });
            });
        }

        // Process companies associations
        if (associatedCompanies) {
            const companyIds =
                typeof associatedCompanies === "string"
                    ? associatedCompanies.split(",").map((id) => id.trim())
                    : Array.isArray(associatedCompanies)
                        ? associatedCompanies
                        : [associatedCompanies];

            companyIds.forEach((companyId) => {
                associations.push({
                    to: { id: companyId },
                    types: [
                        {
                            associationCategory: "HUBSPOT_DEFINED",
                            associationTypeId:
                                ASSOCIATION_TYPES.MEETING_TO_COMPANY,
                        },
                    ],
                });
            });
        }

        // Process deals associations
        if (associatedDeals) {
            const dealIds =
                typeof associatedDeals === "string"
                    ? associatedDeals.split(",").map((id) => id.trim())
                    : Array.isArray(associatedDeals)
                        ? associatedDeals
                        : [associatedDeals];

            dealIds.forEach((dealId) => {
                associations.push({
                    to: { id: dealId },
                    types: [
                        {
                            associationCategory: "HUBSPOT_DEFINED",
                            associationTypeId:
                                ASSOCIATION_TYPES.MEETING_TO_DEAL,
                        },
                    ],
                });
            });
        }

        // Add associations array to the request if any associations were specified
        if (associations.length > 0) {
            data.associations = associations;
        }

        const result = await makePostRequest("/crm/v3/objects/meetings", data);
        const meetingId = result.id;

        // Verify associations were created
        if (associations.length > 0) {
            try {
                const verifyResult = await makeGetRequest(
                    `/crm/v3/objects/meetings/${meetingId}/associations/contacts`,
                );
            } catch (verifyError) {
                console.error(
                    "HUBSPOT RESOLVER: Failed to verify associations:",
                    verifyError,
                );
            }
        }

        return { result: "success", id: meetingId };
    } catch (error) {
        console.error(`HUBSPOT RESOLVER: Failed to create meeting: ${error}`);
        console.error(`HUBSPOT RESOLVER: Error stack:`, error.stack);
        return { result: "error", message: error.message };
    }
};

export const queryMeeting = async (env, attrs) => {
    return await queryWithFilters("meetings", "Meeting", attrs);
};

export const updateMeeting = async (env, attributes, newAttrs) => {
    const id = attributes.attributes.get("id");
    if (!id) {
        return {
            result: "error",
            message: "Meeting ID is required for update",
        };
    }

    const data = {
        properties: {
            hs_timestamp: newAttrs.get("timestamp"),
            hs_meeting_title: newAttrs.get("meeting_title"),
            hubspot_owner_id: newAttrs.get("owner"),
            hs_meeting_body: newAttrs.get("meeting_body"),
            hs_internal_meeting_notes: newAttrs.get("internal_meeting_notes"),
            hs_meeting_external_url: newAttrs.get("meeting_external_url"),
            hs_meeting_location: newAttrs.get("meeting_location"),
            hs_meeting_start_time: newAttrs.get("meeting_start_time"),
            hs_meeting_end_time: newAttrs.get("meeting_end_time"),
            hs_meeting_outcome: newAttrs.get("meeting_outcome"),
            hs_activity_type: newAttrs.get("activity_type"),
            hs_attachment_ids: newAttrs.get("attachment_ids"),
        },
    };

    try {
        const result = await makePatchRequest(
            `/crm/v3/objects/meetings/${id}`,
            data,
        );
        return asInstance(result, "Meeting");
    } catch (error) {
        console.error(`HUBSPOT RESOLVER: Failed to update meeting: ${error}`);
        return { result: "error", message: error.message };
    }
};

export const deleteMeeting = async (env, attributes) => {
    const id = attributes.attributes.get("id");
    if (!id) {
        return {
            result: "error",
            message: "Meeting ID is required for deletion",
        };
    }

    try {
        await makeDeleteRequest(`/crm/v3/objects/meetings/${id}`);
        return { result: "success" };
    } catch (error) {
        console.error(`HUBSPOT RESOLVER: Failed to delete meeting: ${error}`);
        return { result: "error", message: error.message };
    }
};

async function handleSubsMeetings(resolver) {
    await getAndProcessRecords(resolver, "meetings");
}

export async function subsMeetings(resolver) {
    await handleSubsMeetings(resolver);
    const intervalMinutes =
        parseInt(getLocalEnv("HUBSPOT_POLL_INTERVAL_MINUTES")) || 15;
    const intervalMs = intervalMinutes * 60 * 1000;
    setInterval(async () => {
        await handleSubsMeetings(resolver);
    }, intervalMs);
}

// Exported association management functions
export const associateMeeting = async (env, attributes) => {
    const meetingId = attributes.attributes.get("meeting_id");
    const toObjectType = attributes.attributes.get("to_object_type"); // contacts, companies, or deals
    const toObjectId = attributes.attributes.get("to_object_id");
    const associationTypeId = attributes.attributes.get("association_type_id");

    if (!meetingId || !toObjectType || !toObjectId) {
        return {
            result: "error",
            message:
                "meeting_id, to_object_type, and to_object_id are required for association",
        };
    }

    try {
        await createMeetingAssociation(
            meetingId,
            toObjectType,
            toObjectId,
            associationTypeId,
        );
        return { result: "success" };
    } catch (error) {
        console.error(
            `HUBSPOT RESOLVER: Failed to associate meeting: ${error}`,
        );
        return { result: "error", message: error.message };
    }
};

export const disassociateMeeting = async (env, attributes) => {
    const meetingId = attributes.attributes.get("meeting_id");
    const toObjectType = attributes.attributes.get("to_object_type");
    const toObjectId = attributes.attributes.get("to_object_id");
    const associationTypeId = attributes.attributes.get("association_type_id");

    if (!meetingId || !toObjectType || !toObjectId) {
        return {
            result: "error",
            message:
                "meeting_id, to_object_type, and to_object_id are required for disassociation",
        };
    }

    try {
        await removeMeetingAssociation(
            meetingId,
            toObjectType,
            toObjectId,
            associationTypeId,
        );
        return { result: "success" };
    } catch (error) {
        console.error(
            `HUBSPOT RESOLVER: Failed to disassociate meeting: ${error}`,
        );
        return { result: "error", message: error.message };
    }
};

export const getMeetingAssociationsResolver = async (env, attributes) => {
    const meetingId = attributes.attributes.get("meeting_id");
    const toObjectType = attributes.attributes.get("to_object_type"); // contacts, companies, or deals

    if (!meetingId || !toObjectType) {
        return {
            result: "error",
            message: "meeting_id and to_object_type are required",
        };
    }

    try {
        const associations = await getMeetingAssociations(
            meetingId,
            toObjectType,
        );
        return { result: "success", data: associations };
    } catch (error) {
        console.error(
            `HUBSPOT RESOLVER: Failed to get meeting associations: ${error}`,
        );
        return { result: "error", message: error.message };
    }
};
