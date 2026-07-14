/*
 * Author: 			Kristine Arcangel
 * Created Date: 	July 22, 2021
 * Description: 	Apex Class for Xero Outbound Quote Request Body
 * Test Class: 		
 * History:    		July 22, 2021 - Creation
*/
public class XeroReqFlowParamsQuote 
{
    @InvocableVariable public String Date_x;
    @InvocableVariable public String ExpiryDate;
    @InvocableVariable public String Status;
    @InvocableVariable public String LineAmountTypes;
    @InvocableVariable public List<XeroReqFlowLineItemParams> LineItems;
    @InvocableVariable public Decimal SubTotal;
    @InvocableVariable public Decimal TotalTax;
    @InvocableVariable public Decimal Total;
    @InvocableVariable public Decimal TotalDiscount;
    @InvocableVariable public String CurrencyCode;
    @InvocableVariable public String QuoteID;
    @InvocableVariable public String QuoteNumber;
    @InvocableVariable public String Reference;
    @InvocableVariable public String Title;
    @InvocableVariable public String Summary;
    @InvocableVariable public String Terms;
    @InvocableVariable public String SalesforceRecordId;
    @InvocableVariable public String QuoteContactID;
}