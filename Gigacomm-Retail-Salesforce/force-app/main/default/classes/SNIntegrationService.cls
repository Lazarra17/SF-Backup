public with sharing class SNIntegrationService {
    
    @InvocableMethod(label='Get caseId' description='call service Now system')
    public static void invokeServiceNow(List<FlowInputs> flowInputs) {
        try{
            Org_Configuration__c mc = Org_Configuration__c.getOrgDefaults();
            String caseId = flowInputs.get(0).CaseId;
            Case caseobj = [Select Id ,Comments,ServiceNow_State__c, Status, CaseNumber,Subject,Description,ServiceNow_Incident_ID__c,ServiceNow_Incident_Number__c from Case where Id =:caseId];
            string description = generateDescription(caseId,caseobj.Description);
            //Create Incident
            if(caseobj.ServiceNow_Incident_ID__c ==null && caseobj.ServiceNow_Incident_Number__c ==null &&caseobj.ServiceNow_State__c != 'Closed'){
                Map<String, String> payload = new Map<String, String>{'caller_id'=>mc.ServiceNow_Username__c,'short_description'=>caseobj.Subject,'description'=>description,'correlation_id'=>caseobj.Id,'u_external_ticket_number'=>caseobj.CaseNumber,'correlation_display'=>'Salesforce','u_support_type'=>'network_operations'};
                    List<Web_Services_Credential__mdt> request = [
                        SELECT Method_Type__c, Success_Code__c, Timeout__c, URL__c
                        FROM Web_Services_Credential__mdt
                        WHERE DeveloperName = 'Create_ServiceNow_Incident'
                    ];
                string responseData =  createServiceNowIncident(Json.serialize(payload) ,request.get(0).URL__c,request.get(0).Method_Type__c, caseobj.CaseNumber);
                
                PayloadWrapper wrapper = (PayloadWrapper)JSON.deserialize(responseData, PayloadWrapper.class);
                String sysId = wrapper.result.sys_id;
                String incidentNumber = wrapper.result.task_effective_number;
                
                updateSalesforceRecord(incidentNumber, sysId,caseobj.Id);
                if(flowInputs.get(0).uploadFile ==true){
                    UploadBulKFiles.invokeServiceNowUploadFiles(new List<String>{flowInputs.get(0).CaseId});
                }
            }
        }
        catch(Exception e) {
            system.debug('e.getMessage()'+e.getMessage()+'    '+e.getStackTraceString());
            errorCapture(e);
        }
        
    } 
    public static void createCommentInServiceNow(List<SObject> newvalues){
        List<Web_Services_Credential__mdt> request = [
            SELECT Method_Type__c, Success_Code__c, Timeout__c, URL__c
            FROM Web_Services_Credential__mdt
            WHERE DeveloperName = 'Update_ServiceNow_Incident'
        ];
        User integrationUserId = [SELECT Id from user where Name ='ServiceNow Integration'];
        for(Sobject eachobject :newvalues ){
            String ParentId ='';
            String commentBody ='';
            if (eachobject instanceof CaseComment) {
                CaseComment CaseCommentRecord = (CaseComment) eachobject;
                if(CaseCommentRecord.CreatedById != integrationUserId.Id && CaseCommentRecord.CommentBody !=null && CaseCommentRecord.ParentId.getSObjectType() == case.SObjectType){
                    // NEW CHECK: Skip if comment originated from ServiceNow (has the marker)
                    if(CaseCommentRecord.CommentBody.contains('[SNOW_ORIGIN:')) {
                        System.debug('Skipping comment sync back to ServiceNow - detected SNOW_ORIGIN marker');
                        continue; // Skip this comment - it came from ServiceNow originally
                    }
                    ParentId =CaseCommentRecord.ParentId ;
                    commentBody = CaseCommentRecord.CommentBody;
                }
            }
            if (eachobject instanceof FeedItem) {
                FeedItem feedItemRecord = (FeedItem) eachobject;
                if((feedItemRecord.Type =='TextPost' ||feedItemRecord.Type =='ContentPost') && feedItemRecord.CreatedById != integrationUserId.Id && String.isNotBlank(feedItemRecord.Body)){
                    // NEW CHECK: Skip if comment originated from ServiceNow (has the marker)
                    if(feedItemRecord.Body.contains('[SNOW_ORIGIN:')) {
                        System.debug('Skipping feed item sync back to ServiceNow - detected SNOW_ORIGIN marker');
                        continue; // Skip this feed item - it came from ServiceNow originally
                    }
                    ParentId =feedItemRecord.ParentId ;
                    commentBody = feedItemRecord.Body.stripHtmlTags();
                }
            }
            if (eachobject instanceof FeedComment) {
                FeedComment feedCommentRecord = (FeedComment) eachobject;
                if((feedCommentRecord.CommentType =='TextComment' ||feedCommentRecord.CommentType =='ContentComment') && feedCommentRecord.CreatedById != integrationUserId.Id && String.isNotBlank(feedCommentRecord.CommentBody)){
                    // NEW CHECK: Skip if comment originated from ServiceNow (has the marker)
                    if(feedCommentRecord.CommentBody.contains('[SNOW_ORIGIN:')) {
                        System.debug('Skipping feed comment sync back to ServiceNow - detected SNOW_ORIGIN marker');
                        continue; // Skip this feed comment - it came from ServiceNow originally
                    }
                    ParentId =feedCommentRecord.ParentId ;
                    commentBody = feedCommentRecord.CommentBody.stripHtmlTags();
                }
            }
            if(ParentId !='' && commentBody !=''){
                Case caseobj = [Select Id ,Comments, Status,ServiceNow_State__c, CaseNumber,Subject,Description,ServiceNow_Incident_ID__c,ServiceNow_Incident_Number__c from Case where Id =:ParentId];
                if(caseobj.ServiceNow_Incident_ID__c !=null && caseobj.ServiceNow_Incident_Number__c !=null && caseobj.ServiceNow_State__c != 'Closed'){
                    // Log when we're sending a comment back to ServiceNow
                    System.debug('Sending comment to ServiceNow for Case: ' + caseobj.CaseNumber + ' (No SNOW_ORIGIN marker found - this is a genuine Salesforce comment)');
                    Map<String, String> jsondata =new Map<String, String>{'comments'=>commentBody};
                        string endpointUrl =request.get(0).URL__c+ '/'+caseobj.ServiceNow_Incident_ID__c;
                    try{
                        updateServiceNowIncident(Json.serialize(jsondata) ,endpointUrl,request.get(0).Method_Type__c,null, caseobj.CaseNumber);
                    }
                    catch(Exception e) {
                        errorCapture(e);
                    }
                }
            }
        }
    }
    
    
    public static void updateCommentInServiceNow(List<SObject> newvalues,Map<Id, SObject> oldMapvalue){
        List<Web_Services_Credential__mdt> request = [
            SELECT Method_Type__c, Success_Code__c, Timeout__c, URL__c
            FROM Web_Services_Credential__mdt
            WHERE DeveloperName = 'Update_ServiceNow_Incident'
        ];
        User integrationUserId = [SELECT Id from user where Name ='ServiceNow Integration'];
        for(Sobject eachobject :newvalues ){
            String ParentId ='';
            String commentBody ='';
            if (eachobject instanceof CaseComment) {
                CaseComment CaseCommentRecord = (CaseComment) eachobject;
                CaseComment oldvalueCaseComment =  (CaseComment) oldMapvalue.get(eachobject.Id);
                if(CaseCommentRecord.CommentBody != oldvalueCaseComment.CommentBody && CaseCommentRecord.CreatedById != integrationUserId.Id && CaseCommentRecord.CommentBody !=null && CaseCommentRecord.ParentId.getSObjectType() == case.SObjectType){
                    ParentId =CaseCommentRecord.ParentId ;
                    commentBody = 'The comment has been updated from \''+ oldvalueCaseComment.CommentBody +'\' to \''+ CaseCommentRecord.CommentBody+'\'.';
                }
            }
            if (eachobject instanceof FeedItem) {
                FeedItem feedItemRecord = (FeedItem) eachobject;
                FeedItem oldFeedItemvalue =  (FeedItem) oldMapvalue.get(eachobject.Id);
                if(feedItemRecord.Body != oldFeedItemvalue.Body && (feedItemRecord.Type =='TextPost' ||feedItemRecord.Type =='ContentPost') && feedItemRecord.CreatedById != integrationUserId.Id && String.isNotBlank(feedItemRecord.Body)){
                    ParentId =feedItemRecord.ParentId ;
                    commentBody = 'The comment has been updated from \''+ oldFeedItemvalue.Body.stripHtmlTags() +'\' to \''+ feedItemRecord.Body.stripHtmlTags() +'\'.';
                    
                }
            }
            if (eachobject instanceof FeedComment) {
                FeedComment feedCommentRecord = (FeedComment) eachobject;
                FeedComment oldfeedCommentvalue =  (FeedComment) oldMapvalue.get(eachobject.Id);
                if(feedCommentRecord.CommentBody != oldfeedCommentvalue.CommentBody && (feedCommentRecord.CommentType =='TextComment' ||feedCommentRecord.CommentType =='ContentComment') && feedCommentRecord.CreatedById != integrationUserId.Id && String.isNotBlank(feedCommentRecord.CommentBody)){
                    ParentId =feedCommentRecord.ParentId ;
                    commentBody = 'The comment has been updated from \''+oldfeedCommentvalue.CommentBody.stripHtmlTags() +'\' to \''+ feedCommentRecord.CommentBody.stripHtmlTags() +'\'.';
                }
            }
            if(ParentId !='' && commentBody !=''){
                Case caseobj = [Select Id ,Comments, Status,ServiceNow_State__c, CaseNumber,Subject,Description,ServiceNow_Incident_ID__c,ServiceNow_Incident_Number__c from Case where Id =:ParentId];
                if(caseobj.ServiceNow_Incident_ID__c !=null && caseobj.ServiceNow_Incident_Number__c !=null && caseobj.ServiceNow_State__c != 'Closed'){
                    Map<String, String> jsondata =new Map<String, String>{'comments'=>commentBody};
                        string endpointUrl =request.get(0).URL__c+ '/'+caseobj.ServiceNow_Incident_ID__c; 
                    try{
                        updateServiceNowIncident(Json.serialize(jsondata) ,endpointUrl,request.get(0).Method_Type__c,null, caseobj.CaseNumber);
                    }
                    catch(Exception e) { 
                        errorCapture(e);
                    }
                }
            }
        }
    }
    public static void updateIncident(List<case> newvalues, Map<Id, Case> oldMapvalue) {
        List<Web_Services_Credential__mdt> request = [
            SELECT Method_Type__c, Success_Code__c, Timeout__c, URL__c
            FROM Web_Services_Credential__mdt
            WHERE DeveloperName = 'Update_ServiceNow_Incident'
        ];
        for(Case caseobj :newvalues ){
            Map<String, String> payload =new Map<String, String>();
            Case oldvalue = oldMapvalue.get(caseobj.Id);
            if(caseobj.ServiceNow_Incident_ID__c !=null && caseobj.ServiceNow_Incident_Number__c !=null && caseobj.ServiceNow_State__c != 'Closed'){
                if(caseobj.Status =='Closed' && oldvalue.Status !='Closed'){
                    Map<String, String> jsondata =new Map<String, String>{'comments'=>'The case is marked as Closed'};
                        payload.putAll(jsondata);  
                }else if(caseobj.Subject != oldvalue.Subject){
                    Map<String, String> jsondata =new Map<String, String>{'short_description'=>caseobj.Subject};
                        payload.putAll(jsondata);
                }
                else if(caseobj.Description != oldvalue.Description){
                    string description = generateDescription(caseobj.Id,caseobj.Description); 
                    Map<String, String> jsondata =new Map<String, String>{'description'=>description};
                        payload.putAll(jsondata);
                }
            }
            try{
                
                if(!payload.isEmpty()){
                    string endpointUrl =request.get(0).URL__c+ '/'+caseobj.ServiceNow_Incident_ID__c;                
                    updateServiceNowIncident(Json.serialize(payload) ,endpointUrl,request.get(0).Method_Type__c,null, caseobj.CaseNumber);
                }
            }catch(Exception e) {
                errorCapture(e);
            }
            
        }
    }
    public static void updateSalesforceRecord(String incidentNumber, String sysId, Id caseId) {
        Case caseobj = new case();
        caseobj.Id = caseId;
        caseobj.ServiceNow_Incident_ID__c =sysId;
        caseobj.ServiceNow_Incident_Number__c =incidentNumber;
        caseobj.ServiceNow_State__c ='New';
        update caseobj;
    }
    public static string generateDescription(Id caseId, string description){
        Case caseobj = [Select Id ,Comments,Contact.MailingPostalCode,Account.GigaComm_ID_Bric__c,Contact.MailingCity,Contact.MailingState,Contact.MailingStreet,Contact.MailingCountry,Contact.Name,Account.Name,ContactPhone, Status, CaseNumber,Subject,Account.BillingCity,Account.BillingStreet,Account.BillingState,Account.BillingPostalCode,Description,ServiceNow_Incident_ID__c,ContactEmail,ServiceNow_Incident_Number__c from Case where Id =:caseId];
        
        string des ='Contact:'+checknull(caseobj.Contact.Name)+'\n'+
            'Account:'+caseobj.Account.Name+' (Account Number:'+caseobj.Account.GigaComm_ID_Bric__c+'),'+'\n'+
            'Address:'+checknull(caseobj.Contact.MailingStreet) +checknull(caseobj.Contact.MailingCity)+checknull(caseobj.Contact.MailingState)+checknull(caseobj.Contact.MailingPostalCode)+checknull(caseobj.Contact.MailingCountry) +'\n'+ 
            'Phone:'+checknull(caseobj.ContactPhone)+'\n'+
            'Email:'+checknull(caseobj.ContactEmail)+'\n'+
            'Description:'+description;
        system.debug('des'+des);
        return des;
    }
    public static string checknull(string value){
        string returnvalue='';
        if(value !=null){
            returnvalue = value+', ';
        }
        return returnvalue;
    }
    public static string createServiceNowIncident(String payload, string endpoint,string method, String caseNumber) {
        String accessToken = getAccessToken();
        if(accessToken.contains('Error ')){
            return null;
        }
        HttpResponse res = new HttpResponse();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setBody(payload);
        Http http = new Http();
        try{
            res = http.send(req);
        } catch(System.CalloutException e) {
            errorCapture(e);
        }
        if(Test.isRunningTest()){
            return '{"result": {"number": "INC12345","task_effective_number":"INC12345", "sys_id": "1234567890"}}';
        }
        if (res.getStatusCode() != 201) {//res.getStatusCode() != 200 ||res.getStatusCode() != 201
            errorcalloutExceptionCapture(res, caseNumber);
            return 'Error ServiceNow OAuth authentication failed with status code ' + res.getStatusCode() + ' and message ' + res.getStatus() ;
        } else {
            System.debug('ServiceNow incident created successfully!'+res.getBody());
            return res.getBody();
        }
    }
    @Future(callout=true)
    public static void updateServiceNowIncident(String payload, string endpoint, string method,Blob blobvalue, String caseNumber ){
        HttpResponse res = new HttpResponse();
        Http https = new Http();
        HttpRequest req = setaccessTokenHeader();
        try{
            res = https.send(req);
        } catch(System.CalloutException e) {
            errorCapture(e);
        }
        String responseBody = res.getBody();
        if (res.getStatusCode() != 200) {//res.getStatusCode() != 200 ||res.getStatusCode() != 201
            errorcalloutExceptionCapture(res, caseNumber);
            System.debug('ServiceNow OAuth authentication failed with status code ' + res.getStatusCode() + ' and message ' + res.getStatus());
        }
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
        String accessToken = (String)responseMap.get('access_token');
        if(!accessToken.contains('Error ')){
            HttpResponse resp = new  HttpResponse();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod(method);
            request.setHeader('Authorization', 'Bearer ' + accessToken);
            if(blobvalue ==null){   
                
                request.setHeader('Content-Type', 'application/json');
                request.setHeader('Accept', 'application/json');
                request.setBody(payload);
            }else{
                
                request.setHeader('Content-Type', 'multipart/form-data'); 
                request.setBodyAsBlob(blobvalue);
            }
            Http http = new Http();
            try{
                resp = http.send(request);
            } catch(System.CalloutException e) {
                errorCapture(e);
            }
            if(blobvalue ==null && resp.getStatusCode() != 200 ){
                errorcalloutExceptionCapture(resp, caseNumber);
            }else if(blobvalue !=null && resp.getStatusCode() != 201){
                errorcalloutExceptionCapture(resp, caseNumber);
            }else if(blobvalue!=null && resp.getStatusCode() == 201){
                System.debug('File uploaded under ServiceNow incident successfully!'+resp.getBody());
            }
            else if(blobvalue ==null && resp.getStatusCode() == 200)
            {
                System.debug('ServiceNow incident updated successfully!'+resp.getBody());
            }
        }
        
    }
    // This method will be invoked when a file is uploaded.
    public static void uploadFile(List<ContentDocumentLink> newvalues){
        List<Web_Services_Credential__mdt> request = [
            SELECT Method_Type__c, Success_Code__c, Timeout__c, URL__c
            FROM Web_Services_Credential__mdt
            WHERE DeveloperName = 'Upload_File_ServiceNow_Incident'
        ];
        User integrationUserId = [SELECT Id from user where Name ='ServiceNow Integration'];
        for (ContentDocumentLink fileLink : newvalues) {
            if (fileLink.LinkedEntityId.getSObjectType() == case.SObjectType) {
                Case caseobj = [Select Id ,Comments,ServiceNow_State__c, Status, CaseNumber,Subject,Description,ServiceNow_Incident_ID__c,ServiceNow_Incident_Number__c from Case where Id =:fileLink.LinkedEntityId];
                if(caseobj.ServiceNow_Incident_ID__c !=null && caseobj.ServiceNow_Incident_Number__c !=null &&  caseobj.ServiceNow_State__c != 'Closed'){
                    // Retrieve the related ContentVersion record
                    ContentVersion contentVersion = [SELECT Id,CreatedById,FileExtension, VersionData,Title, FileType FROM ContentVersion WHERE ContentDocumentId = :fileLink.ContentDocumentId LIMIT 1];
                    String encodedFileName = EncodingUtil.urlEncode(contentVersion.Title+'.'+contentVersion.FileExtension, 'UTF-8');
                    string endpointUrl =request.get(0).URL__c+caseobj.ServiceNow_Incident_ID__c+'&file_name='+encodedFileName;                
                    system.debug('endpointUrl::'+endpointUrl);
                    if(contentVersion.CreatedById != integrationUserId.Id){
                        updateServiceNowIncident('',endpointUrl,request.get(0).Method_Type__c,contentVersion.VersionData, caseobj.CaseNumber);
                    }
                }
            }
        }
    }
    
    public static HttpRequest setaccessTokenHeader(){
        Org_Configuration__c mc = Org_Configuration__c.getOrgDefaults();
        List<Web_Services_Credential__mdt> request = [
            SELECT Method_Type__c, Success_Code__c, Timeout__c, URL__c
            FROM Web_Services_Credential__mdt
            WHERE DeveloperName = 'Authenticate_ServiceNow'
        ];
        String grantType = 'password';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(request.get(0).URL__c);
        req.setMethod(request.get(0).Method_Type__c);        
        //req.setTimeout(Integer.valueOf(request.get(0).Timeout__c));
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        String requestBody = 'grant_type=' + EncodingUtil.urlEncode(grantType, 'UTF-8') +
            '&client_id=' + EncodingUtil.urlEncode(mc.ServiceNow_ClientId__c, 'UTF-8') +
            '&client_secret=' + EncodingUtil.urlEncode(mc.ServiceNow_ClientSecret__c, 'UTF-8') +
            '&username=' + EncodingUtil.urlEncode(mc.ServiceNow_Username__c, 'UTF-8') +
            '&password=' + EncodingUtil.urlEncode(mc.ServiceNow_Password__c, 'UTF-8');
        system.debug('requestBody::'+requestBody);
        req.setBody(requestBody);
        return req;
    }
    public static  String getAccessToken() {
        HttpResponse res = new HttpResponse ();
        Http http = new Http();
        HttpRequest req = setaccessTokenHeader();
        try{
            res = http.send(req);
        } catch (System.CalloutException e) {
            errorCapture(e);
        }
        String responseBody = res.getBody();
        if (res.getStatusCode() != 200) {
            errorcalloutExceptionCapture(res,null);
            return 'Error ServiceNow OAuth authentication failed with status code ' + res.getStatusCode() + ' and message ' + res.getStatus() ;
        }
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
        String accessToken = (String)responseMap.get('access_token');
        return accessToken;
    }
    public static void errorCapture(Exception e){
        // // handle the exception and store the st_admin__Admin_Console_Debug__c Object 
        // st_admin__Admin_Console_Debug__c obj = new st_admin__Admin_Console_Debug__c();
        // obj.Name = e.getMessage();
        // string error = 'Error Message :'+e.getMessage()+'\n'+
        //     'Exception Type :'+e.getTypeName()+'\n'+
        //     'Stack Trace :'+e.getStackTraceString()+'\n'+
        //     'Line Number :'+e.getLineNumber()+'\n'+
        //     'Class Name :SNIntegrationService';
        // obj.st_admin__Debug_Log__c = error;
        
        // insert obj;
        // // string currentUserEmail = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId()].Email;
        // // sendEmail(obj.Name,obj.st_admin__Debug_Log__c,currentUserEmail);
        
        
    }
    public static void errorcalloutExceptionCapture(HttpResponse res, String caseNumber){ 
        // st_admin__Admin_Console_Debug__c obj = new st_admin__Admin_Console_Debug__c();
        // obj.Name = res.getStatus();
        // string error = 'Error Message for Case Number:'+caseNumber+'\n'+
        //     'Request:'+res.getBody()+'\n'+
        //     'Error Status :'+res.getStatus()+'\n'+
        //     'Status code :'+res.getStatusCode()+'\n'+
        //     'Class Name :SNIntegrationService';
        // obj.st_admin__Debug_Log__c = error;
        
        // insert obj;
        // // string currentUserEmail = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId()].Email;
        // // sendEmail(obj.Name,obj.st_admin__Debug_Log__c,currentUserEmail);
    }
    public static void sendEmail(string subject,string body, string emailaddress){
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();        
        // Create an email message
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{emailaddress});      
        email.setSubject(subject);   
        email.setPlainTextBody(body);
        emails.add(email);
        Messaging.sendEmail(emails);
        
    }
    
    
    public class PayloadWrapper {
        public ResultWrapper result;
    }
    
    public class ResultWrapper {
        public String sys_id;
        public String task_effective_number ;
        // add more fields as needed
    }
    public static void changeOwnerValidation(List<case> newvalues,Map<Id, Case> oldMapvalue){
        Group groupowner = [select Id , Name ,DeveloperName,  Type from Group where Type= 'Queue' AND DeveloperName ='Gigacomm_Support'];
        
        for(Case caseobj :newvalues ){
            Case oldvalue = oldMapvalue.get(caseobj.Id);
            if(caseobj.OwnerId ==groupowner.Id && caseobj.ServiceNow_Incident_Number__c !=Null && oldvalue.OwnerId != caseobj.OwnerId ){
                caseobj.addError('Please choose a different owner for NetOps incident.');
            }
        }
    }
    public class FlowInputs {
        
        @InvocableVariable
        public Id CaseId;
        
        @InvocableVariable
        public Boolean uploadFile;        
        
    }
}