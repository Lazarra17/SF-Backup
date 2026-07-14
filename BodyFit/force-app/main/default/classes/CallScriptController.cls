public with sharing class CallScriptController {

    @AuraEnabled(cacheable=true)
    public static List<Call_Script__c> getCallScripts(String leadId) {
        // Query Call Scripts ordered by sequence
        List<Call_Script__c> callScripts = [SELECT Id, Name, Script_Content__c, Category__c, Sequence__c 
                                            FROM Call_Script__c 
                                            WHERE Category__c != null 
                                            ORDER BY Sequence__c];
        
        return callScripts;
    }
}