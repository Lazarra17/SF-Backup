public class UploadBulKFiles {
    
    @InvocableMethod(label='Upload Bulk File' description='call service Now system to upload Buil file')
    public static void invokeServiceNowUploadFiles(List<String> inputs) {
        try{
            String caseId = inputs[0];            
            Case caseobj = [Select Id ,Comments,ServiceNow_State__c, Status, CaseNumber,Subject,Description,ServiceNow_Incident_ID__c,ServiceNow_Incident_Number__c, (SELECT ContentDocumentId,LinkedEntityId, Id  FROM ContentDocumentLinks) FROM Case where Id =:caseId];
            List<Web_Services_Credential__mdt> request = [
                SELECT Method_Type__c, Success_Code__c, Timeout__c, URL__c
                FROM Web_Services_Credential__mdt
                WHERE DeveloperName = 'Upload_File_ServiceNow_Incident'
            ];
            for (ContentDocumentLink fileLink : caseobj.ContentDocumentLinks) {
                if (fileLink.LinkedEntityId.getSObjectType() == case.SObjectType && caseobj.ServiceNow_Incident_ID__c !=null && caseobj.ServiceNow_Incident_Number__c !=null &&  caseobj.ServiceNow_State__c != 'Closed') {
                    ContentVersion contentVersion = [SELECT Id, VersionData,Title,ContentVersion.FileExtension, FileType FROM ContentVersion WHERE ContentDocumentId = :fileLink.ContentDocumentId LIMIT 1];
                    String encodedFileName = EncodingUtil.urlEncode(contentVersion.Title+'.'+contentVersion.FileExtension, 'UTF-8');
                    string endpointUrl =request.get(0).URL__c+caseobj.ServiceNow_Incident_ID__c+'&file_name='+encodedFileName;                
                    SNIntegrationService.updateServiceNowIncident('',endpointUrl,request.get(0).Method_Type__c,contentVersion.VersionData, caseobj.CaseNumber);     
                }
            }
        }
        catch(Exception e) {
            SNIntegrationService.errorCapture(e);
        }
    }
    
}