@isTest
public class fetchMembershipDataUsingFromDate_Test {

    @isTest
    public static void testGetMembers() {
        
        RecordType objRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'PersonAccount' LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new MemberMockHttpResponseGenerator());
        
        String APIKey = 'dummyAPIKey';
        Integer limits = 100;
        Integer offset = 0;
        String club = 'Fitness Club';
         
        Club__c newclub= new Club__c();
        newclub.Name = 'Fitness Club';
        
        insert newclub;
        
        Map<String,Id> mapofclub= new  Map<String,Id>();
        mapofclub.put(newclub.Name,newclub.Id);
        
        Test.startTest();
        fetchMembershipDataUsingFromDate.getMembers(APIKey, limits, offset, objRecordType.Id, club, mapofclub);
        Test.stopTest();
    }
    
    @isTest
    public static void testMembershipBatch() {
        
        Test.setMock(HttpCalloutMock.class, new MemberMockHttpResponseGenerator());
        
        APIKeys__c apiKey = new APIKeys__c(
            Name = 'Test',
            Club__c = 'Fitness Club',
            Key__c = 'dummyAPIKey',
            Membership_Offset__c = 0,
            Membership_limit__c = 100
        );
        insert apiKey;
        
        RecordType objRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'PersonAccount' LIMIT 1];
        
        Test.startTest();
        membershipUsingFromDateBatch batch = new membershipUsingFromDateBatch();
        Database.executeBatch(batch);
        Test.stopTest();
    }
}