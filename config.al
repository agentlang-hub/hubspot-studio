{
    "service": {
        "port": "#js parseInt(getLocalEnv('PORT', '8080'))"
    },
    "store": {
        "type": "sqlite",
        "dbname": "hubspot.db"
    },
    "hubspot/HubSpotConfig": {
        "accessToken": "#js getLocalEnv('HUBSPOT_ACCESS_TOKEN', '')",
        "pollIntervalMinutes": "#js parseInt(getLocalEnv('HUBSPOT_POLL_INTERVAL_MINUTES', '2'))",
        "searchResultLimit": "#js parseInt(getLocalEnv('HUBSPOT_SEARCH_RESULT_LIMIT', '100'))",
        "active": true
    }
}
