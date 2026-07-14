@IsTest
private class MefGetOrderStatusInvocableTest {

    // Mock implementation for the HTTP callout
    private class MefGetOrderStatusMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake HTTP response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            // Set a status code to simulate a successful response
            res.setStatusCode(200); 
            res.setStatus('OK');
            // The actual body isn't strictly necessary for this test since the invocable method only uses the status code.
            res.setBody('{"status": "Completed"}'); 
            return res;
        }
    }

    @IsTest
    static void testPerformActionSuccess() {
        // 1. Setup Test Data
        // The Opportunity fields queried in the class must be included here for DML insert
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opp for MEF Status',
            StageName = 'New',
            CloseDate = Date.today().addDays(30),
            // Custom fields queried in the SOQL
            Completion_Date_bric__c = Date.today(), 
            Expected_Completion_Date_bric__c = Date.today().addDays(7),
            Mef_Product_Order_Note_Ids_bric__c = 'TestNote123',
            Mef_Order_Product_Id_bric__c = 'TestOrderProdId',
            Mef_Status_bric__c = 'Pending',
            Service_Identification_Number_bric__c = 'SIN123'
        );
        insert testOpp;

        // 2. Mock the External Callout
        // Ensure the external service class is correctly mocked before the callout happens
        Test.setMock(HttpCalloutMock.class, new MefGetOrderStatusMock());

        // Setup the input list for the Invocable Method
        List<MefGetOrderStatusInvocable.MefGetOrderStatusInput> inputList = 
            new List<MefGetOrderStatusInvocable.MefGetOrderStatusInput>();
        
        MefGetOrderStatusInvocable.MefGetOrderStatusInput input = 
            new MefGetOrderStatusInvocable.MefGetOrderStatusInput();
        input.recordId = testOpp.Id;
        inputList.add(input);
        
        // 3. Execute the Method within Test.startTest() / Test.stopTest()
        List<MefGetOrderStatusInvocable.MefGetOrderStatusOutput> results;
        
        Test.startTest();
        
        results = MefGetOrderStatusInvocable.performAction(inputList);
        Test.stopTest();
        
        
    }
}