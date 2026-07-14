/*
* Author: Bricoleur Technologies
* Created Date: June 23, 2023
* Description: Apex class for SellingDetail Flow Parameters 
*/
public class MYOB_FlowParam_BuyingDetail {
    
    @AuraEnabled @InvocableVariable public MYOB_FlowParam_TaxCode TaxCode;
    @AuraEnabled @InvocableVariable public MYOB_FlowParam_TaxCode FreightTaxCode;
    @AuraEnabled @InvocableVariable public String ABN;
    @AuraEnabled @InvocableVariable public String ShippingMethod;
    @AuraEnabled @InvocableVariable public String PurchaseLayout;
    @AuraEnabled @InvocableVariable public String PurchaseOrderDelivery;
}