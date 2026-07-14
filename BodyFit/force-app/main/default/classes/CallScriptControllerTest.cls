@isTest
public class CallScriptControllerTest {

    @isTest
    static void testGetCallScripts() {
        // Step 1: Create test data
        // Create a few Call Script records with necessary fields
        Call_Script__c script1 = new Call_Script__c(
            Name = 'Introduction Script', 
            Script_Content__c = 'This is the introduction script content.',
            Category__c = 'Closing',
            Sequence__c = 1
        );
        
        Call_Script__c script2 = new Call_Script__c(
            Name = 'Product Information Script',
            Script_Content__c = 'This is the product information script content.',
            Category__c = 'Introduction',
            Sequence__c = 2
        );
        
        insert new List<Call_Script__c>{script1, script2};

        // Step 2: Call the Apex method
        Test.startTest();
        List<Call_Script__c> scripts = CallScriptController.getCallScripts('dummyLeadId');
        Test.stopTest();

        // Step 3: Assertions
        // Ensure the correct number of scripts are returned
        System.assertEquals(2, scripts.size(), 'There should be 2 Call Scripts returned.');

        // Ensure the content of the scripts are as expected
        System.assertEquals('This is the introduction script content.', scripts[0].Script_Content__c, 'Script content mismatch.');
        System.assertEquals('This is the product information script content.', scripts[1].Script_Content__c, 'Script content mismatch.');

        // Ensure the scripts are ordered by sequence
        System.assertEquals('Introduction Script', scripts[0].Name, 'Script names are not in the expected sequence.');
        System.assertEquals('Product Information Script', scripts[1].Name, 'Script names are not in the expected sequence.');
    }
}