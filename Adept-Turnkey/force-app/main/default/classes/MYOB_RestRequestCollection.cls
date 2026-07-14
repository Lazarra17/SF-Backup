/*
* Author: Bricoleur Technologies
* Created Date: June 23, 2023
* Description: Apex class for all requests to MYOB 
*/

public class MYOB_RestRequestCollection {
    
    public class EmployeeRequestBody{
        
        public String UID; //(36)
        public String LastName; //(50)
        public String FirstName; //(20)
        public Boolean IsIndividual; 
        public String DisplayID; //(15)
        public Boolean IsActive; 
        public List<Address> Addresses; 
    }
    /*
    public class CustomerRequestBodyUpdate{
        public String UID; //(36)
        //public String LastName; //(50)
        //public String FirstName; //(20)
        public Boolean IsIndividual; 
        public String DisplayID; //(15)
        public String CompanyName; //(15)
        public String ABN; //(50)
        public String Notes; //(255)     
        public String RowVersion; //(50)
        public MYOB_FlowParam_SellingDetail SellingDetails;
        public List<MYOB_FlowParam_Address> Addresses;
    }
    */
    
    
    public class CustomerRequestBody{
        public String UID; //(36)
        public String LastName; //(50)
        public String FirstName; //(20)
        public Boolean IsIndividual; 
        public String DisplayID; //(15)
        public String CompanyName; //(15)
        //public String ABN; //(50)
        public String Notes; //(255)   
        public String RowVersion; //(50)
        public MYOB_FlowParam_SellingDetail SellingDetails;
        public MYOB_FlowParam_BuyingDetail BuyingDetails;
        public List<MYOB_FlowParam_Address> Addresses;
        
    }
    
    public class InvoiceRequestBody{
        public String UID; //required
        public Date Date_x; //required
        public String Number_x; //required
        public Boolean IsTaxInclusive;
        public String CustomerPurchaseOrderNumber;
        public MYOB_FlowParam_SalesOrder Order;
        public MYOB_FlowParam_Customer Customer;
        public List<MYOB_FlowParam_SalesOrderLines> Lines;
        public String RowVersion; //(50)
        public MYOB_RestRequestCollection.Terms Terms;
    }
    
    public class Customer{
        public String UID; //(36)
        public String Name; //(50)
        public String DisplayID; //(15)
    }
    
    public class Order{
        public String UID; //(36)
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
    
    public class SellingDetail{
        public TaxCode TaxCode;
        public TaxCode FreightTaxCode;
    }    
    
    public class TaxCode{
        public String UID;
    }
    
    public class SalesOrderRequestBody {
        
        //public String UID; //required
        public Date Date_x; //required
        public String Number_x; //required
        public String CustomerPurchaseOrderNumber;
        public MYOB_FlowParam_Customer Customer;
        public List<MYOB_FlowParam_SalesOrderLines> Lines;
        public Boolean IsTaxInclusive;
        public MYOB_FlowParam_ForeignCurrency ForeignCurrency;
        
    }
 
    

    public class Terms{
        public String PaymentIsDue;
        public Integer DiscountDate;
        public Integer BalanceDueDate;
        public Decimal DiscountForEarlyPayment;
        public Decimal MonthlyChargeForLatePayment;
        public String DiscountExpiryDate;
        public Decimal Discount;
    }
    
    /**PRODUCT JSON*/
    public class InventoryItem{
        public IncomeAccount IncomeAccount;
        public Decimal BaseSellingPrice;
        public String Description;
        public Boolean IsSold;
        public Boolean IsActive;
        public String Name;
        public SellingDetails SellingDetails;
        public String Number_x;
    }
    
    public class SellingDetails{
        public String CalculateSalesTaxOn;
        public Boolean IsTaxInclusive;
        public TaxCode TaxCode;
        public Decimal BaseSellingPrice;
        public String ABN;
    }
    public class IncomeAccount{
        public String UID;
    }
    /**PRODUCT JSON*/
    
    
    /**PURCHASE ORDER JSON*/
    public class PurchaseOrderItemBody{
        public String UID;
        public String Number_x; // 'Number' is a reserved keyword or identifier
        public Date Date_x;   // 'Date' is a reserved keyword
        public MYOB_FlowParam_Supplier Supplier;
        public String ShipToAddress;
        public Boolean IsTaxInclusive; 
        public List<MYOB_FlowParam_PurchaseOrderItemLine> Lines;
        public MYOB_FlowParam_FreightTaxCode FreightTaxCode;
        public String Comment;
        public String Status;
        public MYOB_FlowParam_ForeignCurrency ForeignCurrency;
    }
    
    public class Item {
        public String UID;
    }
     
    public class Location {
        public String UID;
    }
    
    
    /**PURCHASE BILL JSON*/
    public class PurchaseBillItemBody{
        public String UID;
        public String Number_x; // Renamed from 'Number'
        public Date Date_x;   // Renamed from 'Date'
        public MYOB_FlowParam_Supplier Supplier;
        public String ShipToAddress;
        public List<MYOB_FlowParam_PurchaseOrderItemLine> Lines;
        public Boolean IsTaxInclusive;
        public MYOB_FlowParam_TaxCode FreightTaxCode;
        public String Status;
        public String BillType;
        public MYOB_FlowParam_SalesOrder Order;
        public String RowVersion; 
        public String BillDeliveryStatus;
    }
    
    
    /**PRODUCT / ITEM JSON*/
    public class InventoryItemBody{
        public String UID;
        public String Name;
        public String Number_x;
        public Boolean IsActive;
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
    
    
    
    
}