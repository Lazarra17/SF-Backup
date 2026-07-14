public without sharing class GigacommContactUsController{
    
    @AuraEnabled
    public static Lead createLead(String lead){
        String recordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Commercial_Lead').getRecordTypeId();
        Lead l = (Lead)JSON.deserialize(lead, Lead.class);
        l.RecordTypeId = recordTypeId;
        
        system.debug(lead);
        insert l;
        
        
        return l;
        
    }
    
}