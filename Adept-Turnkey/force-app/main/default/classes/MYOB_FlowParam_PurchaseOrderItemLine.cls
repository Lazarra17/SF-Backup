/*
* @Author: Bricoleur Technology
* @Date: March 5, 2026
* @Desc:
*
*/
public class MYOB_FlowParam_PurchaseOrderItemLine {
    
    
    @AuraEnabled @InvocableVariable public String RowID;
    //public String Type; // 'Type' is a reserved keyword
    @AuraEnabled @InvocableVariable public String Description;
    @AuraEnabled @InvocableVariable public Decimal BillQuantity;
    @AuraEnabled @InvocableVariable public Decimal ReceivedQuantity;
    @AuraEnabled @InvocableVariable public Decimal BackorderQuantity;
    @AuraEnabled @InvocableVariable public Decimal UnitPrice;
    @AuraEnabled @InvocableVariable public Decimal UnitPriceForeign;
    @AuraEnabled @InvocableVariable public Decimal Total;
    @AuraEnabled @InvocableVariable public MYOB_FlowParam_Item Item;
    @AuraEnabled @InvocableVariable public MYOB_FlowParam_TaxCode TaxCode;
    @AuraEnabled @InvocableVariable public MYOB_FlowParam_Location Location;
    @AuraEnabled @InvocableVariable public String RowVersion;
    
    
    
    
}