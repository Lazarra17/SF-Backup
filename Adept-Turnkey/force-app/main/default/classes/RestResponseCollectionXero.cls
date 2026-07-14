/*
 * Author:          Alfonso Maquilan
 * Created Date:    May. 04, 2021
 * Description:     Collection class for Rest Body Response for Xero Integrations
 * Test Class:      N/A
 * History:         May 04, 2021 - Creation
 */
public class RestResponseCollectionXero
{
    //Get Connection
    public class XeroTenantIdResponseBody
    {
        public String id;
        public String authEventId;
        public String tenantId;
        public String tenantType;
        public String tenantName;
        public String createdDateUtc;
        public String updatedDateUtc;
    }
    
    //Get Contact
    public class GetContactResponseBody
    {
        public String Id;
        public String Status;
        public String ProviderName;
        public String DateTimeUTC;
        public List<XeroContact> Contacts;
    }
    
    //Get Invoice
    public class GetInvoiceResponseBody
    {
        public String Id;
        Public String Status;
        public String ProviderName;
        public String DateTimeUTC;
        public List<Invoice> Invoices;
    }
    
    //Get Quote
    public class GetQuoteResponseBody
    {
        public String Id;
        Public String Status;
        public String ProviderName;
        public String DateTimeUTC;
        public List<Quote> Quotes;
    }

    //Post Contact
    public class PostContactResponseBody
    {   
        public String Id;
        public String Status;
        public String ProviderName;
        public String DateTimeUTC;
        public List<XeroContact> Contacts;
    }
    
    public class XeroContact
    {
        public String ContactID;
        public String ContactNumber;
        public String AccountNumber;
        public String ContactStatus;
        public String Name;
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
        public String TrackingCategoryName;
        public PaymentTerm PaymentTerms;
        public String UpdatedDateDTC;
        public List<ContactGroup> ContactGroups;
        public List<SalesTrackingCategory> SalesTrackingCategories;
        public List<PurchasesTrackingCategory> PurchasesTrackingCategories;
        public List<ContactPerson> ContactPersons;
        public Boolean HasValidationErrors;
        
        public Object GetField(String fieldToGet)
        {
            Address poboxAddress;
            Address address;
            String phone;
            String fax;
            String mobile;
            
            if(this.Addresses != NULL){
                address = XeroStructureSearch.SearchXeroAddress(this.Addresses, CONSTANTS_BRIC.INTEGRATION_XERO_ADDRESS_ADDRESS_TYPE_STREET);
                poboxAddress = XeroStructureSearch.SearchXeroAddress(this.Addresses, CONSTANTS_BRIC.INTEGRATION_XERO_ADDRESS_ADDRESS_TYPE_POBOX);
            }
            if(this.Phones != NULL){
                phone = XeroStructureSearch.SearchXeroPhone(this.Phones , CONSTANTS_BRIC.INTEGRATION_XERO_PHONE_PHONE_TYPE_DEFAULT)?.PhoneNumber;
                fax = XeroStructureSearch.SearchXeroPhone(this.Phones , CONSTANTS_BRIC.INTEGRATION_XERO_PHONE_PHONE_TYPE_FAX)?.PhoneNumber;
                mobile = XeroStructureSearch.SearchXeroPhone(this.Phones , CONSTANTS_BRIC.INTEGRATION_XERO_PHONE_PHONE_TYPE_MOBILE)?.PhoneNumber;
            }

            Switch on fieldToGet
            {
                When 'ContactID'                    {return this.ContactId;}
                When 'ContactNumber'                {return this.ContactNumber;}
                When 'AccountNumber'                {return this.AccountNumber;}
                When 'ContactStatus'                {return this.ContactStatus;}
                When 'Name'                         {return this.Name;}
                When 'FirstName'                    {return this.FirstName;}
                When 'LastName'                     {return this.LastName;}
                When 'EmailAddress'                 {return this.EmailAddress;}
                When 'SkypeUserName'                {return this.SkypeUserName;}
                When 'BankAccountDetails'           {return this.BankAccountDetails;}
                When 'TaxNumber'                    {return this.TaxNumber;}
                When 'AccountsReceivableTaxType'    {return this.AccountsReceivableTaxType;}
                When 'AccountsPayableTaxType'       {return this.AccountsPayableTaxType;}
                When 'AddressLine1'                 {return address?.AddressLine1;}
                When 'City'                         {return address?.City;}
                When 'Region'                       {return address?.Region;}
                When 'PostalCode'                   {return address?.PostalCode;}
                When 'Country'                      {return address?.Country;}
                When 'poboxAddressLine1'            {return poboxAddress?.AddressLine1;}
                When 'poboxCity'                    {return poboxAddress?.City;}
                When 'poboxRegion'                  {return poboxAddress?.Region;}
                When 'poboxPostalCode'              {return poboxAddress?.PostalCode;}
                When 'poboxCountry'                 {return poboxAddress?.Country;}
                When 'Phone'                        {return phone;}
                When 'Fax'                          {return fax;}
                When 'Mobile'                       {return mobile;}
                When 'IsSupplier'                   {return this.IsSupplier;}
                When 'IsCustomer'                   {return this.IsCustomer;}
                When 'DefaultCurrency'              {return this.DefaultCurrency;}
                When 'XeroNetworkKey'               {return this.XeroNetworkKey;}
                When 'SalesDefaultAccountCode'      {return this.SalesDefaultAccountCode;}
                When 'PurchasesDefaultAccountCode'  {return this.PurchasesDefaultAccountCode;}
                When 'TrackingCategoryName'         {return this.TrackingCategoryName;}
                When 'PaymentTerms'                 {return this.PaymentTerms;}
                When 'PaymentTermsSalesDay'         {return this.PaymentTerms?.Sales?.Day;}
                When 'PaymentTermsSalesType'        {return this.PaymentTerms?.Sales?.Type_x;}
                When 'UpdatedDateDTC'               {return this.UpdatedDateDTC;}
                When Else                           {return NULL;}
            }
        }
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
        public String AddressType_x;
    }

    public class Phone
    {
        public String PhoneType;
        public String PhoneNumber;
        public String PhoneAreaCode;
        public String PhoneCountryCode;
        public String PhoneType_x;
        
    }
    
    public class ContactGroup
    {
        
    }
    
    public class SalesTrackingCategory
    {
        
    }
    
    public class PurchasesTrackingCategory
    {
        
    }
    
    public class ContactPerson
    {
        
    }
    
    //Post Invoice
    public class PostInvoiceResponseBody
    {
        public String Id;
        Public String Status;
        public String ProviderName;
        public String DateTimeUTC;
        public List<Invoice> Invoices;
    }
    
    public class Invoice
    {
        public String Type_x;
        public String InvoiceID;
        public String InvoiceNumber;
        public String Reference;
        public List<Prepayment> Prepayments;
        public List<Overpayment> Overpayments;
        public Decimal AmountDue;
        public Decimal AmountPaid;
        public Boolean SentToContact;
        public Decimal CurrencyRate;
        public Boolean IsDiscounted;
        public Boolean HasErrors;
        public XeroContact Contact;
        public String DateString;
        public String Date_x;
        public String DueDateString;
        public String DueDate;
        public String BrandingThemeID;
        public String Status;
        public String LineAmountTypes;
        public List<LineItem> LineItems;
        public Decimal SubTotal;
        public Decimal TotalTax;
        public Decimal Total;
        public String UpdatedDateUTC;
        public String CurrencyCode;
        
        public Object GetField(String fieldToGet)
        {
            XeroContact con;
            
            if(this.Contact != NULL) con = XeroStructureSearch.GetXeroContactFromInvoice(this.Contact);
            
            Switch on fieldToGet
            {
                When 'Type'             {return this.Type_x;}
                When 'InvoiceID'        {return this.InvoiceID;}
                When 'InvoiceNumber'    {return this.InvoiceNumber;}
                When 'Reference'        {return this.Reference;}
                When 'AmountDue'        {return this.AmountDue;}
                When 'AmountPaid'       {return this.AmountPaid;}
                When 'SentToContact'    {return this.SentToContact;}
                When 'CurrencyRate'     {return this.CurrencyRate;}
                When 'IsDiscounted'     {return this.IsDiscounted;}
                When 'HasErrors'        {return this.HasErrors;}
                When 'DateString'       {return this.DateString;}
                When 'DueDateString'    {return this.DueDateString;}
                When 'DueDate'          {return this.DueDate;}
                When 'BrandingThemeID'  {return this.BrandingThemeID;}
                When 'Status'           {return this.Status;}
                When 'LineAmountTypes'  {return this.LineAmountTypes;}
                When 'SubTotal'         {return this.SubTotal;}
                When 'TotalTax'         {return this.TotalTax;}
                When 'Total'            {return this.Total;}
                When 'UpdatedDateUTC'   {return this.UpdatedDateUTC;}
                When 'CurrencyCode'     {return this.CurrencyCode;}
                When 'ContactId'        {return con?.ContactID;}
                When 'ContactStatus'    {return con?.ContactStatus;}
                When 'ContactName'    {return this.Contact?.Name;}
                When Else               {return NULL;}
            }
        }
    }
    
    public class Prepayment
    {
        
    }
    
    public class Overpayment
    {
        
    }
    
     //GET PurchaseOrder
    public class GetPurchaseOrderResponseBody
    {
        public String Id;
        Public String Status;
        public String ProviderName;
        public String DateTimeUTC;
        public List<PurchaseOrder> PurchaseOrders;
    }
    
    //Post PurchaseOrder
    public class PostPurchaseOrderResponseBody
    {
        public String Id;
        Public String Status;
        public String ProviderName;
        public String DateTimeUTC;
        public List<PurchaseOrder> PurchaseOrders;
    }
    
     public class PurchaseOrder
    {
        public String Reference;
        public PurchaseOrderXeroContact Contact;
        public String Date_x;
        public String DeliveryDate;
        public String LineAmountTypes;
        public List<LineItem> LineItems;
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
    
    public class LineItem
    {
        public String Description;
        public Decimal UnitAmount;
        public String TaxType;
        public String ItemCode;
        public Decimal TaxAmount;
        public Decimal LineAmount;
        public Decimal DiscountRate;
        public String AccountCode;
        public List<Tracking> Tracking;
        public Decimal Quantity;
        public String LineItemID;
        public List<ValidationError> ValidationErrors;
        
        public Object GetField(String fieldToGet)
        {
            Switch on fieldToGet
            {
                When 'Description'  {return this.Description?.abbreviate(255);}
                When 'UnitAmount'   {return this.UnitAmount;}
                When 'TaxType'      {return this.TaxType;}
                When 'TaxAmount'    {return this.TaxAmount;}
                When 'LineAmount'   {return this.LineAmount;}
                When 'AccountCode'  {return this.AccountCode;}
                When 'Quantity'     {return this.Quantity;}
                When 'LineItemID'   {return this.LineItemID;}
                When 'ItemCode'   {return this.ItemCode;}
                When Else           {return NULL;}
            }
        }
    }
    
    public class Tracking
    {
        
    }
    
    public class ValidationError
    {
        
    }

    //Post Quote
    public class PostQuoteResponseBody
    {
        public String Id;
        Public String Status;
        public String ProviderName;
        public String DateTimeUTC;
        public List<Quote> Quotes;
    }

    public class Quote
    {
        public XeroContact Contact;
        public String Date_x;
        public String DateString;
        public String ExpiryDate;
        public String ExpiryDateString;
        public String Status;
        public String LineAmountTypes;
        public List<LineItem> LineItems;
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
        public String SalesforceRecordId;
        public String QuoteContactID;        
    }
    
    //Get Items
    public class GetItemResponseBody
    {
        public String Id;
        Public String Status;
        public String ProviderName;
        public String DateTimeUTC;
        public List<Item> Items;
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
    
}