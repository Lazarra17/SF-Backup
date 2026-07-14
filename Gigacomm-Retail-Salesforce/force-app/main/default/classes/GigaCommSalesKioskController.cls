public without sharing class GigaCommSalesKioskController {
    
    
  
    
    @AuraEnabled
    public static Lead createLead(String kioskId, String agentCode){
        Kiosk_Bric__c kiosk;
        if(kioskId != null){
            kiosk = [SELECT Id FROM Kiosk_Bric__c WHERE Id =: kioskId];
        }
        
        Lead l = new Lead();
        l.LastName = 'TBA';
        l.Company = 'TBA';
        l.Agent_Code_bric__c = agentCode;
        l.Kiosk_bric__c = kiosk?.Id;
        insert l;
        return l;
    }

}