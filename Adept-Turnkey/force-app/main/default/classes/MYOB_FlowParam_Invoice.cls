/*
* Author: Bricoleur Technologies
* Created Date: Feb 25, 2025
* Description: Apex class for Invoice TimeBilling Flow Parameters 
*/
public class MYOB_FlowParam_Invoice {
    
    @AuraEnabled @InvocableVariable public String UID; //required
    @AuraEnabled @InvocableVariable public String Number_x;
    @AuraEnabled @InvocableVariable public Date Date_x; //required
    @AuraEnabled @InvocableVariable public Boolean IsTaxInclusive;
    @AuraEnabled @InvocableVariable public String CustomerPurchaseOrderNumber;
    @AuraEnabled @InvocableVariable public MYOB_FlowParam_SalesOrder Order;
    @AuraEnabled @InvocableVariable public MYOB_FlowParam_Customer Customer;
    @AuraEnabled @InvocableVariable public List<MYOB_FlowParam_SalesOrderLines> Lines;
    @AuraEnabled @InvocableVariable public String SFInvoiceId;

}