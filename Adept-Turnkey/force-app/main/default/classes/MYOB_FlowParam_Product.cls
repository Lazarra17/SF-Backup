public class MYOB_FlowParam_Product {
    
    @AuraEnabled @InvocableVariable public String UID;
    @AuraEnabled @InvocableVariable public String Name;
    @AuraEnabled @InvocableVariable public String Number_x;
    @AuraEnabled @InvocableVariable public Boolean IsActive;
    @AuraEnabled @InvocableVariable public String Description;    
    @AuraEnabled @InvocableVariable public Decimal BaseSellingPrice;  
    @AuraEnabled @InvocableVariable public Boolean IsBought;
    @AuraEnabled @InvocableVariable public Boolean IsSold;
    @AuraEnabled @InvocableVariable public Boolean IsInventoried;
    @AuraEnabled @InvocableVariable public String RowVersion;
    @AuraEnabled @InvocableVariable public MYOB_FlowParam_Account IncomeAccount;
    @AuraEnabled @InvocableVariable public MYOB_FlowParam_Account ExpenseAccount;
    @AuraEnabled @InvocableVariable public MYOB_FlowParam_TaxCode BuyingDetails;
    @AuraEnabled @InvocableVariable public MYOB_FlowParam_TaxCode SellingDetails;
    @AuraEnabled @InvocableVariable public String SFID;  
    
    

}