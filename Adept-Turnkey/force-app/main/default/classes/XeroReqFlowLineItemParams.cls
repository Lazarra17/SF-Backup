/*
 * Author: 			Alfonso Maquilan
 * Created Date: 	May 14, 2021
 * Description: 	Apex Class for Xero Outbound Invoice Line Items Request Body
 * Test Class: 		N/A
 * History:    		May 14, 2021 - Creation
*/
public class XeroReqFlowLineItemParams 
{
    @AuraEnabled @InvocableVariable public String Description;
    @AuraEnabled @InvocableVariable public String Quantity;
    @AuraEnabled @InvocableVariable public String UnitAmount;
    @AuraEnabled @InvocableVariable public String AccountCode;
    @AuraEnabled @InvocableVariable public String LineItemId;
    @AuraEnabled @InvocableVariable public String TaxType;
    @AuraEnabled @InvocableVariable public String TaxAmount;
    @AuraEnabled @InvocableVariable public String LineAmount;
    @AuraEnabled @InvocableVariable public String DiscountRate;
    @AuraEnabled @InvocableVariable public String ItemCode;
    //@AuraEnabled @InvocableVariable public String Tracking;
}