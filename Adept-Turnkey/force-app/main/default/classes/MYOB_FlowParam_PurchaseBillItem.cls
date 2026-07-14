public class MYOB_FlowParam_PurchaseBillItem {
    
    @AuraEnabled @InvocableVariable public String UID; //required
    @AuraEnabled @InvocableVariable public String OrderNumber;
    @AuraEnabled @InvocableVariable public Date Date_x; //required
    @AuraEnabled @InvocableVariable public MYOB_FlowParam_Supplier Supplier;
    @AuraEnabled @InvocableVariable public String ShipToAddress;
    @AuraEnabled @InvocableVariable public Boolean IsTaxInclusive;
    @AuraEnabled @InvocableVariable public List<MYOB_FlowParam_PurchaseOrderItemLine> Lines;
    @AuraEnabled @InvocableVariable public String BillDeliveryStatus; 
    @AuraEnabled @InvocableVariable public String Status; 
    @AuraEnabled @InvocableVariable public MYOB_FlowParam_TaxCode FreightTaxCode;
    @AuraEnabled @InvocableVariable public MYOB_FlowParam_SalesOrder Order;
    @AuraEnabled @InvocableVariable public String SFID; 
    @AuraEnabled @InvocableVariable public String RowVersion; 
    
}