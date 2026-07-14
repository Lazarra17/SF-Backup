/*
 * Author: 			Alfonso Maquilan
 * Created Date: 	May 11, 2021
 * Description: 	Apex Class for Xero Outbound Contact Request Body
 * Test Class: 		N/A
 * History:    		May 11, 2021 - Creation
 * 					May 14, 2021 - Segmented Invoice and Invoice Line Item request bodies.
 * 					Aug. 26, 2021 - Added Billing Address fields.
*/
public class XeroReqFlowParamsContact 
{
	//Contact
	@AuraEnabled @InvocableVariable public Account AccountRecord;
    @AuraEnabled @InvocableVariable public String RecordId;
    @AuraEnabled @InvocableVariable public String SearchParameter;
    @AuraEnabled @InvocableVariable public String SearchParameterValue;
    @AuraEnabled @InvocableVariable public String Name;
    @AuraEnabled @InvocableVariable public String ContactID;
    @AuraEnabled @InvocableVariable public String ContactNumber;
    @AuraEnabled @InvocableVariable public String AccountNumber;
    @AuraEnabled @InvocableVariable public String ContactStatus;
    @AuraEnabled @InvocableVariable public String FirstName;
    @AuraEnabled @InvocableVariable public String LastName;
    @AuraEnabled @InvocableVariable public String EmailAddress;
    @AuraEnabled @InvocableVariable public String SkypeUserName;
    @AuraEnabled @InvocableVariable public String BankAccountDetails;
    @AuraEnabled @InvocableVariable public String TaxNumber;
    @AuraEnabled @InvocableVariable public String AccountsReceivableTaxType;
    @AuraEnabled @InvocableVariable public String AccountsPayableTaxType;
    @AuraEnabled @InvocableVariable public String ShippingStreet;
    @AuraEnabled @InvocableVariable public String ShippingCity;
    @AuraEnabled @InvocableVariable public String ShippingState;
    @AuraEnabled @InvocableVariable public String ShippingPostalCode;
    @AuraEnabled @InvocableVariable public String ShippingCountry;
    @AuraEnabled @InvocableVariable public String BillingStreet;
    @AuraEnabled @InvocableVariable public String BillingCity;
    @AuraEnabled @InvocableVariable public String BillingState;
    @AuraEnabled @InvocableVariable public String BillingPostalCode;
    @AuraEnabled @InvocableVariable public String BillingCountry;
    @AuraEnabled @InvocableVariable public String Phone;
    @AuraEnabled @InvocableVariable public String Fax;
    @AuraEnabled @InvocableVariable public String Mobile;
    @AuraEnabled @InvocableVariable public Boolean IsSupplier;
    @AuraEnabled @InvocableVariable public Boolean IsCustomer;
    @AuraEnabled @InvocableVariable public String DefaultCurrency;
    @AuraEnabled @InvocableVariable public String XeroNetworkKey;
    @AuraEnabled @InvocableVariable public String SalesDefaultAccountCode;
    @AuraEnabled @InvocableVariable public String PurchasesDefaultAccountCode;
    @AuraEnabled @InvocableVariable public String SalesTrackingCategories;
    @AuraEnabled @InvocableVariable public String PurchasesTrackingCategories;
    @AuraEnabled @InvocableVariable public String TrackingCategoryName;
    @AuraEnabled @InvocableVariable public XeroReqFlowParamsPaymentTerm PaymentTerms;
}