/*
* Author: Bricoleur Technologies
* Created Date: June 23, 2023
* Description: Apex class for all responses from MYOB 
*/

public class MYOB_RestResponseCollection {

    
    public class ContactResponseBody{
        public List<Contact> Items;
        public String NextPageLink;
        public Integer count;
    }

    public class JobResponseBody{
        public List<Job> Items;
        public String NextPageLink;
        public Integer count; 
    }
    
    public class InvoiceResponseBody{
        public List<Invoice> Items;
        public String NextPageLink;
        public Integer count;
    }

    public class CustomerPaymentResponseBody{
        public List<CustomerPayment> Items;
        public String NextPageLink;
        public Integer count;
    }
    
    public class BillResponseBody{
        public List<Bill> Items;
        public String NextPageLink;
        public Integer count;
    }
    
    public class SalesOrderResponseBody{
        public List<SalesOrder> Items;
        public String NextPageLink;
        public Integer count;
    }
    
    public class PurchaseOrderResponseBody{
        public List<PurchaseOrder> Items;
        public String NextPageLink;
        public Integer count;
    }
    
    
    
    public class Job {        
        public String UID;
        public String Name;
        public String Description;
        public String Number_x;   
    }
    
    public class Contact{
        public String UID;
        public String LastName;
        public String FirstName;
        public String Name;
        public String CompanyName;
        public Boolean IsIndividual;
        public String DisplayID;
        public Boolean IsActive;
        public List<Address> Addresses;
        public String Notes;
        public List<Identifier> Identifiers;
        public Decimal CurrentBalance;
        public SellingDetail SellingDetails;
        public PaymentDetail PaymentDetails;
        public ForeignCurrency ForeignCurrency;
        public DateTime LastModifiedDateTime;
        public String PhotoURIString;
        public String URIString;
        public String RowVersion;  
        public String PhotoURI; 
        public String URI;      
        public String ABN;   
        public CustomList CustomList2;
        public CustomList CustomList3;
    }
    
    public Class CustomList{
            
        public String Label;       
        public String Value;   
    }
    
    public class Address{
        public Integer Location; 
        public String Street; //(255)
        public String City; //(255)
        public String State; // (255)
        public String PostCode; // (11)
        public String Country; // (255)
        public String Phone1; // (21)
        public String Phone2; // (21)
        public String Phone3; // (21)
        public String Fax; // (21)
        public String Email; // (255)
        public String Website; //(255)
        public String ContactName; // 25
        public String Salutation; // 15
    }

    public class Identifier{
        public String Label;
        public String Value;
    }

    public class SellingDetail{
        public String SaleLayout; //NoDefault;Service;Item;Professional;TimeBilling;Miscellaneous
        public String PrintedForm;
        public String InvoiceDelivery;
        public String ItemPriceLevel; //Base Selling Price;Level A;Level B;Level C;Level D;Level E;Level F;
        public IncomeAccount IncomeAccount;
        public String ReceiptMemo;
        public SalesPerson SalesPerson;
        public String SaleComment;
        public String ShippingMethod;
        public Decimal HourlyBillingRate;
        public String ABN; //14
        public String ABNBranch; //11
        public TaxCode TaxCode;
        public TaxCode FreightTaxCode;
        public Boolean UseCustomerTaxCode;
        public Term Terms;
        public Credit Credit;
        public String TaxIdNumber; //19
        public String Memo; //255
    }
  
    public class PaymentDetail{
        public String Method; //American Express;Bank Card;Barter Card;Cash;Cheque;Diners Club;EFTPOS;MasterCard;Money Order;Other;Visa
        public String CardNumber;
        public String NameOnCard;
        public String BSBNumber;
        public String BankAccountNumber;
        public String BankAccountName;
        public String Notes;
    }  
  
    public class ForeignCurrency{
        public String UID;
        public String Code;
        public String CurrencyName;
        public String URI;        
    }  
    
    public class IncomeAccount{
        public String UID;// (36)
        public String Name; // (30)
        public String Display;// (15)
        public String URI;
    }
    
     public class Account{
        public String UID;// (36)
        public String Name; // (30)
        public String DisplayID;// (15)
        public String URI;
    }

    public class SalesPerson{
        public String UID;// (36)
        public String Name; // (30)
        public String Display;// (15)
        public String URI;
    } 

    public class TaxCode{
        public String UID;
        public String Code;
        public String URI;
    } 

    public class Term{
        public String PaymentIsDue;
        public Integer DiscountDate;
        public Integer BalanceDueDate;
        public Decimal DiscountForEarlyPayment;
        public Decimal MonthlyChargeForLatePayment;
        public Decimal VolumeDiscount;
    }
    
    public class Credit{
        public Decimal Limit_x;
        public Decimal Available;
        public Decimal PastDue;
        public Boolean OnHold;
    } 
        
    public class Invoice{
        public String UID;
        public String Number_x;
        public String Date_x;
        public String CustomerPurchaseOrderNumber;
        public Contact Customer;
        public Contact Salesperson;
        public String PromisedDate;
        public Decimal BalanceDueAmount;
        public String Status;
        public String ShipToAddress;
        public Boolean IsTaxInclusive;
        public Decimal Subtotal;
        public Decimal TotalTax;
        public Decimal TotalAmount;
        public String Comment;
        public String JournalMemo;
        public String LastPaymentDate;
        public List<InvoiceLineItem> Lines;
        public MYOB_RestRequestCollection.Terms Terms;
        public String RowVersion;
        public InvoiceOrder Order;
        
    } 
    
     public class InvoiceOrder{
        public String UID;
        public String Number_x;
    }

    public class CustomerPayment{
        public String UID;
        public String Date_x;
        public Customer Customer;
        public Decimal AmountReceived;
        public String PaymentMethod;
        public String Memo;
        public List<CustomerPaymentInvoiceLine> Invoices;
        public String RowVersion;
        public String URI;
    }

    public class CustomerPaymentInvoiceLine{
        public String UID;
        public PaymentSale Sale;
        public Decimal AmountApplied;
        public Decimal DiscountApplied;
    }

    public class PaymentSale{
        public String UID;
        public String Number_x;
        public String Type_x;
    } 
    
    public class InvoiceLineItem{
        public Integer RowID;
        public Decimal ShipQuantity;
        public String Type_x;
        public String UnitOfMeasure;
        public String Description;
        public Decimal UnitPrice;
        public Decimal UnitCount;
        public Decimal DiscountPercent;
        public Decimal CostOfGoodsSold;
        public Decimal Total;
        public Item Item;
        public Account Account;
        public TaxCode TaxCode;   
    } 
    
     public class Item{
        public String UID;
        public String Number_x;
        public String Name;      
    } 
    
    
    
    /**PURCHASE PURCHASE ORDER JSON*/
    public class PurchaseOrder{
        public String UID;
        public String Number_x; // 'Number' is a reserved keyword or identifier
        public String Date_x;   // 'Date' is a reserved keyword
        public MYOB_FlowParam_Supplier Supplier;
        public String ShipToAddress;
        public Boolean IsTaxInclusive; 
        public List<MYOB_FlowParam_PurchaseOrderItemLine> Lines;
        public MYOB_FlowParam_FreightTaxCode FreightTaxCode;
        public String Comment;
        public String Status;
        public MYOB_FlowParam_ForeignCurrency ForeignCurrency;
        public String RowVersion;
        
        
        
    }
    
    
    
    //Sales Order Response
    public class SalesOrder{
        public String SubtotalForeign;
        public Decimal TotalTax;
        public FreightTaxCode FreightTaxCode;
        public String TotalTaxForeign;
        public String Category;
        public String Salesperson;
        public String TotalAmountForeign;
        public String Comment;
        public Decimal TotalAmount;
        public String ShippingMethod;
        public String FreightForeign;
        public String JournalMemo;
        public Decimal Freight;
        public String PromisedDate;
        public Decimal Subtotal;
        public String DeliveryStatus;
        public list<OrderLines> Lines;
        public String ReferralSource;
        public String AppliedToDateForeign;
        public Decimal BalanceDueAmount;
        public Decimal AppliedToDate;
        public String BalanceDueAmountForeign;
        public Boolean IsTaxInclusive;
        public String Status;
        public Terms Terms;
        public String LastPaymentDate;
        public Customer Customer;
        public ForeignCurrency ForeignCurrency;
        public String CustomerPurchaseOrderNumber;
        public String CurrencyExchangeRate;
        public String ShipToAddress;
        public String LastModified;
        public String Date_x;
        public String URI;
        public String Number_x;
        public String RowVersion;
        public String UID;
    }
	public class Terms{
		public String DiscountExpiryDate;
		public Decimal Discount;
		public Decimal MonthlyChargeForLatePayment;
		public String DiscountForeign;
		public Decimal DiscountForEarlyPayment;
		public String DueDate;
		public Integer BalanceDueDate;
		public Decimal FinanceCharge;
		public Integer DiscountDate;
		public String FinanceChargeForeign;
		public String PaymentIsDue;
	}

	public class Location{
		public String Name;
		public String UID;
        public String Identifier;
	}
	public class OrderLines{
		public Location Location;
		public Decimal DiscountPercent;
		public Decimal Total;
		public Decimal UnitPriceForeign;
		public String TotalForeign;
		public Decimal UnitPrice;
		public OrderItem Item;
		public Decimal ShipQuantity;
		public String Job;
		public String Description;
		public TaxCode TaxCode;
		public String Type;
		public String RowVersion;
		public Integer RowID;
	}
    
    public class BillLines{
        public Integer RowID;
        public String Type;
		public String Description;
        public Decimal BillQuantity;
        public Decimal ReceivedQuantity;
        public Decimal BackorderQuantity;
        public Decimal Total;
        public String TotalForeign;
        public Decimal UnitPrice;
        public Decimal UnitPriceForeign;
        public String Job;
        public Decimal DiscountPercent;
		public Location Location;
		public TaxCode TaxCode;
		public OrderItem Item;
		public Decimal ShipQuantity;
		public String RowVersion;
		
		
		
	}
    
    
	public class OrderItem{
		public String Number_x;
		public String Name;
		public String UID;
	}
	public class FreightTaxCode{
		public String UID;
	}
	public class Customer{
		public String UID;
        public String Name;
        
	}
    
    public class MYOBOrder {
        public String UID;
        public String Number_x; // Mapped from 'Number'
    }

    public class Supplier {
        public String UID;
        public String Name;
        public String DisplayID;
        public String URI;
    }
    
    
    /**PRODUCT / ITEM JSON*/
    public class InventoryItemBody{
        public String UID;
        public String Name;
        public Boolean IsActive;
        public String Number_x;
        public String Description;
        public Decimal BaseSellingPrice;
        public Boolean IsBought;
        public Boolean IsSold;
        public Boolean IsInventoried;
        public String RowVersion;
        public MYOB_FlowParam_Account IncomeAccount;
        public MYOB_FlowParam_Account ExpenseAccount;
        public MYOB_FlowParam_TaxCode BuyingDetails;
        public MYOB_FlowParam_TaxCode SellingDetails;
    }
    
    
    /**BILL JSON*/
    public class Bill{
        
        public String UID;
        public String Number_x;
        public Date Date_x;
        public String SupplierInvoiceNumber;
        public Supplier Supplier;
        public String ShipToAddress;
        public Term Terms;
        public Boolean IsTaxInclusive;
        public Boolean IsReportable;
        public Decimal Subtotal;
        public Decimal SubtotalForeign;
        public Decimal Freight;
        public Decimal FreightForeign;
        public TaxCode FreightTaxCode;
        public Decimal TotalTax;
        public Decimal TotalTaxForeign;
        public Decimal TotalAmount;
        public Decimal TotalAmountForeign;
        public String Comment;
        public String ShippingMethod;
        public String PromisedDate;
        public String JournalMemo;
        public String BillDeliveryStatus;
        public Decimal AppliedToDate;
        public Decimal AppliedToDateForeign;
        public Decimal BalanceDueAmount;
        public Decimal BalanceDueAmountForeign;
        public String Status;
        public String LastPaymentDate;
        public String BillType;
        public MYOBOrder Order;
        public ForeignCurrency ForeignCurrency;
        public Decimal CurrencyExchangeRate;
        public list<BillLines> Lines;
        
        public String URI;
        public String RowVersion;
        
    }
    
    
    
}