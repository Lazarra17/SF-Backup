/*
 * Author: 			Bricoleur Technologies - Kristine Arcangel
 * Created Date: 	June 10, 2022
 * Description: 	Apex Class for Xero Outbound Item Request Body
 * Test Class: 		N/A
 * History:    		June 10, 2022 - Creation
*/
public class XeroReqFlowParamsItem {
    
    @AuraEnabled @InvocableVariable  public String ItemID;
    @AuraEnabled @InvocableVariable public String Name;
    @AuraEnabled @InvocableVariable public String Code;
    @AuraEnabled @InvocableVariable public String Description;
    @AuraEnabled @InvocableVariable public String PurchaseDescription;
    @AuraEnabled @InvocableVariable public String UpdatedDateUTC;
    @AuraEnabled @InvocableVariable public Boolean IsTrackedAsInventory;
    @AuraEnabled @InvocableVariable public Boolean IsSold;
    @AuraEnabled @InvocableVariable public Boolean IsPurchased;
    @AuraEnabled @InvocableVariable public XeroReqFlowParamsPurchaseSaleDetail PurchaseDetails;
    
    @AuraEnabled @InvocableVariable public XeroReqFlowParamsPurchaseSaleDetail SalesDetails;
    @AuraEnabled @InvocableVariable public String SalesforceID; 

}