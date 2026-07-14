@isTest
public class Invoke_DocTemplateGen_BatchTest {
    
    static testMethod void testGenerateAndAttachPDF() {
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
        
        EmailTemplate et = [SELECT Id FROM EmailTemplate LIMIT 1];
        
        // Create a request
        Invoke_DocTemplateGen_Batch.Request request = new Invoke_DocTemplateGen_Batch.Request();
        request.recordId = testAccount.Id;
        request.docTemplate = docTemplate;
        request.setToAddrList = new List<String>{'test@gmail.com'};
		request.emailTemplateId = et.Id;
        request.senderDisplayName = 'test';
        request.targetObjectId = UserInfo.getUserId();
        request.whatId = testAccount.Id;
        request.saveAsActivity = true;
            
            // Add the request to a list
            List<Invoke_DocTemplateGen_Batch.Request> requestList = new List<Invoke_DocTemplateGen_Batch.Request>{request};
                
                // Call the method to test
                Test.startTest();
        Invoke_DocTemplateGen_Batch.generateAndAttachPDF(requestList);
        Test.stopTest();
    }
}