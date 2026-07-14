@isTest
public class SNIntegrationServiceTest {
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
        // Start a new transaction
        Test.startTest();  
        // Set the mock response for the HTTP callout
        Test.setMock(HttpCalloutMock.class, new ServiceNowApiMock());
        Case newCase = [select id,Comments,ServiceNow_Incident_ID__c,Description,Subject,Status,ServiceNow_Incident_Number__c from case LIMIT 1];
        SNIntegrationService.FlowInputs input = new SNIntegrationService.FlowInputs();
        input.CaseId = newCase.Id;
        input.uploadFile = true;
        List<SNIntegrationService.FlowInputs> inputList = new List<SNIntegrationService.FlowInputs>{input};
            SNIntegrationService.invokeServiceNow(inputList);
        
        Case Caseobj1 = [select id,Comments,ServiceNow_Incident_ID__c,Description,Subject,Status,ServiceNow_Incident_Number__c from case where Id=:newCase.Id];
        Caseobj1.Status='Closed';
        update Caseobj1;
        Case Caseobj2 = [select id,Comments,ServiceNow_Incident_ID__c,Description,Subject,Status,ServiceNow_Incident_Number__c from case where Id=:newCase.Id];
        Caseobj2.Description='testing subject';
        update Caseobj2;
        Case Caseobj3 = [select id,Comments,ServiceNow_Incident_ID__c,Description,Subject,Status,ServiceNow_Incident_Number__c from case where Id=:newCase.Id];
        Caseobj3.Subject='Demo testing subject';
        update Caseobj3;
        Test.stopTest();
        
        Case Caserec = [select id,Comments,ServiceNow_Incident_ID__c,Description,Subject,Status,ServiceNow_Incident_Number__c from case where Id=:newCase.Id];
        Assert.areEqual('1234567890', Caserec.ServiceNow_Incident_ID__c);
        Assert.areEqual('INC12345', Caserec.ServiceNow_Incident_Number__c);
    }
    @isTest
    static void testcaseComment() {
        Case newCase = [select id,Comments,ServiceNow_Incident_ID__c,Description,Subject,Status,ServiceNow_Incident_Number__c from case LIMIT 1];
        
        Test.startTest();  
        
        // Set the mock response for the HTTP callout
        Test.setMock(HttpCalloutMock.class, new ServiceNowApiMock());
        SNIntegrationService.FlowInputs input = new SNIntegrationService.FlowInputs();
        input.CaseId = newCase.Id;
        input.uploadFile = true;
        List<SNIntegrationService.FlowInputs> inputList = new List<SNIntegrationService.FlowInputs>{input};
            SNIntegrationService.invokeServiceNow(inputList);
        
        Case Caseobj1 = [select id,Comments,ServiceNow_Incident_ID__c,Description,Subject,Status,ServiceNow_Incident_Number__c from case where Id=:newCase.Id];
        
        CaseComment tComment = new CaseComment();
        tComment.ParentId = Caseobj1.Id;
        tComment.CommentBody = 'Some Comment';
        tComment.IsPublished = TRUE;
        
        INSERT tComment;
        CaseComment CaseComments = [select id,CommentBody from CaseComment where Id=:tComment.Id];
        CaseComments.CommentBody='update text';
        update CaseComments;
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
        try{
            ContentDocumentLink cLink=new ContentDocumentLink();
            cLink.LinkedEntityId='456789087';
            insert cLink;
        }catch(Exception e){
            SNIntegrationService.errorCapture(e); 
        }
        FeedItem newFeedItem = new FeedItem(
            ParentId = newCase.id,
            Type = 'TextPost',
            Body = 'This is a test FeedItem.'
        );
        
        insert newFeedItem;
        FeedComment newFeedComment = new FeedComment(
            FeedItemId = newFeedItem.Id,
            CommentBody = 'This is a test FeedComment.',
            CommentType ='TextComment'
        );
        insert newFeedComment;
        FeedComment FeedComments = [select id,CommentBody from FeedComment where Id=:newFeedComment.Id];
        FeedComments.CommentBody='update FeedComments text';
        update FeedComments;
        FeedItem feedItems = [select id,Body from FeedItem where Id=:newFeedItem.Id];
        feedItems.Body='update feedItems text';
        update feedItems;
        Test.stopTest();
        CaseComment CaseCommentobj = [select id,CommentBody from CaseComment where Id=:tComment.Id];
        
        Assert.areEqual('update text', CaseCommentobj.CommentBody);
        // Verify if the FeedItem is Updated successfully
        FeedItem insertedFeedItem = [SELECT Id, ParentId, Body FROM FeedItem WHERE Id = :newFeedItem.Id];
        Assert.areEqual('update feedItems text', insertedFeedItem.Body);
        Assert.areEqual(Caseobj1.Id, insertedFeedItem.ParentId);
        // Verify if the FeedComment is Updated successfully
         FeedComment insertedFeedComment = [SELECT Id, FeedItemId, CommentBody FROM FeedComment WHERE Id = :newFeedComment.Id];
         Assert.areEqual('update FeedComments text', insertedFeedComment.CommentBody);
        
    }
}