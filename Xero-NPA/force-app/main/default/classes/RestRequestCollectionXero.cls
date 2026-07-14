/*
 * Author: 			Alfonso Maquilan
 * Created Date: 	May. 06, 2021
 * Description: 	Collection class for Rest Body Request for Xero Integrations
 * Test Class:  	N/A
 * History: 		May 06, 2021 - Creation
 */
public class RestRequestCollectionXero 
{
	//Post Contact
    public class PostXeroContact
    {
        public String Name;
        public String ContactID;
        public String ContactNumber;
        public String AccountNumber;
        public String ContactStatus;
        public String FirstName;
        public String LastName;
        public String EmailAddress;
        public String SkypeUserName;
        public String BankAccountDetails;
        public String TaxNumber;
        public String AccountsReceivableTaxType;
        public String AccountsPayableTaxType;
        public List<Address> Addresses;
        public List<Phone> Phones;
        public Boolean IsSupplier;
        public Boolean IsCustomer;
        public String DefaultCurrency;
        public String XeroNetworkKey;
        public String SalesDefaultAccountCode;
        public String PurchasesDefaultAccountCode;
        public String SalesTrackingCategories;
        public String PurchasesTrackingCategories;
        public String TrackingCategoryName;
        public PaymentTerm PaymentTerms;
    }
    
    public class PaymentTerm{
        
        public BillSalesPaymentTerm Bills;
        public BillSalesPaymentTerm Sales;
    }
    
    Public class BillSalesPaymentTerm{
        public Integer Day;
        public String Type_x;
    }
    
    public class Address
    {
        public String AddressType;
        public String AddressLine1;
        public String City;
        public String Region;
        public String PostalCode;
        public String Country;
    }
    
    public class Phone
    {
        public String PhoneType;
        public String PhoneNumber;
        public String PhoneAreaCode;
        public String PhoneCountryCode;
    }
    
    //Post Invoice
    public class PostInvoiceBody
    {
        public List<Invoice> Invoices;
    }
    
    public class Invoice
    {
        public String Reference;
        public String Type_x;
        public XeroContact Contact;
        public String Date_x;
        public String DueDate;
        public String LineAmountTypes;
        public List<XeroLineItem> LineItems;
        public String Url; 
        public String CurrencyCode;
        public String CurrencyRate;
        public String Status;
        public String InvoiceID;
        public Boolean SentToContact; 
        public String InvoiceNumber;	
        public String ExpectedPaymentDate; 
        public String PlannedPaymentDate; 
    }

    //Post PurchaseOrder
    public class PostPurchaseOrderBody
    {
        public List<PurchaseOrder> PurchaseOrders;
    }
    
     public class PurchaseOrder
    {
        public String Reference;
        public PurchaseOrderXeroContact Contact;
        public String Date_x;
        public String DeliveryDate;
        public String LineAmountTypes;
        public List<XeroLineItem> LineItems;
        public String CurrencyCode;
        public String CurrencyRate;
        public String Status;
        public String PurchaseOrderID;
        public String PurchaseOrderNumber;
    }

     public class PurchaseOrderXeroContact
    {
        public String ContactID;
    }

    
    public class XeroContact
    {
        public String ContactID;
    }
    
    public class XeroLineItem
    {
        public String LineItemID;
        public String Description;
        public String Quantity;
        public String UnitAmount;
        public String AccountCode;
        public String TaxType; 
        public String TaxAmount; 
        public String LineAmount; 
        public String DiscountRate; 
        public String ItemCode;
    }

     //Post Quote
     public class PostQuoteBody
     {
         public Quote Quote;
     }
 
     public class Quote
     {
        public XeroContact Contact;
        public String Date_x;
        public String ExpiryDate;
        public String Status;
        public String LineAmountTypes;
        public List<XeroLineItem> LineItems;
        public Decimal SubTotal;
        public Decimal TotalTax;
        public Decimal Total;
        public Decimal TotalDiscount;
        public String UpdatedDateUTC;
        public String CurrencyCode;
        public String CurrencyRate;
        public String QuoteID;
        public String QuoteNumber;
        public String Reference;
        public String Title;
        public String Summary;
        public String Terms;        
     }
    
    public class Item
    {
        public String ItemID;
        public String Name;
        public String Code;
        public String Description;
        public String PurchaseDescription;
        public String UpdatedDateUTC;
        public Boolean IsTrackedAsInventory;
        public Boolean IsSold;
        public Boolean IsPurchased;
        public PurchaseSalesDetails PurchaseDetails;
        public PurchaseSalesDetails SalesDetails;        
    }
    
     public class PurchaseSalesDetails
    {
        public Decimal UnitPrice;
        public String AccountCode;
        public String TaxType;
    }
    
    //PUT PAYMENT
    public class PutPaymentBody{
        public List<Payment> Payments;
        
    }
    
    public class Payment{        
        public Invoice Invoice;
        public String PaymentID;
        public String Date_x;
        public Decimal Amount;
        public XeroReqFlowParamAccount Account;
        
    }
}