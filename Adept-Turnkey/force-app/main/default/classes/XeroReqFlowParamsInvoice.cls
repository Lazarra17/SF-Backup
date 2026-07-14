/*
 * Author: 			Alfonso Maquilan
 * Created Date: 	May 14, 2021
 * Description: 	Apex Class for Xero Outbound Invoice Request Body
 * Test Class: 		XeroRequestTest
 * History:    		May 14, 2021 - Creation
*/
public class XeroReqFlowParamsInvoice 
{
	//Invoice
    @AuraEnabled @InvocableVariable public String SalesforceID;
    @AuraEnabled @InvocableVariable public String InvoiceType;
    @AuraEnabled @InvocableVariable public String InvoiceId;
    @AuraEnabled @InvocableVariable public String InvoiceContactId;
    @AuraEnabled @InvocableVariable public List<XeroReqFlowLineItemParams> LineItems;
    @AuraEnabled @InvocableVariable public String Date_x;
    @AuraEnabled @InvocableVariable public String DueDate;
    @AuraEnabled @InvocableVariable public String LineAmountTypes;
    @AuraEnabled @InvocableVariable public String InvoiceNumber;
    @AuraEnabled @InvocableVariable public String Reference;
    //@AuraEnabled @InvocableVariable public BrandingTheme
    @AuraEnabled @InvocableVariable public String URL;
    @AuraEnabled @InvocableVariable public String CurrencyCode;
    @AuraEnabled @InvocableVariable public String CurrencyRate;
    @AuraEnabled @InvocableVariable public String Status;
    @AuraEnabled @InvocableVariable public Boolean SentToContact;
    @AuraEnabled @InvocableVariable public String ExpectedPaymentDate;
    @AuraEnabled @InvocableVariable public String PlannedPaymentDate;
    @AuraEnabled @InvocableVariable public Boolean EmailToXero;
    @AuraEnabled @InvocableVariable public Boolean CreateContactInXero;
    @AuraEnabled @InvocableVariable public Boolean GetInvoiceAsPDF;
    @AuraEnabled @InvocableVariable public XeroReqFlowParamsContact Contact;
    @AuraEnabled @InvocableVariable public List<XeroReqFlowParamPayment> Payments;
}