@isTest
private class ClubFitServiceAndBatchTest {

    // A callout mock that simulates responses for the token, members, and visits endpoints.
    class ClubFitHttpCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            String endpoint = req.getEndpoint();
            
            // Simulate token endpoint response. Note: use key "AccessToken" as expected by getAccessToken().
            if (endpoint.contains('/v1/token')) {
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"AccessToken": "dummyToken"}');
                res.setStatusCode(200);
            }
            // Simulate members endpoint response (for getMembersJSON).
            else if (endpoint.contains('/v1/members') && !endpoint.contains('/attendance/visits')) {
                String clubKey = req.getHeader('x-api-key');
                if (clubKey == null) {
                    clubKey = 'unknown';
                }
                String externalId = 'BODY12345-' + clubKey;
                String responseBody = '{'
                    + '"href": "https://api.clubfit.net.au/v1/members?fromdate=2025-02-12T00:00:00&limit=500&offset=0&status=Active&updatedate=2025-02-12T00:00:00",'
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
                    + '           "ExpiryDate": "2026-01-01T00:00:00"'
                    + '       }'
                    + '    }'
                    + ']'
                    + '}';
                res.setHeader('Content-Type', 'application/json');
                res.setBody(responseBody);
                res.setStatusCode(200);
            }
            // Simulate visits endpoint response (for getVisitsJSON).
            else if (endpoint.contains('/v1/members/attendance/visits')) {
                // For simplicity, we return a single visit record.
                // In your real batch, this JSON would likely contain different data per club.
                String responseBody = '{'
                    + '"data": ['
                    + '    {'
                    + '       "MemberNumber": "TESTVISIT-123",'
                    + '       "Door": "Test Door",'
                    + '       "ScanSource": "TestScan",'
                    + '       "VisitDateTime": "2025-02-12T12:00:00Z"'
                    + '    }'
                    + ']'
                    + '}';
                res.setHeader('Content-Type', 'application/json');
                res.setBody(responseBody);
                res.setStatusCode(200);
            }
            else {
                res.setStatusCode(404);
                res.setBody('{"error": "Not found"}');
            }
            return res;
        }
    }
    
    // -------------------------------
    // Tests for ClubFitService Methods
    // -------------------------------
    
    @isTest
    static void testGetAccessToken() {
        Test.setMock(HttpCalloutMock.class, new ClubFitHttpCalloutMock());
        String token = ClubFitService.getAccessToken();
        System.assertEquals('dummyToken', token, 'Access token should be dummyToken');
    }
    
    @isTest
    static void testGetMembersJSON() {
        Test.setMock(HttpCalloutMock.class, new ClubFitHttpCalloutMock());
        String fromDate = '2025-02-12T00:00:00';
        String updateDate = '2025-02-12T00:00:00';
        String jsonResponse = ClubFitService.getMembersJSON(fromDate, updateDate, 'TestKey');
        System.assertNotEquals(null, jsonResponse, 'Members JSON response should not be null');
        
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        List<Object> dataList = (List<Object>) result.get('data');
        System.assertEquals(1, dataList.size(), 'There should be one member record');
        
        Map<String, Object> memberRec = (Map<String, Object>) dataList[0];
        System.assertEquals('BODY12345-TestKey', memberRec.get('Number'),
            'The member external id should match');
    }
    
    @isTest
    static void testGetVisitsJSON() {
        Test.setMock(HttpCalloutMock.class, new ClubFitHttpCalloutMock());
        String fromDate = '2025-02-12T00:00:00';
        String jsonResponse = ClubFitService.getVisitsJSON(fromDate, 'TestKey', 0);
        System.assertNotEquals(null, jsonResponse, 'Visits JSON response should not be null');
        
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        List<Object> dataList = (List<Object>) result.get('data');
        System.assertEquals(1, dataList.size(), 'There should be one visitation record');
        
        Map<String, Object> visitRec = (Map<String, Object>) dataList[0];
        System.assertEquals('TESTVISIT-123', visitRec.get('MemberNumber'), 'MemberNumber should match');
        System.assertEquals('Test Door', visitRec.get('Door'), 'Door should match');
        System.assertEquals('TestScan', visitRec.get('ScanSource'), 'ScanSource should match');
        System.assertEquals('2025-02-12T12:00:00Z', visitRec.get('VisitDateTime'),
            'VisitDateTime should match');
    }
    
    // -------------------------------
    // Tests for ClubFitVisitsBatch
    // -------------------------------
    
    @isTest
    static void testBatchUsingExecuteBatch() {
        // Clear any existing Visitation__c records.
        delete [SELECT Id FROM Visitation__c];
        
        Test.setMock(HttpCalloutMock.class, new ClubFitHttpCalloutMock());
        Test.startTest();
            // Execute the batch with a batch size of 1.
            Database.executeBatch(new ClubFitVisitsBatch(), 1);
        Test.stopTest();
        
        // Since our club map in the batch has 8 clubs, we expect 8 visitation records.
        List<Visitation__c> visits = [SELECT Member_ID__c, Door__c, Scan_Source__c, Date_Time__c 
                                      FROM Visitation__c];
        System.assertEquals(8, visits.size(), 'Eight visitation records should be inserted via executeBatch');
        
        // Verify that each record has the expected values.
        for (Visitation__c v : visits) {
            System.assertEquals('TESTVISIT-123', v.Member_ID__c, 'Member_ID__c should match the mock response');
            System.assertEquals('Test Door', v.Door__c, 'Door should match');
            System.assertEquals('TestScan', v.Scan_Source__c, 'Scan_Source__c should match');
            DateTime expectedDt = DateTime.valueOf('2025-02-12 12:00:00');
            System.assertEquals(expectedDt, v.Date_Time__c, 'Date_Time__c should match');
        }
    }
    
    @isTest
    static void testBatchExecuteDirectly() {
        // Clear any existing records.
        delete [SELECT Id FROM Visitation__c];
        
        Test.setMock(HttpCalloutMock.class, new ClubFitHttpCalloutMock());
        ClubFitVisitsBatch batch = new ClubFitVisitsBatch();
        batch.execute(null, new List<String>{ 'start' });
        
        List<Visitation__c> visits = [SELECT Member_ID__c, Door__c, Scan_Source__c, Date_Time__c 
                                      FROM Visitation__c];
        System.assertEquals(8, visits.size(), 'Eight visitation records should be inserted via direct execute call.');
    }
}