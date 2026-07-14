public class MYOB_FlowParam_Address {

   
    @AuraEnabled @InvocableVariable public Integer Location; 
    @AuraEnabled @InvocableVariable public String Street; //(255)
    @AuraEnabled @InvocableVariable public String City; //(255)
    @AuraEnabled @InvocableVariable public String State; // (255)
    @AuraEnabled @InvocableVariable public String PostCode; // (11)
    @AuraEnabled @InvocableVariable public String Country; // (255)
    @AuraEnabled @InvocableVariable public String Phone1; // (21)
    @AuraEnabled @InvocableVariable public String Phone2; // (21)
    @AuraEnabled @InvocableVariable public String Phone3; // (21)
    @AuraEnabled @InvocableVariable public String Fax; // (21)
    @AuraEnabled @InvocableVariable public String Email; // (255)
    @AuraEnabled @InvocableVariable public String Website; //(255)
    @AuraEnabled @InvocableVariable public String ContactName; // 25
    @AuraEnabled @InvocableVariable public String Salutation; // 15
    
    
}