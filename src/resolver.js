// HubSpot Studio Resolver - Browser-compatible with Skypack CDN dependencies
import axios from 'https://cdn.skypack.dev/axios';
import { asInstance } from 'https://cdn.skypack.dev/agentlang';

// Browser Configuration Management
const BrowserConfig = {
    store: {},
    init: function () {
        if (typeof localStorage !== 'undefined') {
            const config = localStorage.getItem('hubspotConfig');
            if (config) {
                this.store = JSON.parse(config);
            }
        }
    },
    get: function (key) {
        if (Object.keys(this.store).length === 0) {
            this.init();
        }
        return this.store[key];
    },
    set: function (key, value) {
        this.store[key] = value;
        if (typeof localStorage !== 'undefined') {
            localStorage.setItem('hubspotConfig', JSON.stringify(this.store));
        }
    }
};

// Configuration helpers
const getAccessToken = () => BrowserConfig.get('accessToken');
const getBaseUrl = () => BrowserConfig.get('baseUrl') || 'https://api.hubapi.com';
const getPollInterval = () => parseInt(BrowserConfig.get('pollIntervalMinutes')) || 15;

// HTTP Request Wrapper
const makeRequest = async (endpoint, options = {}) => {
    const token = getAccessToken();
    if (!token) {
        return { result: 'error', message: 'HubSpot access token not configured' };
    }

    const baseUrl = getBaseUrl();
    const url = `${baseUrl}${endpoint}`;

    const config = {
        ...options,
        url,
        headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
            ...(options.headers || {})
        },
        timeout: options.timeout || 30000
    };

    try {
        const response = await axios(config);
        return response.data;
    } catch (error) {
        if (error.response) {
            return {
                result: 'error',
                message: error.response.data?.message || `HTTP error! status: ${error.response.status}`
            };
        } else if (error.request) {
            return {
                result: 'error',
                message: 'No response received from HubSpot API'
            };
        } else {
            return {
                result: 'error',
                message: error.message
            };
        }
    }
};

// HTTP helpers
const makeGetRequest = (endpoint) => makeRequest(endpoint, { method: 'GET' });
const makePostRequest = (endpoint, body) => makeRequest(endpoint, { method: 'POST', data: body });
const makePatchRequest = (endpoint, body) => makeRequest(endpoint, { method: 'PATCH', data: body });
const makeDeleteRequest = (endpoint) => makeRequest(endpoint, { method: 'DELETE' });

// ============================================================================
// CONTACT ENTITY OPERATIONS
// ============================================================================

// Property mapper for Contact
const toContactProperties = (attrs) => {
    const props = {};
    if (attrs.get('first_name')) props.firstname = attrs.get('first_name');
    if (attrs.get('last_name')) props.lastname = attrs.get('last_name');
    if (attrs.get('email')) props.email = attrs.get('email');
    if (attrs.get('job_title')) props.jobtitle = attrs.get('job_title');
    if (attrs.get('lead_status')) props.hs_lead_status = attrs.get('lead_status');
    if (attrs.get('lifecycle_stage')) props.lifecyclestage = attrs.get('lifecycle_stage');
    if (attrs.get('mobile_phone_number')) props.mobilephone = attrs.get('mobile_phone_number');
    if (attrs.get('website_url')) props.website = attrs.get('website_url');
    if (attrs.get('owner')) props.hubspot_owner_id = attrs.get('owner');
    return props;
};

const toContact = (contact) => ({
    id: contact.id?.toString(),
    created_date: contact.createdAt,
    first_name: contact.properties?.firstname || '',
    last_name: contact.properties?.lastname || '',
    email: contact.properties?.email || '',
    job_title: contact.properties?.jobtitle || '',
    last_contacted: contact.properties?.notes_last_contacted || '',
    last_activity_date: contact.properties?.notes_last_updated || '',
    lead_status: contact.properties?.hs_lead_status || '',
    lifecycle_stage: contact.properties?.lifecyclestage || '',
    salutation: contact.properties?.salutation || '',
    mobile_phone_number: contact.properties?.mobilephone || '',
    website_url: contact.properties?.website || '',
    owner: contact.properties?.hubspot_owner_id || '',
    properties: contact.properties || {},
    createdAt: contact.createdAt,
    updatedAt: contact.updatedAt,
    archived: contact.archived || false
});

export async function createContact(env, attributes) {
    const attrs = attributes.attributes;
    const properties = toContactProperties(attrs);

    const result = await makePostRequest('/crm/v3/objects/contacts', { properties });

    if (result.result === 'error') {
        return result;
    }

    return asInstance(toContact(result), 'hubspot/Contact');
}

export async function queryContact(env, attrs) {
    const path = attrs.queryAttributeValues?.get('__path__');

    if (path) {
        const id = path.split('/').slice(-1)[0];
        const result = await makeGetRequest(`/crm/v3/objects/contacts/${id}`);

        if (result.result === 'error') {
            return [result];
        }

        return [asInstance(toContact(result), 'hubspot/Contact')];
    }

    const result = await makeGetRequest('/crm/v3/objects/contacts');

    if (result.result === 'error') {
        return [result];
    }

    return result.results?.map(contact => asInstance(toContact(contact), 'hubspot/Contact')) || [];
}

export async function updateContact(env, attributes, newAttrs) {
    const id = attributes.attributes.get('id');

    if (!id) {
        return { result: 'error', message: 'Contact ID is required for update' };
    }

    const properties = toContactProperties(newAttrs);
    const result = await makePatchRequest(`/crm/v3/objects/contacts/${id}`, { properties });

    if (result.result === 'error') {
        return result;
    }

    return asInstance(toContact(result), 'hubspot/Contact');
}

export async function deleteContact(env, attributes) {
    const id = attributes.attributes.get('id');

    if (!id) {
        return { result: 'error', message: 'Contact ID is required for delete' };
    }

    const result = await makeDeleteRequest(`/crm/v3/objects/contacts/${id}`);

    if (result.result === 'error') {
        return result;
    }

    return { result: 'success', message: 'Contact deleted successfully' };
}

// ============================================================================
// COMPANY ENTITY OPERATIONS
// ============================================================================

const toCompanyProperties = (attrs) => {
    const props = {};
    if (attrs.get('name')) props.name = attrs.get('name');
    if (attrs.get('description')) props.description = attrs.get('description');
    if (attrs.get('industry')) props.industry = attrs.get('industry');
    if (attrs.get('country')) props.country = attrs.get('country');
    if (attrs.get('city')) props.city = attrs.get('city');
    if (attrs.get('year_founded')) props.founded_year = attrs.get('year_founded');
    if (attrs.get('website_url')) props.website = attrs.get('website_url');
    if (attrs.get('owner')) props.hubspot_owner_id = attrs.get('owner');
    return props;
};

const toCompany = (company) => ({
    id: company.id?.toString(),
    name: company.properties?.name || '',
    description: company.properties?.description || '',
    industry: company.properties?.industry || '',
    country: company.properties?.country || '',
    city: company.properties?.city || '',
    year_founded: company.properties?.founded_year || '',
    website_url: company.properties?.website || '',
    owner: company.properties?.hubspot_owner_id || '',
    properties: company.properties || {},
    createdAt: company.createdAt,
    updatedAt: company.updatedAt,
    archived: company.archived || false
});

export async function createCompany(env, attributes) {
    const attrs = attributes.attributes;
    const properties = toCompanyProperties(attrs);

    const result = await makePostRequest('/crm/v3/objects/companies', { properties });

    if (result.result === 'error') {
        return result;
    }

    return asInstance(toCompany(result), 'hubspot/Company');
}

export async function queryCompany(env, attrs) {
    const path = attrs.queryAttributeValues?.get('__path__');

    if (path) {
        const id = path.split('/').slice(-1)[0];
        const result = await makeGetRequest(`/crm/v3/objects/companies/${id}`);

        if (result.result === 'error') {
            return [result];
        }

        return [asInstance(toCompany(result), 'hubspot/Company')];
    }

    const result = await makeGetRequest('/crm/v3/objects/companies');

    if (result.result === 'error') {
        return [result];
    }

    return result.results?.map(company => asInstance(toCompany(company), 'hubspot/Company')) || [];
}

export async function updateCompany(env, attributes, newAttrs) {
    const id = attributes.attributes.get('id');

    if (!id) {
        return { result: 'error', message: 'Company ID is required for update' };
    }

    const properties = toCompanyProperties(newAttrs);
    const result = await makePatchRequest(`/crm/v3/objects/companies/${id}`, { properties });

    if (result.result === 'error') {
        return result;
    }

    return asInstance(toCompany(result), 'hubspot/Company');
}

export async function deleteCompany(env, attributes) {
    const id = attributes.attributes.get('id');

    if (!id) {
        return { result: 'error', message: 'Company ID is required for delete' };
    }

    const result = await makeDeleteRequest(`/crm/v3/objects/companies/${id}`);

    if (result.result === 'error') {
        return result;
    }

    return { result: 'success', message: 'Company deleted successfully' };
}

// ============================================================================
// DEAL ENTITY OPERATIONS
// ============================================================================

const toDealProperties = (attrs) => {
    const props = {};
    if (attrs.get('deal_name')) props.dealname = attrs.get('deal_name');
    if (attrs.get('deal_stage')) props.dealstage = attrs.get('deal_stage');
    if (attrs.get('amount')) props.amount = attrs.get('amount');
    if (attrs.get('close_date')) props.closedate = attrs.get('close_date');
    if (attrs.get('deal_type')) props.dealtype = attrs.get('deal_type');
    if (attrs.get('pipeline')) props.pipeline = attrs.get('pipeline');
    if (attrs.get('priority')) props.priority = attrs.get('priority');
    if (attrs.get('owner')) props.hubspot_owner_id = attrs.get('owner');
    return props;
};

const toDeal = (deal) => ({
    id: deal.id?.toString(),
    deal_name: deal.properties?.dealname || '',
    deal_stage: deal.properties?.dealstage || '',
    amount: deal.properties?.amount || '',
    close_date: deal.properties?.closedate || '',
    deal_type: deal.properties?.dealtype || '',
    pipeline: deal.properties?.pipeline || '',
    priority: deal.properties?.priority || '',
    owner: deal.properties?.hubspot_owner_id || '',
    properties: deal.properties || {},
    createdAt: deal.createdAt,
    updatedAt: deal.updatedAt,
    archived: deal.archived || false
});

export async function createDeal(env, attributes) {
    const attrs = attributes.attributes;
    const properties = toDealProperties(attrs);

    const result = await makePostRequest('/crm/v3/objects/deals', { properties });

    if (result.result === 'error') {
        return result;
    }

    return asInstance(toDeal(result), 'hubspot/Deal');
}

export async function queryDeal(env, attrs) {
    const path = attrs.queryAttributeValues?.get('__path__');

    if (path) {
        const id = path.split('/').slice(-1)[0];
        const result = await makeGetRequest(`/crm/v3/objects/deals/${id}`);

        if (result.result === 'error') {
            return [result];
        }

        return [asInstance(toDeal(result), 'hubspot/Deal')];
    }

    const result = await makeGetRequest('/crm/v3/objects/deals');

    if (result.result === 'error') {
        return [result];
    }

    return result.results?.map(deal => asInstance(toDeal(deal), 'hubspot/Deal')) || [];
}

export async function updateDeal(env, attributes, newAttrs) {
    const id = attributes.attributes.get('id');

    if (!id) {
        return { result: 'error', message: 'Deal ID is required for update' };
    }

    const properties = toDealProperties(newAttrs);
    const result = await makePatchRequest(`/crm/v3/objects/deals/${id}`, { properties });

    if (result.result === 'error') {
        return result;
    }

    return asInstance(toDeal(result), 'hubspot/Deal');
}

export async function deleteDeal(env, attributes) {
    const id = attributes.attributes.get('id');

    if (!id) {
        return { result: 'error', message: 'Deal ID is required for delete' };
    }

    const result = await makeDeleteRequest(`/crm/v3/objects/deals/${id}`);

    if (result.result === 'error') {
        return result;
    }

    return { result: 'success', message: 'Deal deleted successfully' };
}

// ============================================================================
// OWNER ENTITY OPERATIONS
// ============================================================================

const toOwner = (owner) => ({
    id: owner.id?.toString(),
    email: owner.email || '',
    first_name: owner.firstName || '',
    last_name: owner.lastName || '',
    user_id: owner.userId?.toString() || '',
    created_at: owner.createdAt,
    updated_at: owner.updatedAt,
    archived: owner.archived || false
});

export async function queryOwner(env, attrs) {
    const path = attrs.queryAttributeValues?.get('__path__');

    if (path) {
        const id = path.split('/').slice(-1)[0];
        const result = await makeGetRequest(`/crm/v3/owners/${id}`);

        if (result.result === 'error') {
            return [result];
        }

        return [asInstance(toOwner(result), 'hubspot/Owner')];
    }

    const result = await makeGetRequest('/crm/v3/owners');

    if (result.result === 'error') {
        return [result];
    }

    return result.results?.map(owner => asInstance(toOwner(owner), 'hubspot/Owner')) || [];
}

// ============================================================================
// TASK ENTITY OPERATIONS
// ============================================================================

const toTaskProperties = (attrs) => {
    const props = {};
    if (attrs.get('task_type')) props.hs_task_type = attrs.get('task_type');
    if (attrs.get('title')) props.hs_task_subject = attrs.get('title');
    if (attrs.get('priority')) props.hs_task_priority = attrs.get('priority');
    if (attrs.get('assigned_to')) props.hs_task_assigned_to = attrs.get('assigned_to');
    if (attrs.get('due_date')) props.hs_task_due_date = attrs.get('due_date');
    if (attrs.get('status')) props.hs_task_status = attrs.get('status');
    if (attrs.get('description')) props.hs_task_body = attrs.get('description');
    if (attrs.get('owner')) props.hubspot_owner_id = attrs.get('owner');
    return props;
};

const toTask = (task) => ({
    id: task.id?.toString(),
    task_type: task.properties?.hs_task_type || '',
    title: task.properties?.hs_task_subject || '',
    priority: task.properties?.hs_task_priority || '',
    assigned_to: task.properties?.hs_task_assigned_to || '',
    due_date: task.properties?.hs_task_due_date || '',
    status: task.properties?.hs_task_status || '',
    description: task.properties?.hs_task_body || '',
    owner: task.properties?.hubspot_owner_id || '',
    properties: task.properties || {},
    createdAt: task.createdAt,
    updatedAt: task.updatedAt,
    archived: task.archived || false
});

export async function createTask(env, attributes) {
    const attrs = attributes.attributes;
    const properties = toTaskProperties(attrs);

    const result = await makePostRequest('/crm/v3/objects/tasks', { properties });

    if (result.result === 'error') {
        return result;
    }

    return asInstance(toTask(result), 'hubspot/Task');
}

export async function queryTask(env, attrs) {
    const path = attrs.queryAttributeValues?.get('__path__');

    if (path) {
        const id = path.split('/').slice(-1)[0];
        const result = await makeGetRequest(`/crm/v3/objects/tasks/${id}`);

        if (result.result === 'error') {
            return [result];
        }

        return [asInstance(toTask(result), 'hubspot/Task')];
    }

    const result = await makeGetRequest('/crm/v3/objects/tasks');

    if (result.result === 'error') {
        return [result];
    }

    return result.results?.map(task => asInstance(toTask(task), 'hubspot/Task')) || [];
}

export async function updateTask(env, attributes, newAttrs) {
    const id = attributes.attributes.get('id');

    if (!id) {
        return { result: 'error', message: 'Task ID is required for update' };
    }

    const properties = toTaskProperties(newAttrs);
    const result = await makePatchRequest(`/crm/v3/objects/tasks/${id}`, { properties });

    if (result.result === 'error') {
        return result;
    }

    return asInstance(toTask(result), 'hubspot/Task');
}

export async function deleteTask(env, attributes) {
    const id = attributes.attributes.get('id');

    if (!id) {
        return { result: 'error', message: 'Task ID is required for delete' };
    }

    const result = await makeDeleteRequest(`/crm/v3/objects/tasks/${id}`);

    if (result.result === 'error') {
        return result;
    }

    return { result: 'success', message: 'Task deleted successfully' };
}

// ============================================================================
// SUBSCRIPTION/POLLING MECHANISMS
// ============================================================================

let contactIntervalId = null;
let companyIntervalId = null;
let dealIntervalId = null;
let ownerIntervalId = null;
let taskIntervalId = null;

async function handleSubsContacts(resolver) {
    const result = await makeGetRequest('/crm/v3/objects/contacts');

    if (result.result === 'error') {
        console.error('Error fetching contacts:', result.message);
        return;
    }

    const instances = result.results?.map(contact => asInstance(toContact(contact), 'hubspot/Contact')) || [];
    await resolver.onSubscription(instances, true);
}

export async function subsContacts(resolver) {
    await handleSubsContacts(resolver);

    const intervalMs = getPollInterval() * 60 * 1000;

    if (contactIntervalId) {
        clearInterval(contactIntervalId);
    }

    contactIntervalId = setInterval(async () => {
        await handleSubsContacts(resolver);
    }, intervalMs);
}

async function handleSubsCompanies(resolver) {
    const result = await makeGetRequest('/crm/v3/objects/companies');

    if (result.result === 'error') {
        console.error('Error fetching companies:', result.message);
        return;
    }

    const instances = result.results?.map(company => asInstance(toCompany(company), 'hubspot/Company')) || [];
    await resolver.onSubscription(instances, true);
}

export async function subsCompanies(resolver) {
    await handleSubsCompanies(resolver);

    const intervalMs = getPollInterval() * 60 * 1000;

    if (companyIntervalId) {
        clearInterval(companyIntervalId);
    }

    companyIntervalId = setInterval(async () => {
        await handleSubsCompanies(resolver);
    }, intervalMs);
}

async function handleSubsDeals(resolver) {
    const result = await makeGetRequest('/crm/v3/objects/deals');

    if (result.result === 'error') {
        console.error('Error fetching deals:', result.message);
        return;
    }

    const instances = result.results?.map(deal => asInstance(toDeal(deal), 'hubspot/Deal')) || [];
    await resolver.onSubscription(instances, true);
}

export async function subsDeals(resolver) {
    await handleSubsDeals(resolver);

    const intervalMs = getPollInterval() * 60 * 1000;

    if (dealIntervalId) {
        clearInterval(dealIntervalId);
    }

    dealIntervalId = setInterval(async () => {
        await handleSubsDeals(resolver);
    }, intervalMs);
}

async function handleSubsOwners(resolver) {
    const result = await makeGetRequest('/crm/v3/owners');

    if (result.result === 'error') {
        console.error('Error fetching owners:', result.message);
        return;
    }

    const instances = result.results?.map(owner => asInstance(toOwner(owner), 'hubspot/Owner')) || [];
    await resolver.onSubscription(instances, true);
}

export async function subsOwners(resolver) {
    await handleSubsOwners(resolver);

    const intervalMs = getPollInterval() * 60 * 1000;

    if (ownerIntervalId) {
        clearInterval(ownerIntervalId);
    }

    ownerIntervalId = setInterval(async () => {
        await handleSubsOwners(resolver);
    }, intervalMs);
}

async function handleSubsTasks(resolver) {
    const result = await makeGetRequest('/crm/v3/objects/tasks');

    if (result.result === 'error') {
        console.error('Error fetching tasks:', result.message);
        return;
    }

    const instances = result.results?.map(task => asInstance(toTask(task), 'hubspot/Task')) || [];
    await resolver.onSubscription(instances, true);
}

export async function subsTasks(resolver) {
    await handleSubsTasks(resolver);

    const intervalMs = getPollInterval() * 60 * 1000;

    if (taskIntervalId) {
        clearInterval(taskIntervalId);
    }

    taskIntervalId = setInterval(async () => {
        await handleSubsTasks(resolver);
    }, intervalMs);
}

// ============================================================================
// CONFIGURATION INITIALIZATION
// ============================================================================

export function initializeHubSpotConfig(config) {
    if (config && typeof config === 'object') {
        Object.entries(config).forEach(([key, value]) => {
            BrowserConfig.set(key, value);
        });
    }
}

// Export configuration object for external access
export const config = BrowserConfig;
