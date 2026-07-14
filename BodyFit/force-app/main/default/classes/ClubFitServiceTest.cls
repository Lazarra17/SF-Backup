@isTest
private class ClubFitServiceTest {

    // This mock simulates responses for the token, members, visits, and payment history endpoints.
    private class ClubFitServiceMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            String endpoint = req.getEndpoint();
            
            if(endpoint.contains('/v1/token')) {
                // Simulate token response
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"AccessToken": "dummyToken"}');
                res.setStatusCode(200);
            }
            else if(endpoint.contains('/v1/members') && 
                    !endpoint.contains('attendance/visits') &&
                    !endpoint.contains('payment/history')) {
                // Simulate members response
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"data": [{"Number": "12345", "FirstName": "John", "LastName": "Doe"}]}');
                res.setStatusCode(200);
            }
            else if(endpoint.contains('/v1/members/attendance/visits')) {
                // Simulate visits response
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"data": [{"MemberNumber": "V123", "VisitDate": "2025-02-18T00:00:00Z"}]}');
                res.setStatusCode(200);
            }
            else if(endpoint.contains('/v1/members/payment/history')) {
                // Simulate payment history response
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"data": [{"PaymentId": "P123", "Amount": 100}]}');
                res.setStatusCode(200);
            }
            else {
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"error": "Not found"}');
                res.setStatusCode(404);
            }
            return res;
        }
    }
    
    @isTest
    static void testGetAccessToken() {
        Test.setMock(HttpCalloutMock.class, new ClubFitServiceMock());
        String token = ClubFitService.getAccessToken();
        System.assertEquals('dummyToken', token, 'Access token should be dummyToken');
    }
    
    @isTest
    static void testGetMembersJSON() {
        Test.setMock(HttpCalloutMock.class, new ClubFitServiceMock());
        String jsonResponse = ClubFitService.getMembersJSON('2025-01-01T00:00:00', '2025-01-02T00:00:00', 'dummyApiKey');
        System.assert(jsonResponse.contains('"data"'), 'Response should contain a data field');
        
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        List<Object> dataList = (List<Object>) responseMap.get('data');
        System.assertEquals(1, dataList.size(), 'There should be one member record');
        Map<String, Object> member = (Map<String, Object>) dataList[0];
        System.assertEquals('John', member.get('FirstName'), 'FirstName should be John');
    }
    
    @isTest
    static void testGetVisitsJSON() {
        Test.setMock(HttpCalloutMock.class, new ClubFitServiceMock());
        String jsonResponse = ClubFitService.getVisitsJSON('2025-01-01T00:00:00', 'dummyApiKey', 0);
        System.assert(jsonResponse.contains('"data"'), 'Response should contain a data field');
        
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        List<Object> dataList = (List<Object>) responseMap.get('data');
        System.assertEquals(1, dataList.size(), 'There should be one visit record');
        Map<String, Object> visit = (Map<String, Object>) dataList[0];
        System.assertEquals('V123', visit.get('MemberNumber'), 'MemberNumber should be V123');
    }
    
    @isTest
    static void testGetPaymentHistoryJSON() {
        Test.setMock(HttpCalloutMock.class, new ClubFitServiceMock());
        String jsonResponse = ClubFitService.getPaymentHistoryJSON('2025-01-01T00:00:00', 'dummyApiKey', 0);
        System.assert(jsonResponse.contains('"data"'), 'Response should contain a data field');
        
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        List<Object> dataList = (List<Object>) responseMap.get('data');
        System.assertEquals(1, dataList.size(), 'There should be one payment history record');
        Map<String, Object> payment = (Map<String, Object>) dataList[0];
        System.assertEquals('P123', payment.get('PaymentId'), 'PaymentId should be P123');
    }
}