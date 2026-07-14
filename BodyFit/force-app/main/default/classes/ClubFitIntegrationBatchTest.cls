@isTest
private class ClubFitIntegrationBatchTest {

    // Callout mock for ClubFit integration batch.
    class ClubFitHttpCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            String endpoint = req.getEndpoint();
            
            // Simulate token endpoint response.
            if (endpoint.contains('/v1/token')) {
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"AccessToken": "dummyToken"}');
                res.setStatusCode(200);
            }
            // Simulate members endpoint response.
            else if (endpoint.contains('/v1/members') && !endpoint.contains('/attendance/visits')) {
                String clubKey = req.getHeader('x-api-key');
                // For Blacktown, return a record with cancellation date and archived status.
                if (clubKey == 'n9pa7h4HEz8YzulNtAxtC7a3aJhidLNA4Jz2HXXs') {
                    String responseBody = '{'
                        + '"href": "https://api.clubfit.net.au/v1/members?fromdate=2025-02-12T00:00:00&limit=500&offset=0&updatedate=2025-02-12T00:00:00",'
                        + '"data": ['
                        + '    {'
                        + '       "Number": "BODY91511",'
                        + '       "FirstName": "Abi",'
                        + '       "LastName": "KANDEL",'
                        + '       "Status": "Archived",'
                        + '       "Barcode": "224547",'
                        + '       "FitnessPassportNumber": null,'
                        + '       "DateOfBirth": "1987-12-11T00:00:00",'
                        + '       "Gender": "M",'
                        + '       "LastUpdatedUtcDateTime": "2025-02-11T22:37:32.01",'
                        + '       "Contact": {'
                        + '           "Email": "abinesh399@live.com",'
                        + '           "Mobile": "0424374753",'
                        + '           "Address": "24 Fourth Avenue",'
                        + '           "Suburb": "Blacktown",'
                        + '           "State": "NSW",'
                        + '           "Postcode": "2148",'
                        + '           "OptOutEmail": false,'
                        + '           "OptOutSms": false'
                        + '       },'
                        + '       "Membership": {'
                        + '           "Id": 2680,'
                        + '           "Name": "Got It In One -  Flexi Membership",'
                        + '           "StartDate": "2025-02-04T00:00:00",'
                        + '           "SaleDate": "2025-02-04T18:36:07.877",'
                        + '           "CancellationDate": "2025-02-11T22:37:31.993",'
                        + '           "MinimumTermDate": "2025-03-04T00:00:00",'
                        + '           "Type": "Direct Debit"'
                        + '       }'
                        + '    }'
                        + ']'
                        + '}';
                    res.setHeader('Content-Type', 'application/json');
                    res.setBody(responseBody);
                    res.setStatusCode(200);
                } else {
                    // Default JSON response for other clubs.
                    String externalId = 'BODY12345-' + clubKey;
                    String responseBody = '{'
                        + '"href": "https://api.clubfit.net.au/v1/members?fromdate=2025-02-12T00:00:00&limit=500&offset=0&updatedate=2025-02-12T00:00:00",'
                        + '"data": ['
                        + '    {'
                        + '       "Number": "' + externalId + '",'
                        + '       "FirstName": "John",'
                        + '       "LastName": "Doe",'
                        + '       "Gender": "M",'
                        + '       "Status": "Active",'
                        + '       "Barcode": "123456789",'
                        + '       "FitnessPassportNumber": "987654321",'
                        + '       "DateOfBirth": "1990-01-01T00:00:00",'
                        + '       "Contact": {'
                        + '           "Email": "john.doe@example.com",'
                        + '           "Mobile": "0412345678",'
                        + '           "Address": "123 Main St",'
                        + '           "Suburb": "Sydney",'
                        + '           "State": "NSW",'
                        + '           "Postcode": "2000",'
                        + '           "OptOutEmail": false,'
                        + '           "OptOutSms": false'
                        + '       },'
                        + '       "Membership": {'
                        + '           "Id": 123,'
                        + '           "Name": "Standard Membership",'
                        + '           "StartDate": "2025-01-01T00:00:00",'
                        + '           "ExpiryDate": "2026-01-01T00:00:00",'
                        + '           "SaleDate": "2025-01-01T12:00:00",'
                        + '           "Type": "Standard"'
                        + '       }'
                        + '    }'
                        + ']'
                        + '}';
                    res.setHeader('Content-Type', 'application/json');
                    res.setBody(responseBody);
                    res.setStatusCode(200);
                }
            }
            else {
                res.setStatusCode(404);
                res.setBody('{"error": "Not found"}');
            }
            return res;
        }
    }
    
    @isTest
    static void testIntegrationBatchUsingExecuteBatch() {
        // Clean up any preexisting Account records created by the integration.
        delete [SELECT Id FROM Account WHERE Clubfit_Member_Id__c != null];

        // Set the HTTP callout mock.
        Test.setMock(HttpCalloutMock.class, new ClubFitHttpCalloutMock());
        
        Test.startTest();
            // Execute the integration batch (batch size set to 1 for testing).
            Database.executeBatch(new ClubFitIntegrationBatch(), 1);
        Test.stopTest();
        
        // Query the upserted Account records.
        List<Account> accounts = [
            SELECT Clubfit_Member_Id__c, FirstName, LastName, Gender__c, Status__pc, Barcode__c, 
                   Fitness_Passport_Number__pc, PersonBirthdate, BillingStreet, BillingCity, BillingState, BillingPostalCode, 
                   AssociatedClub__c, Cancellation_Date__c, Sale_Date__c, Membership_Type__pc
            FROM Account 
            WHERE Clubfit_Member_Id__c LIKE 'BODY%'
        ];
        // The integration batch processes 8 clubs so we expect 8 Account records.
        System.assertEquals(8, accounts.size(), 'Eight Account records should have been upserted by the integration batch.');
        
        // Verify the records. In particular, check the special record (for Blacktown) for cancellation and the blended address.
        for (Account acc : accounts) {
            if (acc.Clubfit_Member_Id__c == 'BODY91511') {
                // This record should come from the special Blacktown response.
                System.assertEquals('Abi', acc.FirstName, 'FirstName should be Abi');
                System.assertEquals('KANDEL', acc.LastName, 'LastName should be KANDEL');
                System.assertEquals('Archived', acc.Status__pc, 'Status should be overridden to Archived');
                System.assertEquals(Date.newInstance(2025, 2, 11), acc.Cancellation_Date__c, 'Cancellation_Date__c should be 2025-02-11');
                // Blend the individual address fields for comparison.
                String blendedAddress = acc.BillingStreet + ', ' + acc.BillingCity + ', ' + acc.BillingState + ' ' + acc.BillingPostalCode;
                System.assertEquals('24 Fourth Avenue, Blacktown, NSW 2148', blendedAddress, 'BillingAddress should be a blend of the individual address fields');
            } else {
                // For all other clubs, default record values are used.
                System.assertEquals('John', acc.FirstName, 'Default FirstName should be John');
                System.assertEquals('Doe', acc.LastName, 'Default LastName should be Doe');
                System.assertEquals('Active', acc.Status__pc, 'Default Status should be Active');
                System.assertEquals(null, acc.get('Cancellation_Date__c'), 'Cancellation_Date__c should be null for default records');
            }
        }
    }
}