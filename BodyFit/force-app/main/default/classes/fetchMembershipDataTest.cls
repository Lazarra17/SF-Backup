@IsTest
public class fetchMembershipDataTest {
      @isTest
    public static void testGetMembers() {
        // Fetch the record type ID for PersonAccount (ensure PersonAccount is enabled in your org)
        Id personAccountId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'PersonAccount' LIMIT 1].Id;
        
        // If PersonAccount is not enabled or not found, the test will fail gracefully
        if (personAccountId == null) {
            System.assert(false, 'PersonAccount record type is not available in this org.');
        }

        // Set up mock response
        Test.setMock(HttpCalloutMock.class, new MemberMockHttpResponseGenerator());

        // Define test inputs
        String APIKey = 'dummyAPIKey';
        Integer limits = 100;
        Integer offset = 0;
        String club = 'Fitness Club';
         
        Club__c newclub= new Club__c();
        newclub.Name = 'Fitness Club';
        
        insert newclub;
        
        Map<String,Id> mapofclub= new  Map<String,Id>();
        mapofclub.put(newclub.Name,newclub.Id);

        // Execute the method to test
        Test.startTest();
        List<Account> members = fetchMembershipData.getMembers(APIKey, limits, offset, personAccountId, club,mapofclub);
        Test.stopTest();
        // Execute the batch
    }
    @isTest
    public static void testMembershipBatch() {
        // Set up mock response
        Test.setMock(HttpCalloutMock.class, new MemberMockHttpResponseGenerator());

        // Create test APIKey record
        APIKeys__c apiKey = new APIKeys__c(
            Name = 'Test',
            Club__c = 'Fitness Club',
            Key__c = 'dummyAPIKey',
            Membership_Offset__c = 0,
            Membership_limit__c = 100
        );
        insert apiKey;

        // Create test record type for PersonAccount
        RecordType personAccountType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'PersonAccount' LIMIT 1];

        // Execute the batch
        Test.startTest();
        membershipBatch batch = new membershipBatch();
        Database.executeBatch(batch);
        Test.stopTest();

       
    }
}