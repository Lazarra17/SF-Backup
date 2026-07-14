public class DocTemplateGen_Batch implements Queueable, Database.AllowsCallouts {
    // The request list passed to the Queueable job
    private List<Invoke_DocTemplateGen_Batch.Request> requestList;
    
    // Constructor to pass the request list
    public DocTemplateGen_Batch(List<Invoke_DocTemplateGen_Batch.Request> requestList) {
        this.requestList = requestList;
    }  
    
    // The execute method where the logic is run asynchronously
    public void execute(QueueableContext context) {
        
        List<ContentVersion> contentVersionsToInsert = new List<ContentVersion>();
        List<Database.SaveResult> saveResults = new List<Database.SaveResult>();
        Map<Id, Invoke_DocTemplateGen.Request> requestMap = new Map<Id, Invoke_DocTemplateGen.Request>();
        Set<Id> recordIds = new Set<Id>(); 
        Set<Id> contactIds = new Set<Id>(); 
        Set<Id> contentDocLinksIds = new Set<Id>();
        Map<Id, Invoke_DocTemplateGen_Batch.Request> invoke_DocTemplateGenMap = new Map<Id, Invoke_DocTemplateGen_Batch.Request>();
        
        String qryFields = 'Id';
        Map<Id, sObject> sObjectMap;
        String objName;
        for(Invoke_DocTemplateGen_Batch.Request req : requestList){
            
            invoke_DocTemplateGenMap.put(req.recordId, req);
            recordIds.add(req.recordId);
            
            
            objName = DocTemplateGenUtil.getObjectNameById(req.recordId);
            
            nao__Document_Template__c dt = req.docTemplate;
            
            if(objName == dt.nao__sObject__c && String.isNotBlank(dt.nao__Title_Custom_Field__c)) { 
                if(!qryFields.contains(dt.nao__Title_Custom_Field__c)){
                    qryFields += ',' + dt.nao__Title_Custom_Field__c;
                }
            }
            
            if(DocTemplateGenUtil.getObjectNameById(req.targetObjectId) == 'Contact'){
                contactIds.add(req.targetObjectId);
            }
            
            
        }
        
        String objQry = 'SELECT '+qryFields+' FROM '+objName+' WHERE Id IN :recordIds';
        system.debug('objQry: ' + objQry);
        sObjectMap = new Map<Id, sObject>(Database.query(objQry));
        
        system.debug('sObjectMap: ' + sObjectMap.size());
        
        
        
        
        
        for(Invoke_DocTemplateGen_Batch.Request req : requestList){
            
            nao__Document_Template__c dt = req.docTemplate;
            
            
            String vfParam = dt.nao__VisualForce_Template__c +'?Id='+req.recordId+'&sObjectType='+dt.nao__sObject__c+'&childSObjectType='+dt.nao__Child_sObject__c+'&pdfLogo='+dt.nao__Logo_Image_URL_Formula__c;
            PageReference pdfPage = new PageReference('/apex/'+vfParam);
            // Render the page as a PDF
            Blob pdfBlob = !Test.isRunningTest() ? pdfPage.getContentAsPDF() : Blob.valueOf('Test');
            
            // Create a ContentVersion object for the PDF
            ContentVersion cv = new ContentVersion();
            cv.Title = dt.nao__Document_Title_Prefix__c;
            if(String.isNotBlank(dt.nao__Title_Custom_Field__c)) {
                if(!sObjectMap.isEmpty() && sObjectMap.containsKey(req.recordId)) {
                    cv.Title += ' - ' + sObjectMap.get(req.recordId).get(dt.nao__Title_Custom_Field__c);
                }
            }
            cv.PathOnClient = cv.Title+'.pdf';
            cv.VersionData = pdfBlob;
            cv.IsMajorVersion = true;
            cv.nao__Record_ID__c = req.recordId;
            
            // Collect ContentVersion for bulk insertion
            contentVersionsToInsert.add(cv);
            
            
        }
        
        // Step 2: Insert all ContentVersions in bulk
        if (!contentVersionsToInsert.isEmpty()) {
            try{
                // Step 3: Create ContentDocumentLinks in bulk
                saveResults = Database.insert(contentVersionsToInsert, false);
                Set<Id> cvIdSet = recordIdSet(saveResults);
                system.debug('cvIdSet: ' + cvIdSet);
                
                List<ContentDocumentLink> contentDocumentLinksToInsert = new List<ContentDocumentLink>();
                
                String cvQry = SchemaHelper.getObjectQuery('ContentVersion', '') + ' WHERE Id IN : cvIdSet';
                System.debug('cvQry bric '+cvQry);
                for (ContentVersion cv : Database.query(cvQry)) {
                    
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.ContentDocumentId = cv.ContentDocumentId;
                    cdl.LinkedEntityId = cv.nao__Record_ID__c;
                    cdl.ShareType = 'V';
                    cdl.Visibility = 'AllUsers';
                    
                    // Collect ContentDocumentLink for bulk insertion
                    contentDocumentLinksToInsert.add(cdl);
                }
                
                // Step 4: Insert all ContentDocumentLinks in bulk
                if (!contentDocumentLinksToInsert.isEmpty()) {
                    saveResults = new List<Database.SaveResult>();
                    saveResults = Database.insert(contentDocumentLinksToInsert, false);
                    
                    
                    for(Database.SaveResult sr : saveResults)                       
                    {
                        if (sr.isSuccess()){
                            contentDocLinksIds.add(sr.getId());
                        }
                        else {
                            for(Database.Error err : sr.getErrors()) {
                                System.debug('Error message:' + err.getMessage());
                            }
                        }
                    }
                    
                }
            }catch(Exception e){
                Utilities.CreateExceptionLog(e);
            }
            
            
            if(contentDocLinksIds.size() > 0){
                Map<Id,Contact> contactMap = DocTemplateGenUtil.getContactMapToSendInvoice(contactIds);
                
                List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
                for(ContentDocumentLink cdl : [SELECT Id,LinkedEntityId, ContentDocument.LatestPublishedVersionId FROM ContentDocumentLink WHERE Id IN : contentDocLinksIds]){
                    
                    //Check if Account has Automatically_Send_Invoices_bric__c TRUE
                    if(contactMap.containsKey(invoke_DocTemplateGenMap.get(cdl.LinkedEntityId).targetObjectId)){
                        
                        //Create SendEmailMessage
                        if(invoke_DocTemplateGenMap.containsKey(cdl.LinkedEntityId)){
                            
                            
                            if(invoke_DocTemplateGenMap.get(cdl.LinkedEntityId)?.setToAddrList?.size() > 0 && invoke_DocTemplateGenMap.get(cdl.LinkedEntityId).targetObjectId != ''){
                                
                                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                                List<Id> files = new List<Id>();
                                files.add(cdl.ContentDocument.LatestPublishedVersionId);
                                //Recipient
                                mail.setToAddresses(invoke_DocTemplateGenMap.get(cdl.LinkedEntityId).setToAddrList);
                                
                                //Sender
                                if(!String.isBlank(invoke_DocTemplateGenMap.get(cdl.LinkedEntityId).orgWideEmailId)){
                                    mail.setOrgWideEmailAddressId(invoke_DocTemplateGenMap.get(cdl.LinkedEntityId).orgWideEmailId);
                                }
                                else{
                                    mail.setSenderDisplayName(invoke_DocTemplateGenMap.get(cdl.LinkedEntityId).senderDisplayName);
                                }
                                
                                mail.setReplyTo(invoke_DocTemplateGenMap.get(cdl.LinkedEntityId).replyTo);
                                
                                
                                
                                //Attachment
                                mail.setEntityAttachments(files);
                                
                                //Related record Id
                                mail.setWhatId(cdl.LinkedEntityId);
                                
                                //Target object record Id (Contact, Lead, User)
                                mail.setTargetObjectId(invoke_DocTemplateGenMap.get(cdl.LinkedEntityId).targetObjectId);
                                
                                //Save email to activity
                                
                                mail.setSaveAsActivity(invoke_DocTemplateGenMap.get(cdl.LinkedEntityId).saveAsActivity);
                                
                                //Email Tempalte OR Subject and body
                                
                                if(invoke_DocTemplateGenMap.get(cdl.LinkedEntityId).emailTemplateId != null){
                                    system.debug('emailTemplateId: ' + invoke_DocTemplateGenMap.get(cdl.LinkedEntityId).emailTemplateId);
                                    mail.setTemplateId(invoke_DocTemplateGenMap.get(cdl.LinkedEntityId).emailTemplateId);
                                }else{
                                    system.debug('Body: ' + invoke_DocTemplateGenMap.get(cdl.LinkedEntityId).body);
                                    system.debug('subject: ' + invoke_DocTemplateGenMap.get(cdl.LinkedEntityId).subject);
                                    mail.setSubject(invoke_DocTemplateGenMap.get(cdl.LinkedEntityId).subject);
                                    mail.setHtmlBody(invoke_DocTemplateGenMap.get(cdl.LinkedEntityId).body);
                                }
                                
                                
                                
                                mails.add(mail);
                            }
                            
                        }
                    }
                    
                    
                    
                }
                
                //Send email
                if(mails.size() > 0){
                    Messaging.SendEmailResult[] sendResults =
                        Messaging.sendEmail(mails, false);
                    
                    
                    
                    for(Messaging.SendEmailError error : sendResults[0].getErrors()){
                        Utilities.CreateExceptionLog(error);
                        system.debug(error.getMessage());
                        system.debug('Fields: ' + error.getFields());
                    }
                    
                }
            }
            
        }
    }
    
    
    
    private Set<Id> recordIdSet(List<Database.SaveResult> saveResult) {
        
        Set<Id> idSet = new Set<Id>();
        for(Database.SaveResult sr : saveResult) {
            if(sr.isSuccess()) {
                idSet.add(sr.getId());
            }
        }
        return idSet;
    }
}