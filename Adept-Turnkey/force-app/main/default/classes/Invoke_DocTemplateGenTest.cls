@IsTest
private class Invoke_DocTemplateGenTest {
    
    @IsTest
    static void testGenerateAndAttachPDF() {
        // Setup test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        nao__Document_Template__c docTemplate = new nao__Document_Template__c(
            nao__VisualForce_Template__c = 'TestVFPage',
            nao__sObject__c = 'Account',
            nao__Child_sObject__c = 'Contact',
            nao__Status__c = 'Active',
            nao__Title_Custom_Field__c = 'Name'
        );
        insert docTemplate;

        // Create a request
        Invoke_DocTemplateGen.Request request = new Invoke_DocTemplateGen.Request();
        request.recordId = testAccount.Id;
        request.docTemplates = new List<nao__Document_Template__c>{docTemplate};

        // Add the request to a list
        List<Invoke_DocTemplateGen.Request> requestList = new List<Invoke_DocTemplateGen.Request>{request};

        // Call the method to test
        Test.startTest();
        Invoke_DocTemplateGen.generateAndAttachPDF(requestList);
        Test.stopTest();

        System.assert([select id from contentversion where nao__Record_ID__c =: testAccount.Id] != null, 'PDF Generated and Attached');
    }
}