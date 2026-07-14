@isTest
public class updateMemberNameBatchTest {
   @isTest
    static void testUpdateMemberNameBatch() {
        // Ensure all records fit in a single batch
         // Fetch the record type ID for PersonAccount (ensure PersonAccount is enabled in your org)
         
        recordType personAccountId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'PersonAccount' LIMIT 1];

        // Create Accounts (Person Accounts) with Clubfit Member IDs
        List<Account> accounts = new List<Account>{
            new Account(
                FirstName = 'John',
                LastName = 'Doe',
                Clubfit_Member_Id__c = '12345',
                RecordTypeId = personAccountId.Id,
                PersonEmail = 'test@gmail.com'
            ),
            new Account(
                FirstName = 'Jane',
                LastName = 'Smith',
                Clubfit_Member_Id__c = '67890',
                RecordTypeId = personAccountId.Id,
                PersonEmail = 'test123@gmail.com'
            )
        };
        insert accounts;

        // Create Visitation records with Member_ID__c matching the Accounts and one without a match
        List<Visitation__c> visitations = new List<Visitation__c>{
            new Visitation__c(Member_ID__c = '12345', Member__c = null),
            new Visitation__c(Member_ID__c = '67890', Member__c = null)
        };
        insert visitations;
        
        Test.startTest();
        updateMemberNameBatch batch = new updateMemberNameBatch();
        Database.executeBatch(batch); // Match the number of records in testSetup
        Test.stopTest();
    }
}