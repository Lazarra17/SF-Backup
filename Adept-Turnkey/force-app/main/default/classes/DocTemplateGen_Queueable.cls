/**
* @description Queueable class that generates document templates for NAO
* @author Bricoleur Technologies
* @date Aug-15-2024
* [1] JP Sulit 27 Feb 2025 Bulkify logic of PDF creation feature
* [2] JP Sulit 03 Mar 2025 Add null checker for req.docTemplates
*/

public class DocTemplateGen_Queueable implements Queueable, Database.AllowsCallouts {
    // The request list passed to the Queueable job
    private List<Invoke_DocTemplateGen.Request> requestList;
    
    /**
     * @description Constructor to pass the request list
     * @param requestList
     */
    public DocTemplateGen_Queueable(List<Invoke_DocTemplateGen.Request> requestList) {
        this.requestList = requestList;
    }
    
    /**
     * @description The execute method where the logic is run asynchronously
     * @param context
     */
    //[1] JP Sulit 27 Feb 2025 Bulkify logic of PDF creation feature
    //START
    public void execute(QueueableContext context) {

        List<ContentVersion> contentVersionsToInsert = new List<ContentVersion>();
        List<Database.SaveResult> saveResult = new List<Database.SaveResult>();
        Set<Id> recordIds = new Set<Id>();
        List<Exception> errorList = new List<Exception>();
        //Map<Id, Invoke_DocTemplateGen.Request> requestMap = new Map<Id, Invoke_DocTemplateGen.Request>();
        
        //System.debug('requestList feb 23 queueable '+requestList);

        if(!requestList.isEmpty()) {
            
            String qryFields = '';
            Map<Id, sObject> sObjectMap; 
            String objName;
            
            for(Invoke_DocTemplateGen.Request req : requestList) {
                
                //[2] JP Sulit 03 Mar 2025 Add null checker for req.docTemplates
                if(req.docTemplates != null && !req.docTemplates.isEmpty()) { //START
                    nao__Document_Template__c dt = req.docTemplates[0];
                    recordIds.add(req.recordId);

                    objName = DocTemplateGenUtil.getObjectNameById(req.recordId);

                    if(objName == dt.nao__sObject__c && String.isNotBlank(dt.nao__Title_Custom_Field__c)) { 
                        if(!qryFields.contains(dt.nao__Title_Custom_Field__c)){
                            qryFields += dt.nao__Title_Custom_Field__c+',';
                        }
                    }
                } //END
            }
            
            if(String.isNotBlank(qryFields)) {
                qryFields = qryFields.subString(0, qryFields.length() - 1);
                
                String objQry = 'SELECT '+qryFields+' FROM '+objName+' WHERE Id IN : recordIds';
                sObjectMap = new Map<Id, sObject>(Database.query(objQry));
            }
            
            // Step 1: Generate PDFs and create ContentVersion objects
            for (Invoke_DocTemplateGen.Request req : requestList) {
                try {
                    nao__Document_Template__c dt = req.docTemplates[0];
                    // Create a PageReference for the Visualforce page
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
                    
                } catch (Exception e) {
                    // Handle any exceptions
                    //System.debug('Error generating PDF for record ' + req.recordId + ': ' + e.getLineNumber() + e.getMessage());
                    errorList.add(e);
                }
            }

            if(errorList != null) {
                Utilities.CreateExceptionLog(errorList);
            }

            //System.debug('contentVersionsToInsert feb 25 '+contentVersionsToInsert);
            
            // Step 2: Insert all ContentVersions in bulk
            if (!contentVersionsToInsert.isEmpty()) {
                
                //try{
                    saveResult = Database.insert(contentVersionsToInsert, false);
                    Set<Id> cvIdSet = recordIdSet(saveResult);
                    
                    // Step 3: Create ContentDocumentLinks in bulk
                    List<ContentDocumentLink> contentDocumentLinksToInsert = new List<ContentDocumentLink>();
                    
                    String cvQry = SchemaHelper.getObjectQuery('ContentVersion', '') + ' WHERE Id IN : cvIdSet';
                    //System.debug('cvQry bric '+cvQry);
                    for (ContentVersion cv : Database.query(cvQry)) {
                        
                        ContentDocumentLink cdl = new ContentDocumentLink();
                        cdl.ContentDocumentId = cv.ContentDocumentId;
                        cdl.LinkedEntityId = cv.nao__Record_ID__c;
                        cdl.ShareType = 'V';
                        cdl.Visibility = 'AllUsers';
                        
                        // Collect ContentDocumentLink for bulk insertion
                        contentDocumentLinksToInsert.add(cdl);
                    }
                    
                    //System.debug('contentDocumentLinksToInsert feb 25 '+contentDocumentLinksToInsert);

                    // Step 4: Insert all ContentDocumentLinks in bulk
                    if (!contentDocumentLinksToInsert.isEmpty()) {
                        saveResult = new List<Database.SaveResult>();
                        saveResult = Database.insert(contentDocumentLinksToInsert, false);

                        Set<Id> cdlIdSet = recordIdSet(saveResult);
                        //System.debug('cdlIdSet feb 25 '+cdlIdSet);
                    }
                    
                //}catch(Exception e){
                    //Utilities.CreateExceptionLog(e);
                //}
            }
        }
    }

    /*public void execute(QueueableContext context) {
        List<ContentVersion> contentVersionsToInsert = new List<ContentVersion>();
        List<Database.SaveResult> saveResult = new List<Database.SaveResult>();
        Map<Id, Invoke_DocTemplateGen.Request> requestMap = new Map<Id, Invoke_DocTemplateGen.Request>();
        
        System.debug('requestList feb 23 queueable '+requestList);

        if(!requestList[0].docTemplates.isEmpty()) {
            
            Invoke_DocTemplateGen.Request req = requestList[0];
            String qryFields = '';
            Map<Id, sObject> sObjectMap; 
            system.debug('req DocTemplateGen_Queueable: ' + req);
            String objName = DocTemplateGenUtil.getObjectNameById(req.recordId);
            
            for(nao__Document_Template__c dt : requestList[0].docTemplates) {
                
                if(objName == dt.nao__sObject__c && String.isNotBlank(dt.nao__Title_Custom_Field__c)) { 
                    if(!qryFields.contains(dt.nao__Title_Custom_Field__c)){
                        qryFields += dt.nao__Title_Custom_Field__c+',';
                    }
                }
            }
            
            if(String.isNotBlank(qryFields)) {
                qryFields = qryFields.subString(0, qryFields.length() - 1);
                
                String objQry = 'SELECT '+qryFields+' FROM '+objName+' WHERE Id = \''+req.recordId+'\' LIMIT 1';
                sObjectMap = new Map<Id, sObject>(Database.query(objQry));
            }
            
            // Step 1: Generate PDFs and create ContentVersion objects
            for (nao__Document_Template__c dt : requestList[0].docTemplates) {
                try {
                    // Create a PageReference for the Visualforce page
                    String vfParam = dt.VisualForce_Template__c +'?Id='+req.recordId+'&sObjectType='+dt.nao__sObject__c+'&childSObjectType='+dt.nao__Child_sObject__c+'&pdfLogo='+dt.nao__Logo_Image_URL_Formula__c;
                    
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
                    
                    // Map ContentVersion to the Request recordId
                    requestMap.put(cv.Id, req);
                    
                } catch (Exception e) {
                    // Handle any exceptions (you may want to log these)
                    System.debug('Error generating PDF for record ' + req.recordId + ': ' + e.getLineNumber() + e.getMessage());
                    Utilities.CreateExceptionLog(e);
                }
            }

            System.debug('contentVersionsToInsert feb 25 '+contentVersionsToInsert);
            
            // Step 2: Insert all ContentVersions in bulk
            if (!contentVersionsToInsert.isEmpty()) {
                
                //try{
                    saveResult = Database.insert(contentVersionsToInsert, false);
                    Set<Id> cvIdSet = recordIdSet(saveResult);
                    
                    // Step 3: Create ContentDocumentLinks in bulk
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
                    
                    System.debug('contentDocumentLinksToInsert feb 25 '+contentDocumentLinksToInsert);

                    // Step 4: Insert all ContentDocumentLinks in bulk
                    if (!contentDocumentLinksToInsert.isEmpty()) {
                        saveResult = new List<Database.SaveResult>();
                        saveResult = Database.insert(contentDocumentLinksToInsert, false);

                        Set<Id> cdlIdSet = recordIdSet(saveResult);
                        System.debug('cdlIdSet feb 25 '+cdlIdSet);
                    }
                    
                //}catch(Exception e){
                    //Utilities.CreateExceptionLog(e);
                //}
            }
        }
    }*/
    //END
    
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