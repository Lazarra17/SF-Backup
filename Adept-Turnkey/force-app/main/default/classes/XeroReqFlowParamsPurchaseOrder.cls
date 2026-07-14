/*
 * Author: 			Kristine Arcangel
 * Created Date: 	September 28, 2022
 * Description: 	Apex Class for Xero Outbound Purchase Order Request Body
 * Test Class: 		XeroRequestTest
 * History:    		September 28, 2022 - Creation
 *                  July 18, 2024 - Added variable that accepts PurchaseOrderNumber (jp@bricoleurtech.com)
*/
public class XeroReqFlowParamsPurchaseOrder 
{
	//Invoice
    @AuraEnabled @InvocableVariable public String SalesforceID;
    @AuraEnabled @InvocableVariable public String PurchaseOrderID;
    @AuraEnabled @InvocableVariable public String ContactId;
    @AuraEnabled @InvocableVariable public List<XeroReqFlowLineItemParams> LineItems;
    @AuraEnabled @InvocableVariable public String Date_x;
    @AuraEnabled @InvocableVariable public String DeliveryDate;
    @AuraEnabled @InvocableVariable public String LineAmountTypes;
    @AuraEnabled @InvocableVariable public String Reference;
    @AuraEnabled @InvocableVariable public String CurrencyCode;
    @AuraEnabled @InvocableVariable public String CurrencyRate;
    @AuraEnabled @InvocableVariable public String Status;
    @AuraEnabled @InvocableVariable public String PurchaseOrderNumber;
}