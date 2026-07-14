@isTest
public class DocTemplateGenUtilTest {
    
    @testSetup
    static void setup() {
        // Create test data for parent object
        Account parentAccount = new Account(Name = 'Test Account');
        insert parentAccount;

        // Create test data for child object
        Contact childContact = new Contact(LastName = 'Test Contact', AccountId = parentAccount.Id);
        insert childContact;
    }

    @isTest
    static void testGetRecords() {
        // Retrieve test data
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];

        // Call the method and validate results
        List<SObject> records = DocTemplateGenUtil.getRecords('Account', 'Contacts', '', testAccount.Id);

        // Assertions
        System.assertNotEquals(null, records, 'Records list should not be null');
        System.assertEquals(1, records.size(), 'There should be one parent record');
        System.assertEquals(testAccount.Id, records[0].Id, 'The parent record ID should match');
    }

    @isTest
    static void testGetObjectNameById() {
        // Retrieve test data
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        // Call the method and validate results
        String objectName = DocTemplateGenUtil.getObjectNameById(testAccount.Id);

        // Assertions
        System.assertEquals('Account', objectName, 'Object name should be Account');
    }
}