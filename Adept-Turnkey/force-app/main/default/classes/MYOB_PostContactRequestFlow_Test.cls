@IsTest
public class MYOB_PostContactRequestFlow_Test {

    @testSetup
    static void setup(){
        
        Account accRecord = new Account(Name = 'ABC',
                                        ABN_Bric__c = '123456789012345',
                                        BillingStreet = 'Kingsway', BillingCity='Sydney',
                                        BillingPostalCode = '2000', BillingCountry = 'Australia',
                                        ShippingStreet = 'Kingsway', ShippingCity='Sydney',
                                        ShippingPostalCode = '2000', ShippingCountry = 'Australia');
        insert accRecord;
        

    }
    
    testMethod static void SendContactToMYOBFromFlow_NOEXISTINGUID(){
        
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
        
        MYOB_RestResponseCollection.ContactResponseBody contactResponse = new MYOB_RestResponseCollection.ContactResponseBody();
        MYOB_MockResponse response = new MYOB_MockResponse(MYOB_CONSTANTS.INTEGRATION_REST_RESPONSE_200, JSON.serialize(contactResponse));
        
        test.startTest();
        test.setMock(HttpCalloutMock.class, response);	
        MYOB_PostContactRequestFlow.SendContactToMYOBFromFlow(new List<MYOB_FlowParam_Customer>{customer});
        test.stopTest();
    }
    
    testMethod static void SendContactToMYOBFromFlow_NOEXISTINGUID_FOUNDMATCH(){
        
        Account accrecord = [SELECT Id,Name, BillingCity, BillingState, BillingStreet, BillingCountry, BillingPostalCode,
                            ShippingCity, ShippingState, ShippingStreet, ShippingCountry, ShippingPostalCode
                             FROM Account LIMIT 1];
        
        MYOB_FlowParam_Customer customer = new MYOB_FlowParam_Customer();
        customer.ABN = '123456789012345';
        customer.AccountSFID = accRecord.Id;
        customer.DisplayID = 'TestDisplayID';
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
        customer.CompanyFileId = 'CompanyFileID';
        customer.CompanyName = accRecord.Name;
        customer.IsIndividual = false;
        
        MYOB_RestResponseCollection.ContactResponseBody contactResponse = new MYOB_RestResponseCollection.ContactResponseBody();
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
        contactItem.Addresses = new List<MYOB_RestResponseCollection.Address>{conAddress1, conAddress2};
        contactResponse.Items = new List<MYOB_RestResponseCollection.Contact>{contactItem};
       
        MYOB_MockResponse response = new MYOB_MockResponse(MYOB_CONSTANTS.INTEGRATION_REST_RESPONSE_200, JSON.serialize(contactResponse));
        
        test.startTest();
        test.setMock(HttpCalloutMock.class, response);	
        MYOB_PostContactRequestFlow.SendContactToMYOBFromFlow(new List<MYOB_FlowParam_Customer>{customer});
        test.stopTest();
    }
    
    testMethod static void SendContactToMYOBFromFlow_EXISTINGUID(){
        
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
        customer.CompanyFileId = 'CompanyFileID';
        customer.CompanyName = accRecord.Name;
        customer.UID = 'TestAccountUID';
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
        contactItem.Addresses = new List<MYOB_RestResponseCollection.Address>{conAddress1, conAddress2};
        MYOB_MockResponse response = new MYOB_MockResponse(MYOB_CONSTANTS.INTEGRATION_REST_RESPONSE_200, JSON.serialize(contactItem));
        
        test.startTest();
        test.setMock(HttpCalloutMock.class, response);	
        MYOB_PostContactRequestFlow.SendContactToMYOBFromFlow(new List<MYOB_FlowParam_Customer>{customer});
        test.stopTest();
    }
    
}