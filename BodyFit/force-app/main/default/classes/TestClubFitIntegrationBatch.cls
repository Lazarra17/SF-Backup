@isTest
private class TestClubFitIntegrationBatch {

    // Custom HttpCalloutMock implementation.
    // Note: The counter is an instance variable (not static) so that each callout increments it.
    private class ClubFitMock implements HttpCalloutMock {
        private Integer calloutCount = 0;
        public HTTPResponse respond(HTTPRequest req) {
            calloutCount++;
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            // Build a JSON response with one member record.
            String jsonBody = '{"data":[' +
                '{' +
                    '"Number": "TEST_' + calloutCount + '",' +
                    '"FirstName": "John",' +
                    '"LastName": "Doe",' +
                    '"Gender": "M",' +
                    '"Status": "Active",' +
                    '"Barcode": "12345",' +
                    '"FitnessPassportNumber": null,' +
                    '"DateOfBirth": "2000-01-01T00:00:00",' +
                    '"Contact": {' +
                        '"Email": "john.doe' + calloutCount + '@example.com",' +
                        '"Mobile": "041234567' + calloutCount + '",' +
                        '"OptOutEmail": false,' +
                        '"OptOutSms": false' +
                    '},' +
                    '"Membership": {' +
                        '"Id": 1,' +
                        '"Name": "Test Membership",' +
                        '"StartDate": "2025-02-12T00:00:00",' +
                        '"ExpiryDate": "2029-04-12T00:00:00"' +
                    '}' +
                '}' +
            ']}';
            res.setBody(jsonBody);
            res.setStatusCode(200);
            return res;
        }
    }
    
    // Test method for direct batch execution.
    @isTest
    static void testBatchProcessing() {
        Test.setMock(HttpCalloutMock.class, new ClubFitMock());
        
        Test.startTest();
            // Execute the batch with a scope size of 1.
            Database.executeBatch(new ClubFitIntegrationBatch(), 1);
        Test.stopTest();
        
        // Query for the Accounts that were upserted.
        List<Account> accounts = [SELECT Id, FirstName, LastName, Clubfit_Member_Id__c, AssociatedClub__c 
                                    FROM Account 
                                    WHERE Clubfit_Member_Id__c LIKE 'TEST_%'];
        System.debug('Number of accounts created: ' + accounts.size());
        // We expect 8 accounts—one for each club defined.
        System.assertEquals(8, accounts.size(), 'Expected 8 accounts to be inserted from the batch process.');
        
        // Optionally verify that the values were mapped correctly.
        for (Account acct : accounts) {
            System.assertEquals('John', acct.FirstName, 'FirstName should be John');
            System.assertEquals('Doe', acct.LastName, 'LastName should be Doe');
            System.assertNotEquals(null, acct.Clubfit_Member_Id__c, 'Clubfit_Member_Id__c should be populated');
            System.assertNotEquals(null, acct.AssociatedClub__c, 'AssociatedClub__c should be populated');
        }
    }
    
    // Test method for the Scheduler that invokes the batch.
    @isTest
    static void testSchedulerInvocation() {
        // Set up the HTTP callout mock.
        Test.setMock(HttpCalloutMock.class, new ClubFitMock());
        
        Test.startTest();
            // Schedule the scheduler job. In test context, scheduled jobs execute synchronously.
            String cronExp = '0 0 0 * * ?'; // Every day at midnight (for example)
            String jobId = System.schedule('Test ClubFit Scheduler', cronExp, new ClubFitScheduler());
        Test.stopTest();
        
        // Verify that a job ID was returned.
        System.assertNotEquals(null, jobId, 'The scheduler job should have been scheduled and a job id returned.');
    }
}