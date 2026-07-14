@isTest
public class MYOB_RunMYOBBatchCtrl_Test {
    
    @testSetup
    private static void Setup()
    {
        Account accRecord = new Account(Name = 'ABC',
                                        ABN_Bric__c = '123456789012345',
                                        BillingStreet = 'Kingsway', BillingCity='Sydney',
                                        BillingPostalCode = '2000', BillingCountry = 'Australia',
                                        ShippingStreet = 'Kingsway', ShippingCity='Sydney',
                                        ShippingPostalCode = '2000', ShippingCountry = 'Australia');
        insert accRecord;
        
        MYOBProcessingSettings__c MYOBProcessingSettings = new MYOBProcessingSettings__c();
        MYOBProcessingSettings.Contact_Sync_Date_Time__c = Date.today();
        MYOBProcessingSettings.Invoice_Sync_Date_Time__c = Date.today();
        insert MYOBProcessingSettings;
    }
    
    @isTest
    private static void GetMYOBContactBatch_Test()
    {
      Account accrecord = [SELECT Id,Name, BillingCity, BillingState, BillingStreet, BillingCountry, BillingPostalCode,
                            ShippingCity, ShippingState, ShippingStreet, ShippingCountry, ShippingPostalCode
                             FROM Account LIMIT 1];
     
        
        MYOB_FlowParam_Customer customer = new MYOB_FlowParam_Customer();
        customer.ABN = '123456789012345';
        customer.AccountSFID = accRecord.Id;
        MYOB_FlowParam_Address address1 = new MYOB_FlowParam_Address();
        address1.Location = 1;
        address1.City = accrecord.BillingCity;
        address1.State = accRecord.BillingState;
        address1.Street = accRecord.BillingStreet;
        address1.Country = accRecord.BillingCountry;
        address1.PostCode = accRecord.BillingPostalCode;
        
        MYOB_FlowParam_Address address2 = new MYOB_FlowParam_Address();
        address2.Location = 2;
        address2.City = accrecord.ShippingCity;
        address2.State = accRecord.ShippingState;
        address2.Street = accRecord.ShippingStreet;
        address2.Country = accRecord.ShippingCountry;
        address2.PostCode = accRecord.ShippingPostalCode;
        customer.Addresses = new List<MYOB_FlowParam_Address>{address1,address2};
        customer.CompanyName = accRecord.Name;
        customer.IsIndividual = false;        
        
        MYOB_RestResponseCollection.Contact contactItem = new MYOB_RestResponseCollection.Contact();
        contactItem.ABN = '123456789012345';
        contactItem.UID = 'ContactUID';
        MYOB_RestResponseCollection.Address conAddress1 = new MYOB_RestResponseCollection.Address();   
        conAddress1.Location = 1;
        conAddress1.City = accrecord.BillingCity;
        conAddress1.State = accRecord.BillingState;
        conAddress1.Street = accRecord.BillingStreet;
        conAddress1.Country = accRecord.BillingCountry;
        conAddress1.PostCode = accRecord.BillingPostalCode;
        
        MYOB_RestResponseCollection.Address conAddress2 = new MYOB_RestResponseCollection.Address();
        conAddress2.Location = 2;
        conAddress2.City = accrecord.ShippingCity;
        conAddress2.State = accRecord.ShippingState;
        conAddress2.Street = accRecord.ShippingStreet;
        conAddress2.Country = accRecord.ShippingCountry;
        conAddress2.PostCode = accRecord.ShippingPostalCode;
        
        MYOB_RestResponseCollection.ContactResponseBody contactResponse = new MYOB_RestResponseCollection.ContactResponseBody();
        
        contactItem.Addresses = new List<MYOB_RestResponseCollection.Address>{conAddress1, conAddress2};
        contactResponse.Items = new List<MYOB_RestResponseCollection.Contact>{contactItem};
            
        MYOB_MockResponse response = new MYOB_MockResponse(MYOB_CONSTANTS.INTEGRATION_REST_RESPONSE_200, JSON.serialize(contactResponse));
        
        test.startTest();        
            test.setMock(HttpCalloutMock.class, response);
            RunMYOBBatchCtrl.runMYOBGetContactsBatch();        
        
            MYOB_ContactBatchSchedulable batch= new MYOB_ContactBatchSchedulable();
            String cronExp = '0 0 23 * * ?';
            system.schedule('MYOB Contacts Batch', cronExp, batch);
        
        test.stopTest();
    }

  @isTest
    private static void GetMYOBInvoiceBatch_Test()
    {
        
        MYOB_RestResponseCollection.Invoice inv = new MYOB_RestResponseCollection.Invoice();
        inv.UID = 'Invoice UID';
        inv.BalanceDueAmount = 10;
        inv.Comment = 'Comment';
        MYOB_RestResponseCollection.Contact customer = new MYOB_RestResponseCollection.Contact();
        customer.Name = 'Name';
        customer.UID = 'CustomerUID';
        inv.Customer = customer;
        inv.CustomerPurchaseOrderNumber = 'CustomerPurchaseOrderNumber';
        inv.Date_x = '2015-02-16T00:00:00';
        inv.IsTaxInclusive = FALSE;
        inv.JournalMemo = 'JournalMemo';
        inv.LastPaymentDate = '2015-02-16T00:00:00';
        inv.Number_x = 'Number';
        inv.PromisedDate = '2015-02-16T00:00:00';
        MYOB_RestResponseCollection.Contact salesPerson = new MYOB_RestResponseCollection.Contact();
        customer.Name = 'salesPerson';
        customer.UID = 'CustomerUID';
        inv.Salesperson = salesPerson;
        inv.ShipToAddress = 'Address';
        inv.Status = 'Open';
        inv.Subtotal = 100;
        inv.TotalAmount = 200;
        inv.TotalTax = 300;
        inv.UID = 'Invoice UID';
        MYOB_RestResponseCollection.InvoiceLineItem invItem = new MYOB_RestResponseCollection.InvoiceLineItem();
        MYOB_RestResponseCollection.Item item = new MYOB_RestResponseCollection.Item();
        item.Name = 'Item';
        item.UID = 'Invoice UID';
        invItem.Item = item;
        invItem.Description = 'Description';
        invItem.CostOfGoodsSold = 10;
        invItem.DiscountPercent = 10;
        invItem.RowId = 10;
        invItem.ShipQuantity = 10;
        invItem.Total = 10;
        invItem.Type_x = 'Item';
        invItem.UnitCount = 1;
        invItem.UnitOfMeasure = 'UOM';
        invItem.UnitPrice = 10;        
        inv.Lines = new List<MYOB_RestResponseCollection.InvoiceLineItem>{invItem};
      
        MYOB_RestResponseCollection.InvoiceResponseBody invoiceResponse = new MYOB_RestResponseCollection.InvoiceResponseBody();
        invoiceResponse.Items = new List<MYOB_RestResponseCollection.Invoice>{inv};
        MYOB_MockResponse response = new MYOB_MockResponse(MYOB_CONSTANTS.INTEGRATION_REST_RESPONSE_200, JSON.serialize(invoiceResponse));
        
        test.startTest();        
            test.setMock(HttpCalloutMock.class, response);
            RunMYOBBatchCtrl.runMYOBGetInvoicesBatch();
        
            MYOB_InvoiceBatchSchedulable batch= new MYOB_InvoiceBatchSchedulable();
            String cronExp = '0 0 23 * * ?';
            system.schedule('MYOB Invoices Batch', cronExp, batch);
        MYOB_Constants.ERROR_MESSAGE_TRIGGER_HANDLER_METADATA_DOES_NOT_EXIST('Account');
        MYOB_Constants.ERROR_MESSAGE_TRIGGER_HANDLER_DOES_NOT_EXIST('Account');
        test.stopTest();
    }    
}