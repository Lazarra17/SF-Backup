# Service Availability API

## Overview

The Service Availability API provides external consumers with the ability to retrieve service availability information for a property using a Unique Property Reference Number (UPRN).

The API exposes two versioned REST endpoints:

- **v1** - Returns basic service availability information.
- **v2** - Returns extended service availability information.

The solution is implemented using Apex REST services and follows object-oriented design principles to maximise code reuse, maintainability, and scalability.

---

# Design Decisions

## API Versioning

The API is versioned through the endpoint URL.

Version-specific endpoints allow enhancements to be introduced without breaking existing consumers.

### Endpoints

```text
/services/apexrest/availability/v1
/services/apexrest/availability/v2
```

---

## Service Layer

A service layer has been implemented to encapsulate business logic and separate it from the REST controllers.

Responsibilities:

- Validate incoming requests
- Retrieve account information
- Apply business rules
- Construct response DTOs

Benefits:

- Separation of concerns
- Improved maintainability
- Easier unit testing

---

## Abstract Base Class

A common abstract class is used to centralise shared functionality between API versions.

Shared functionality includes:

- UPRN validation
- Account retrieval
- Common processing logic
- Error handling

Version specific classes inherit from the abstract class and implement only their required response mapping logic.

Benefits:

- Reduces code duplication
- Improves consistency
- Simplifies future enhancements

Architecture:

```text
AvailabilityServiceBase (Abstract)
            │
    ┌───────┴────────┐
    │                │
AvailabilityV1   AvailabilityV2
```

---

## Repository Pattern

All SOQL queries are centralised within a dedicated repository class.

Responsibilities:

- Query Account records
- Isolate database access from business logic
- Provide reusable data access methods

Benefits:

- Single source of truth for queries
- Easier maintenance
- Better testability

Architecture:

```text
REST Resource
      ↓
Service Layer
      ↓
AvailabilityRepository
      ↓
Salesforce Database
```

---

## DTO Pattern

Dedicated response wrapper classes are used for API responses.

Benefits:

- Prevents exposing Salesforce objects directly
- Provides a clear API contract
- Improves maintainability
- Allows future response changes without impacting the underlying data model

---

# API Endpoints

## Version 1

### Request

```http
GET /services/apexrest/availability/v1?UPRN={number}
```

### Example

```http
GET /services/apexrest/availability/v1?UPRN=101
```

### Success Response

```json
{
  "UPRNExists": true,
  "ReadyForSale": true
}
```

### Response Fields

| Field        | Type    | Description |
|---------     |---------|---------|
| UPRNExists   | Boolean | Indicates whether a matching UPRN exists |
| ReadyForSale | Boolean | Indicates whether the property is ready for sale |

---

## Version 2

### Request

```http
GET /services/apexrest/availability/v2?UPRN={number}
```

### Example

```http
GET /services/apexrest/availability/v2?UPRN=101
```

### Success Response

```json
{
  "UPRNExists": true,
  "ReadyForSale": true,
  "ClientJourney": 5,
  "AvailableForPreOrder": false
}
```

### Response Fields

| Field                | Type    | Description |
|---------             |---------|---------|
| UPRNExists           | Boolean | Indicates whether a matching UPRN exists |
| ReadyForSale         | Boolean | Indicates whether the property is ready for sale |
| ClientJourney        | Integer | Current client journey stage |
| AvailableForPreOrder | Boolean | Indicates whether the property can be pre-ordered |

---

# HTTP Response Codes

| Status Code | Description |
|------------ |-------------|
| 200         | Success, a response message will be returned for all records in the originating call. |
| 400         | 400 - Client error, review the message to determine the error. This is most likely to be a poorly
formatted request. |
| 403         | Forbidden.  |
| 404         | Client error, the given UPRN could no be found. |
| 501         | Authentication Error. Check that you are using a valid authorised token and that the token
hasn’t expired. |
| 503         | Server error, indicates the server is busy, overloaded, or down for maintenance. The request
will have to be retried at a later time. |

---

# Error Response Format

All error responses follow a common structure:

```json
{
  "statusCode": 400,
  "message": "Descriptive error message"
}
```

---

## 400 Bad Request

```json
{
  "statusCode": 400,
  "message": "UPRN parameter is required."
}
```

---

## 403 Forbidden

```json
{
  "statusCode": 403,
  "message": "Forbidden."
}
```

---

## 404 Not Found

```json
{
  "statusCode": 404,
  "message": "Client error, the given UPRN could no be found. "
}
```

---

## 501 Authentication Error

```json
{
  "statusCode": 501,
  "message": "Authentication Error. Check that you are using a valid authorised token and that the token
hasn’t expired."
}
```

---

## 503 Service Unavailable

```json
{
  "statusCode": 503,
  "message": "Server error, indicates the server is busy, overloaded, or down for maintenance. The request
will have to be retried at a later time."
}
```

---

# Authentication

The API is intended to be consumed by external systems, including other Salesforce organisations.

Authentication is performed using Salesforce OAuth 2.0.

Recommended integration pattern:

```text
Consumer Org
    ↓
Named Credential
    ↓
OAuth 2.0
    ↓
Connected App
    ↓
Availability API
```

Access to the API is controlled through:

- Salesforce Authentication
- Connected App Configuration
- Apex Class Access
- Object-Level Security
- Field-Level Security

# OAuth Configuration
Client ID - 

Client Secret - 

---

# Assumptions

The following assumptions were made during implementation.

## Account Fields

The Account object contains the following custom fields:

```text
UPRN__c
Ready_For_Sale__c
Client_Journey__c
Available_For_Pre_Order__c
```

---

## UPRN

- UPRN is unique for each property.
- UPRN is stored on the Account object.
- UPRN is used as the primary lookup identifier.

---

## API Responses

- A successful lookup returns HTTP 200.
- Missing or invalid parameters return HTTP 400.
- Unknown UPRNs return HTTP 404.
- Authentication failures return HTTP 501 as specified in the requirements.
- Permission-related failures return HTTP 403.

---

## Security

The solution assumes consumers are authenticated prior to accessing the API.

Users accessing the API must have:

- API Enabled permission
- Access to the REST Apex classes
- Read access to required Account fields
- Appropriate object permissions

---

# Testing

The APIs were tested using:

- Developer Console (Anonymous Apex)
- Salesforce Named Credentials
- Apex Unit Tests
- Direct browser/API requests/Workbench

Sample Apex callout:

```apex
HttpRequest req = new HttpRequest();

req.setEndpoint(
    'callout:AvailabilityNamedCreds/services/apexrest/availability/v2?UPRN=101'
);

req.setMethod('GET');

HttpResponse res = new Http().send(req);

System.debug(res.getStatusCode());
System.debug(res.getBody());
```


# Summary

The Service Availability API was designed using Salesforce and object-oriented best practices. Shared functionality was centralised through an abstract service layer, while database access was isolated using the Repository Pattern. This approach minimises code duplication, promotes maintainability, and provides a scalable foundation for future API versions.