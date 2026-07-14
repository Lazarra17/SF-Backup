/*
@Author: Chad Lazarra(Bricoleur Technology)
@Date:
@Desc:
@History:  [1] Created
		   [2] Added a fix on the bug for multiple contact retrieved on SOQL 
*/
public without sharing class GigaCommPaymentController {
    
    
    @AuraEnabled
    public static Ezi_Debit_Setting__mdt getEziDebit(String enquiryId){
        Opportunity oppty = [SELECT Id, EziDebit_Reference_bric__c, AccountId,
                             Service_Address_Line1_bric__c, Service_Address_Line2_bric__c, Service_Level_Number_bric__c, Service_Level_Type_bric__c, Service_Street_Name_bric__c,
                             Service_Street_Number_bric__c, Service_Street_Number_Last_bric__c, Service_Street_Type_bric__c, Service_Unit_Number_bric__c, Service_Unit_Type_bric__c,
                             Service_Country_bric__c, Service_Postal_Code_bric__c, Service_State_bric__c, Service_City_bric__c
                             FROM Opportunity WHERE Id =: enquiryId];
        
        Contact con = [SELECT Id, FirstName, LastName, Email, MobilePhone
                       FROM Contact WHERE AccountId =: oppty.AccountId ORDER BY CreatedDate DESC LIMIT 1];
        
        Ezi_Debit_Setting__mdt eziDebit = [SELECT MasterLabel, Callback__c, Ezi_Debit_Url__c, Method__c, Secret_Key__c, Parameters__c FROM Ezi_Debit_Setting__mdt WHERE DeveloperName = 'EZ_Debit_Setting' LIMIT 1];
       
        
        String addressLine2 =  oppty.Service_Address_Line2_bric__c != null ? oppty.Service_Address_Line2_bric__c  : '' ;
        
        string Url = eziDebit.Ezi_Debit_Url__c + '?a=' + eziDebit.Secret_Key__c + eziDebit.Parameters__c +  '&cMethod=' + eziDebit.Method__c + '&callback=' + eziDebit.Callback__c;
        Url = Url + '&uref=' + oppty.EziDebit_Reference_bric__c;
        //Url = Url + '&noUref=1'; no CRM Reference
        Url = Url + '&fName=' + con.FirstName;
        Url = Url + '&lName=' + con.LastName;
        Url = Url + '&email=' + con.Email;
        Url = Url + '&mobile=' + con.MobilePhone;
        Url = Url + '&addr=' + oppty.Service_Address_Line1_bric__c;
        Url = Url + '&addr2=' + addressLine2;
        Url = Url + '&suburb=' + oppty.Service_City_bric__c;
        Url = Url + '&state=' + oppty.Service_State_bric__c;
        Url = Url + '&pCode=' + oppty.Service_Postal_Code_bric__c;
            
        eziDebit.Ezi_Debit_Url__c = Url;
        
        return eziDebit;
    }
    
    
}