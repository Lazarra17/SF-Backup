@isTest
public class fetchPaymentDataTest {
    @isTest
    public static void testGetPayment() {
        
        // Set up mock response
        Test.setMock(HttpCalloutMock.class, new paymentMockHttpResponseGenerator());
        
        // Define test inputs
        String APIKey = 'dummyAPIKey';
        Integer limits = 500;
        Integer offset = 0;
        String club = 'Fitness Club';
        
        Club__c newclub= new Club__c();
        newclub.Name = 'Fitness Club';
        
        insert newclub;
        
        Map<String,Id> mapofclub= new  Map<String,Id>();
        mapofclub.put(newclub.Name,newclub.Id);
        
        
        // Execute the method to test
        Test.startTest();
        List<Payment_History__c> payment = fetchPaymentData.getPaymentHistory(APIKey, limits, offset, club, mapofclub);
        Test.stopTest();
        
    }
   @isTest
    public static void testVisitBatch() {
        // Set up mock response
        Test.setMock(HttpCalloutMock.class, new paymentMockHttpResponseGenerator());
        
        // Create test APIKey record
        APIKeys__c apiKey = new APIKeys__c();
        apiKey.Name = 'Test';
        apiKey.Club__c = 'Fitness Club';
        apiKey.Key__c = 'dummyAPIKey';
        apiKey.Payment_Offset__c = 0;
        apiKey.Payment_limit__c = 500;
        
        insert apiKey;
        
        // Execute the batch
        Test.startTest();
        paymentHistoryBatch batch = new paymentHistoryBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
    }    
}