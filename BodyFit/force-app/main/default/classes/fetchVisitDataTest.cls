@isTest
public class fetchVisitDataTest {
    
    @isTest
    public static void testGetVisit() {
        
        // Set up mock response
        Test.setMock(HttpCalloutMock.class, new visitMockHttpResponseGenerator());
        
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
        List<Visitation__c> visit = fetchVisitData.getVisits(APIKey, limits, offset, club, mapofclub);
        Test.stopTest();
        
    }
    @isTest
    public static void testVisitBatch() {
        // Set up mock response
        Test.setMock(HttpCalloutMock.class, new visitMockHttpResponseGenerator());
        
        // Create test APIKey record
        APIKeys__c apiKey = new APIKeys__c();
        apiKey.Name = 'Test';
        apiKey.Club__c = 'Fitness Club';
        apiKey.Key__c = 'dummyAPIKey';
        apiKey.Offset__c = 0;
        apiKey.limit__c = 500;
        
        insert apiKey;
        
        // Execute the batch
        Test.startTest();
        visitBatch batch = new visitBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
    }
}