/*
* Author: Bricoleur Technologies
* Created Date: November 22, 2021
* Description: Apex class for Invoice TimeBilling Flow Parameters 
*/
public class MYOB_FlowParam_SalesOrder {
	
    
    @AuraEnabled @InvocableVariable public String UID; //required
    @AuraEnabled @InvocableVariable public Date Date_x; //required
    @AuraEnabled @InvocableVariable public String CustomerPurchaseOrderNumber;
    @AuraEnabled @InvocableVariable public MYOB_FlowParam_Customer Customer;
    @AuraEnabled @InvocableVariable public List<MYOB_FlowParam_SalesOrderLines> Lines;
    @AuraEnabled @InvocableVariable public Boolean IsTaxInclusive;
    @AuraEnabled @InvocableVariable public String SFID; //required
    @AuraEnabled @InvocableVariable public String CustomerUID; 
    @AuraEnabled @InvocableVariable public String ShipToAddress;
    @AuraEnabled @InvocableVariable public MYOB_FlowParam_ForeignCurrency ForeignCurrency;
}