/*
* Author: Bricoleur Technologies
* Created Date: June 23, 2023
* Description: Apex class for Customer Flow Parameters 
*/

public class MYOB_FlowParam_Customer {
    
    @AuraEnabled @InvocableVariable public String UID;
    @AuraEnabled @InvocableVariable public String SupplierUID;
    @AuraEnabled @InvocableVariable public String LastName;
    @AuraEnabled @InvocableVariable public String FirstName;
    @AuraEnabled @InvocableVariable public Boolean IsIndividual;
    @AuraEnabled @InvocableVariable public String DisplayID;    
    @AuraEnabled @InvocableVariable public String CompanyName;  
    @AuraEnabled @InvocableVariable public MYOB_FlowParam_SellingDetail SellingDetails;   
    @AuraEnabled @InvocableVariable public MYOB_FlowParam_BuyingDetail BuyingDetails;  
    @AuraEnabled @InvocableVariable public String CompanyFileId;     
    @AuraEnabled @InvocableVariable public String AccountSFID;      
    @AuraEnabled @InvocableVariable public String AccountBillingSFID;      
    @AuraEnabled @InvocableVariable public String ProjectSFID;       
    @AuraEnabled @InvocableVariable public String ABN;     
    @AuraEnabled @InvocableVariable public String Notes;        
    @AuraEnabled @InvocableVariable public List<MYOB_FlowParam_Address> Addresses;  
    @AuraEnabled @InvocableVariable public String RowVersion;     
    @AuraEnabled @InvocableVariable public String AccountType;               
    @AuraEnabled @InvocableVariable public String ContactId;     

}