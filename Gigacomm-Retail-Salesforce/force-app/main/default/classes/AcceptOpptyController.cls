/**
 * @description controller for GigaCommOrderReceived page
 * @author Bricoleur Technologies
 * @date May 29 2025
 */
public without sharing class AcceptOpptyController {

    @AuraEnabled
    public static void acceptOpp(String oppId) {

        if(String.isNotBlank(oppId) && oppId.startsWith('006')) {
            
            Opportunity updateOpp = new Opportunity(
                Id = oppId,
                Accepted_by_Client_Bric__c = true,
                Accepted_by_Client_Date_Bric__c = DateTime.now(),
                StageName = 'Won - Business (GC)'
            );

            try {
                update updateOpp;
            }
            catch(DmlException e) {
                System.debug(e.getMessage());
            }
        } 
    }
}