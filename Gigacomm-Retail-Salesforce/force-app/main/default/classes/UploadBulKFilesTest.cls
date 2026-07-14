@isTest
public class UploadBulKFilesTest {
     @testSetup static void setup() {
        // Set up test data
        Case newCase = new Case(
            Subject = 'Test subject',
            Description = 'Test description'
        );
        insert newCase;
         Org_Configuration__c setting = new Org_Configuration__c();
        // Create a new instance of the custom setting
        setting.ServiceNow_ClientSecret__c = '5673893939';
        setting.ServiceNow_ClientId__c = 'HYSUM&*()#033';
        setting.ServiceNow_Password__c = '8849993';
        setting.ServiceNow_Username__c = 'Servicenow';
        // Insert the custom setting record
        insert setting; 
     }
    @isTest
    static void testCreateIncident() {
        Test.startTest();  
        // Set the mock response for the HTTP callout
        Test.setMock(HttpCalloutMock.class, new ServiceNowApiMock());
        Case newCase = [select id,Comments,ServiceNow_Incident_ID__c,Description,Subject,Status,ServiceNow_Incident_Number__c from case LIMIT 1];
        
        SNIntegrationService.FlowInputs input = new SNIntegrationService.FlowInputs();
        input.CaseId = newCase.Id;
        input.uploadFile = false;
        List<SNIntegrationService.FlowInputs> inputList = new List<SNIntegrationService.FlowInputs>{input};
        SNIntegrationService.invokeServiceNow(inputList);
        ContentVersion content=new ContentVersion(); 
        content.Title='Header_Picture1'; 
        content.PathOnClient='/' + content.Title + '.jpg'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        //content.LinkedEntityId=sub.id;
        content.origin = 'H';
        insert content;
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=newCase.id;
        contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers'; 
        
        
        insert contentlink;
        UploadBulKFiles.invokeServiceNowUploadFiles(new List<string>{newCase.Id});
         Test.stopTest();
    }
}