@IsTest
public class MYOB_PostOrderRequestFlow_Test {

    @testSetup
    static void setup(){
        
        Account accRecord = new Account(Name = 'ABC',
                                        ABN_Bric__c = '123456789012345',
                                        BillingStreet = 'Kingsway', BillingCity='Sydney',
                                        BillingPostalCode = '2000', BillingCountry = 'Australia',
                                        ShippingStreet = 'Kingsway', ShippingCity='Sydney',
                                        ShippingPostalCode = '2000', ShippingCountry = 'Australia');
        insert accRecord;
        
        ID standardPricebook = Test.getStandardPricebookId();
        Product2 prod = new Product2();
        prod.Name = 'Test';
        prod.IsActive = true;
        prod.ProductCode = 'ABC';
        insert prod;
        
        PricebookEntry pbe = new PricebookEntry();
        pbe.Product2Id = prod.Id;
        pbe.Pricebook2Id = standardPricebook;
        pbe.UnitPrice = 10;
        insert pbe;
        
        Order orderRecord = new Order();
        orderRecord.AccountId = accRecord.Id;
        orderRecord.EffectiveDate = Date.today();
        orderRecord.Status = 'Draft';
        orderRecord.Pricebook2Id = standardPricebook;
        insert orderRecord;
        
        OrderItem ordItem = new OrderItem();
        ordItem.OrderId = orderRecord.Id;
        ordItem.PricebookEntryId = pbe.Id;
        ordItem.Quantity = 1;
        ordItem.UnitPrice = 10;
        insert ordItem;
        
        
    }
    
    testMethod static void SendContactToMYOBFromFlow_NOEXISTINGUID(){
        
        Account accrecord = [SELECT Id,Name, BillingCity, BillingState, BillingStreet, BillingCountry, BillingPostalCode,
                             ShippingCity, ShippingState, ShippingStreet, ShippingCountry, ShippingPostalCode
                             FROM Account LIMIT 1];
        Order orderRecord = [SELECT Id FROM Order LIMIT 1];
        
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
        
        MYOB_FlowParam_SalesOrder salesOrder = new MYOB_FlowParam_SalesOrder();
        salesOrder.Customer = customer;
        salesOrder.CustomerPurchaseOrderNumber = 'ABC';
        salesOrder.SFID = orderRecord.Id;
        
        MYOB_RestResponseCollection.ContactResponseBody contactResponse = new MYOB_RestResponseCollection.ContactResponseBody();
        MYOB_RestResponseCollection.Contact contactItem = new MYOB_RestResponseCollection.Contact();
        contactItem.UID = '123456789012345';
        contactItem.RowVersion = '123456789012345';
        contactResponse.Items = new List<MYOB_RestResponseCollection.Contact>{contactItem};
        MYOB_MockResponse response = new MYOB_MockResponse(MYOB_CONSTANTS.INTEGRATION_REST_RESPONSE_200, JSON.serialize(contactResponse));
        
        test.startTest();
        test.setMock(HttpCalloutMock.class, response);	
        MYOB_PostOrderRequestFlow.SendOrderToMYOBFromFlow(new List<MYOB_FlowParam_SalesOrder>{salesOrder});
        test.stopTest();
    }
    
    testMethod static void SendContactToMYOBFromFlow_WITHGUID(){
        
        Account accrecord = [SELECT Id,Name, BillingCity, BillingState, BillingStreet, BillingCountry, BillingPostalCode,
                             ShippingCity, ShippingState, ShippingStreet, ShippingCountry, ShippingPostalCode
                             FROM Account LIMIT 1];
        Order orderRecord = [SELECT Id FROM Order LIMIT 1];
        
        MYOB_FlowParam_Customer customer = new MYOB_FlowParam_Customer();
        customer.ABN = '123456789012345';
        customer.UID = '123456789012345';
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
        
        MYOB_FlowParam_SalesOrder salesOrder = new MYOB_FlowParam_SalesOrder();
        salesOrder.Customer = customer;
        salesOrder.CustomerPurchaseOrderNumber = 'ABC';
        salesOrder.SFID = orderRecord.Id;
        
        MYOB_RestResponseCollection.ContactResponseBody contactResponse = new MYOB_RestResponseCollection.ContactResponseBody();
        MYOB_RestResponseCollection.Contact contactItem = new MYOB_RestResponseCollection.Contact();
        contactItem.UID = '123456789012345';
        contactItem.RowVersion = '123456789012345';
        contactResponse.Items = new List<MYOB_RestResponseCollection.Contact>{contactItem};
        MYOB_MockResponse response = new MYOB_MockResponse(MYOB_CONSTANTS.INTEGRATION_REST_RESPONSE_200, JSON.serialize(contactResponse));
        
        test.startTest();
        test.setMock(HttpCalloutMock.class, response);	
        MYOB_PostOrderRequestFlow.SendOrderToMYOBFromFlow(new List<MYOB_FlowParam_SalesOrder>{salesOrder});
        test.stopTest();
    }
    
    testMethod static void SendContactToMYOBFromFlow_NOTFOUND(){
        
        Account accrecord = [SELECT Id,Name, BillingCity, BillingState, BillingStreet, BillingCountry, BillingPostalCode,
                             ShippingCity, ShippingState, ShippingStreet, ShippingCountry, ShippingPostalCode
                             FROM Account LIMIT 1];
        Order orderRecord = [SELECT Id FROM Order LIMIT 1];
        
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
        
        MYOB_FlowParam_SalesOrder salesOrder = new MYOB_FlowParam_SalesOrder();
        salesOrder.Customer = customer;
        salesOrder.CustomerPurchaseOrderNumber = 'ABC';
        salesOrder.SFID = orderRecord.Id;
        
        MYOB_RestResponseCollection.ContactResponseBody contactResponse = new MYOB_RestResponseCollection.ContactResponseBody();
        MYOB_MockResponse response = new MYOB_MockResponse(MYOB_CONSTANTS.INTEGRATION_REST_RESPONSE_200, JSON.serialize(contactResponse));
        
        test.startTest();
        test.setMock(HttpCalloutMock.class, response);	
        MYOB_PostOrderRequestFlow.SendOrderToMYOBFromFlow(new List<MYOB_FlowParam_SalesOrder>{salesOrder});
        test.stopTest();
    }
    
}