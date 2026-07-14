@isTest
private class ClubFitPaymentHistoryBatchTest {

    // Callout mock to simulate responses for all ClubFit endpoints.
    class ClubFitServiceHttpCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            String endpoint = req.getEndpoint();
            
            if (endpoint.contains('/v1/token')) {
                // Simulate token endpoint response.
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"AccessToken": "dummyToken"}');
                res.setStatusCode(200);
            }
            else if (endpoint.contains('/v1/members?')) {
                // Simulate members endpoint response.
                res.setHeader('Content-Type', 'application/json');
                String body = '{'
                    + '"href": "https://api.clubfit.net.au/v1/members",'
                    + '"data": ['
                    + '    {'
                    + '       "Number": "MEM123",'
                    + '       "FirstName": "Alice",'
                    + '       "LastName": "Smith",'
                    + '       "DateOfBirth": "1985-05-10T00:00:00"'
                    + '    }'
                    + ']'
                    + '}';
                res.setBody(body);
                res.setStatusCode(200);
            }
            else if (endpoint.contains('/v1/members/attendance/visits')) {
                // Simulate visits endpoint response.
                res.setHeader('Content-Type', 'application/json');
                String body = '{'
                    + '"href": "https://api.clubfit.net.au/v1/members/attendance/visits",'
                    + '"data": ['
                    + '    {'
                    + '       "MemberNumber": "MEM123",'
                    + '       "Door": "Main Entrance",'
                    + '       "ScanSource": "Card",'
                    + '       "VisitDateTime": "2024-08-24T09:00:00Z"'
                    + '    }'
                    + ']'
                    + '}';
                res.setBody(body);
                res.setStatusCode(200);
            }
            else if (endpoint.contains('/v1/members/payment/history')) {
                // Simulate payment history endpoint response.
                res.setHeader('Content-Type', 'application/json');
                String body = '{'
                    + '"href": "https://api.clubfit.net.au/v1/members/payment/history?fromdate=2024-08-24T00:00:00&limit=500&offset=0",'
                    + '"next": "https://api.clubfit.net.au/v1/members/payment/history?limit=500&offset=500&fromdate=2024-08-24T00:00:00",'
                    + '"data": ['
                    + '    {'
                    + '       "Id": 2353116,'
                    + '       "Number": "MEM123",'
                    + '       "Amount": 29.21,'
                    + '       "PaymentDate": "2024-08-24T01:48:10.977Z",'
                    + '       "PaymentType": "CC",'
                    + '       "Response": "1000 Transaction Approved - Manual Online Payment (New Credit Card)",'
                    + '       "PaymentDescription": "MEMBER_OVERDUE_ONLINE",'
                    + '       "PaymentForReference": {'
                    + '           "Id": 422,'
                    + '           "Name": "Arrears"'
                    + '       },'
                    + '       "FeeBreakdown": {'
                    + '           "AccessCardFee": 0.00,'
                    + '           "AddOnAmount": 0.00,'
                    + '           "Adjustment": 0.00,'
                    + '           "ArrearsFee": 0.00,'
                    + '           "CancellationLateFee": 0.00,'
                    + '           "CardSurchargeFee": 0.00,'
                    + '           "ClassNoShowFee": 0.00,'
                    + '           "CrecheClassNoShowFee": 0.00,'
                    + '           "DishonourFee": 0.00,'
                    + '           "JoiningFee": 0.00,'
                    + '           "MaintenanceFee": 0.00,'
                    + '           "PosTransaction": 0.00,'
                    + '           "Prorata": 0.00,'
                    + '           "PtNoShowFee": 0.00,'
                    + '           "SetupFee": 0.00,'
                    + '           "SubscriptionFee": 0.00,'
                    + '           "SuspensionFee": 0.00,'
                    + '           "TransactionFee": 0.00'
                    + '       },'
                    + '       "Refund": {'
                    + '           "IsRefund": false,'
                    + '           "RefundedPaymentId": null'
                    + '       }'
                    + '    },'
                    + '    {'
                    + '       "Id": 2353123,'
                    + '       "Number": "MEM123",'
                    + '       "Amount": 113.50,'
                    + '       "PaymentDate": "2024-08-24T16:39:42.150Z",'
                    + '       "PaymentType": null,'
                    + '       "Response": "00 Manual Offline Payment",'
                    + '       "PaymentDescription": "MEMBER_OVERDUE_CLUBFIT",'
                    + '       "PaymentForReference": {'
                    + '           "Id": 425,'
                    + '           "Name": null'
                    + '       },'
                    + '       "FeeBreakdown": {'
                    + '           "AccessCardFee": 0.00,'
                    + '           "AddOnAmount": 0.00,'
                    + '           "Adjustment": 0.00,'
                    + '           "ArrearsFee": 0,'
                    + '           "CancellationLateFee": 0,'
                    + '           "CardSurchargeFee": 0,'
                    + '           "ClassNoShowFee": 0,'
                    + '           "CrecheClassNoShowFee": 0,'
                    + '           "DishonourFee": 0,'
                    + '           "JoiningFee": 0,'
                    + '           "MaintenanceFee": 0,'
                    + '           "PosTransaction": 113.51,'
                    + '           "Prorata": 0.00,'
                    + '           "PtNoShowFee": 0,'
                    + '           "SetupFee": 0,'
                    + '           "SubscriptionFee": 0,'
                    + '           "SuspensionFee": 0,'
                    + '           "TransactionFee": 0'
                    + '       },'
                    + '       "Refund": {'
                    + '           "IsRefund": false,'
                    + '           "RefundedPaymentId": null'
                    + '       }'
                    + '    }'
                    + ']'
                    + '}';
                res.setBody(body);
                res.setStatusCode(200);
            }
            else {
                res.setStatusCode(404);
                res.setBody('{"error": "Not found"}');
            }
            return res;
        }
    }

    // Service method tests
    @isTest
    static void testGetAccessToken() {
        Test.setMock(HttpCalloutMock.class, new ClubFitServiceHttpCalloutMock());
        String token = ClubFitService.getAccessToken();
        System.assertEquals('dummyToken', token, 'The access token should be dummyToken');
    }

    @isTest
    static void testGetMembersJSON() {
        Test.setMock(HttpCalloutMock.class, new ClubFitServiceHttpCalloutMock());
        String fromDate = '2024-08-24T00:00:00';
        String updateDate = '2024-08-24T00:00:00';
        String jsonResponse = ClubFitService.getMembersJSON(fromDate, updateDate, 'dummyApiKey');
        System.assert(jsonResponse.contains('"data": ['), 'Response should contain a data array');
    }

    @isTest
    static void testGetVisitsJSON() {
        Test.setMock(HttpCalloutMock.class, new ClubFitServiceHttpCalloutMock());
        String fromDate = '2024-08-24T00:00:00';
        String jsonResponse = ClubFitService.getVisitsJSON(fromDate, 'dummyApiKey', 0);
        System.assert(jsonResponse.contains('"data": ['), 'Response should contain a data array');
    }

    @isTest
    static void testGetPaymentHistoryJSON() {
        Test.setMock(HttpCalloutMock.class, new ClubFitServiceHttpCalloutMock());
        String fromDate = '2024-08-24T00:00:00';
        String jsonResponse = ClubFitService.getPaymentHistoryJSON(fromDate, 'dummyApiKey', 0);
        System.assert(jsonResponse.contains('"data": ['), 'Response should contain a data array');
    }
    
    // Batch tests for Payment History
    @isTest
    static void testPaymentHistoryBatchExecuteDirectly() {
        Test.setMock(HttpCalloutMock.class, new ClubFitServiceHttpCalloutMock());
        ClubFitPaymentHistoryBatch batch = new ClubFitPaymentHistoryBatch();
        batch.execute(null, new List<String>{ 'start' });
        // Our mock returns 2 records per club. With 8 clubs in the map, expect 16 records.
        List<Payment_History__c> payments = [SELECT Id FROM Payment_History__c];
        System.assertEquals(16, payments.size(), 'Sixteen payment history records should be inserted via direct execute call');
    }
    
    @isTest
    static void testPaymentHistoryBatchUsingExecuteBatch() {
        Test.setMock(HttpCalloutMock.class, new ClubFitServiceHttpCalloutMock());
        Test.startTest();
        Database.executeBatch(new ClubFitPaymentHistoryBatch(), 1);
        Test.stopTest();
        List<Payment_History__c> payments = [SELECT Id FROM Payment_History__c];
        System.assertEquals(16, payments.size(), 'Sixteen payment history records should be inserted via executeBatch');
    }
    
    // Scheduler test for Payment History batch.
    @isTest
    static void testPaymentHistorySchedulerJobScheduling() {
        String cronExp = '0 0 0 * * ?';
        String jobId = System.schedule('Test_ClubFitPaymentHistorySchedulerJob', cronExp, new ClubFitPaymentHistoryScheduler());
        System.assertNotEquals(null, jobId, 'The payment history scheduler job should be scheduled successfully.');
    }
}