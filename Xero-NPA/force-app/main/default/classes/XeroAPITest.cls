/*
* Author:           Alfonso Maquilan
* Created Date:     May 24, 2021
* Description:      Test class for XeroAPI apex class
* Test Class:       N/A
* History:          May 24, 2021 - Creation
*/
@isTest
public class XeroAPITest 
{
    private static String xeroContactId1 = '11111';
    private static String xeroContactId2 = '22222';
    private static String xeroContactId3 = '33333';
    
    private static String xeroInvoiceId = '55555';
    
    private static String xeroInvoiceLineItemId1 = '5-1111';
    private static String xeroInvoiceLineItemId2 = '5-2222';
    private static String xeroInvoiceLineItemId3 = '5-3333';
    private static String xeroInvoiceLineItemId4 = '5-4444';
    
    private static String invoiceDueDate = String.valueOf(date.today());
    
    private static Decimal invoiceLineItemAmount = 0;
    private static Decimal invoiceLineItemQuantity = 1;
    
    private class XeroAddressParams
    {
        private String AddressType;
        private String AddressLine1;
        private String City;
        private String Region;
        private String PostalCode;
        private String Country;
    }
    
    @testSetup
    private static void Setup()
    {
        List<Account> testAcctList = TestDataFactory.CreateAccounts(3 , FALSE);
        testAcctList[0].XeroId__c = xeroContactId1;
        testAcctList[1].XeroId__c = xeroContactId2;
        testAcctList[2].XeroId__c = xeroContactId3;
        
        Insert testAcctList;
        
        Contact testCon = TestDataFactory.CreateContacts(1 , testAcctList[0].Id, TRUE)[0];
        
        Opportunity testOpp = TestDataFactory.CreateOpportunities(1 , testAcctList[0].Id , testCon.Id , FALSE)[0];
        testOpp.XeroId__c = xeroInvoiceId;
        
        Insert testOpp;
        
        List<Product2> testProductList = TestDataFactory.CreateProducts(3 , TRUE);
        Id pricebookId = Test.getStandardPricebookId();
        
        TestDataFactory.PricebookEntryParameters pbEParams1 = SetPricebookEntryParams(pricebookId , testProductList[0].Id , 0);
        TestDataFactory.PricebookEntryParameters pbEParams2 = SetPricebookEntryParams(pricebookId , testProductList[1].Id , 0);
        TestDataFactory.PricebookEntryParameters pbEParams3 = SetPricebookEntryParams(pricebookId , testProductList[2].Id , 0);
        
        List<PricebookEntry> testPbEList = new List<PricebookEntry>{TestDataFactory.CreatePricebookEntries(1 , pbEParams1, FALSE)[0],
                                                                    TestDataFactory.CreatePricebookEntries(1 , pbEParams2, FALSE)[0],
                                                                    TestDataFactory.CreatePricebookEntries(1 , pbEParams3, FALSE)[0]};
                                                                        
        Insert testPbEList;
        
        TestDataFactory.OpportunityLineItemParameters oppLineItemParams1 = SetOppLineItemsParams(testOpp.Id , testPbEList[0].Id , 1 , 0);
        TestDataFactory.OpportunityLineItemParameters oppLineItemParams2 = SetOppLineItemsParams(testOpp.Id , testPbEList[1].Id , 1 , 0);
        TestDataFactory.OpportunityLineItemParameters oppLineItemParams3 = SetOppLineItemsParams(testOpp.Id , testPbEList[2].Id , 1 , 0);
                
        List<OpportunityLineItem> oppLineItemTestList = TestDataFactory.CreateOpportunityLineItems(2 , oppLineItemParams2, FALSE);
        oppLineItemTestList.add(TestDataFactory.CreateOpportunityLineItems(1 , oppLineItemParams1, FALSE)[0]);
        oppLineItemTestList.add(TestDataFactory.CreateOpportunityLineItems(1 , oppLineItemParams3, FALSE)[0]);
        
        oppLineItemTestList[0].XeroId__c = xeroInvoiceLineItemId1;
        oppLineItemTestList[1].XeroId__c = xeroInvoiceLineItemId2;
        oppLineItemTestList[2].XeroId__c = xeroInvoiceLineItemId3;
        oppLineItemTestList[3].XeroId__c = xeroInvoiceLineItemId4;
        
        Insert oppLineItemTestList;
        
        XeroAPISettings__c xeroAPISettings = new XeroAPISettings__c();
        xeroAPISettings.Name = Label.Xero_Setting;
        xeroAPISettings.TenantID__c = 'testTenantId';
        xeroAPISettings.Endpoint__c = 'callout:Xero_App/api.xro/2.0';
        
        Insert xeroAPISettings;
        
        XeroInboundFieldMapping__c xeroContactFieldMapping = new XeroInboundFieldMapping__c();
        xeroContactFieldMapping.XeroObject__c = CONSTANTS_BRIC.XERO_INBOUND_FIELD_MAPPING_XERO_OBJECT_CONTACT;
        xeroContactFieldMapping.SalesforceObject__c = 'Account';
        xeroContactFieldMapping.FieldMapping__c = 'Name=Name,Phone=Phone,Fax=Fax,ShippingStreet=AddressLine1,ShippingCity=City,ShippingState=Region,ShippingPostalCode=PostalCode,ShippingCountry=Country';
        xeroContactFieldMapping.Active__c = TRUE;
        
        XeroInboundFieldMapping__c xeroInvoiceFieldMapping = new XeroInboundFieldMapping__c();
        xeroInvoiceFieldMapping.XeroObject__c = CONSTANTS_BRIC.XERO_INBOUND_FIELD_MAPPING_XERO_OBJECT_INVOICE;
        xeroInvoiceFieldMapping.FieldMapping__c = 'Total__c=AmountDue,InvoiceNumber__c=InvoiceNumber,InvoiceID__c=InvoiceID,ContactID__c=ContactId,ContactStatus__c=ContactStatus,Status__c=Status';
        xeroInvoiceFieldMapping.SalesforceObject__c = 'Xero_Loading_Object__c';
        xeroInvoiceFieldMapping.Active__c = TRUE;
        
        XeroInboundFieldMapping__c xeroInvoiceLineItemFieldMapping = new XeroInboundFieldMapping__c();
        xeroInvoiceLineItemFieldMapping.XeroObject__c = CONSTANTS_BRIC.XERO_INBOUND_FIELD_MAPPING_XERO_OBJECT_INVOICE_LINE_ITEM;
        xeroInvoiceLineItemFieldMapping.FieldMapping__c = 'UnitAmount__c=UnitAmount,TaxAmount__c=TaxAmount,LineItemID__c=LineItemID,Quantity__c=Quantity';
        //xeroInvoiceLineItemFieldMapping.SalesforceObject__c = CONSTANTS_BRIC.SOBJECT_OPPORTUNITY_LINE_ITEM;
        xeroInvoiceLineItemFieldMapping.SalesforceObject__c = 'Xero_Line_Item_Load__c';
        xeroInvoiceLineItemFieldMapping.SalesforceLookupField__c = 'Xero_Loading_Object__c';
        xeroInvoiceLineItemFieldMapping.Active__c = TRUE;
        
        Insert new List<XeroInboundFieldMapping__c>{xeroContactFieldMapping , xeroInvoiceFieldMapping , xeroInvoiceLineItemFieldMapping};
    }
    
    private static TestDataFactory.PricebookEntryParameters SetPricebookEntryParams(String pricebookId , String productId , Integer unitPrice)
    {
        TestDataFactory.PricebookEntryParameters pbEParams = new TestDataFactory.PricebookEntryParameters();
        pbEParams.PricebookId = pricebookId;
        pbEParams.ProductId = productId;
        pbEParams.UnitPrice = unitPrice;
        
        return pbEParams;
    }
    
    private static TestDataFactory.OpportunityLineItemParameters SetOppLineItemsParams(String oppId , String pbeId , Decimal qty , Decimal pbeUnitPrice)
    {
        TestDataFactory.OpportunityLineItemParameters oppLineItemParams = new TestDataFactory.OpportunityLineItemParameters();
        oppLineItemParams.OppId = oppId;
        oppLineItemParams.PbeId = pbeId;
        oppLineItemParams.Quantity = qty;
        oppLineItemParams.PbeUnitPrice = pbeUnitPrice;
        
        return oppLineItemParams;
    }
    
    private static List<XeroAPIRequestCollection.Event> SetWebhookEvents(List<String> xeroIdList , String eventType , String eventCategory)
    {
        List<XeroAPIRequestCollection.Event> webhookEventList = new List<XeroAPIRequestCollection.Event>();
        
        for(String xeroId : xeroIdList)
        {
            XeroAPIRequestCollection.Event xeroEvent = new XeroAPIRequestCollection.Event();
            xeroEvent.resourceId = xeroId;
            xeroEvent.eventType = eventType;
            xeroEvent.eventCategory = eventCategory;
            
            webhookEventList.add(xeroEvent);
        }
        
        return webhookEventList;
    }
    
    private static Map<String , RestResponseCollectionXero.XeroContact> GenerateXeroContactMap(List<String> xeroContactIdList)
    {
        Map<String , RestResponseCollectionXero.XeroContact> xeroContactMap = new Map<String , RestResponseCollectionXero.XeroContact>();
        
        for(Integer ctr = 0; ctr < xeroContactIdList.size(); ctr++)
        {
            XeroAddressParams addressParams = new XeroAddressParams();
            addressParams.AddressType = CONSTANTS_BRIC.INTEGRATION_XERO_ADDRESS_ADDRESS_TYPE_STREET;
            addressParams.AddressLine1 = 'testStreet';
            addressParams.City = 'testCity';
            addressParams.Region = 'testRegion';
            addressParams.PostalCode = '1111';
            addressParams.Country = 'testCountry';
            
            RestResponseCollectionXero.XeroContact xeroContact = new RestResponseCollectionXero.XeroContact();
            xeroContact.Name = 'testXeroContact' + ctr;
            xeroContact.ContactID = xeroContactIdList[0];
            xeroContact.Addresses = new List<RestResponseCollectionXero.Address>{GenerateXeroAddress(addressParams)};
            xeroContact.Phones = new List<RestResponseCollectionXero.Phone>{GenerateXeroPhone(CONSTANTS_BRIC.INTEGRATION_XERO_PHONE_PHONE_TYPE_DEFAULT , '1111'),
                                                                            GenerateXeroPhone(CONSTANTS_BRIC.INTEGRATION_XERO_PHONE_PHONE_TYPE_FAX , '2222')};  
                
            xeroContactMap.put(xeroContact.ContactID , xeroContact);
        }
        
        return xeroContactMap;
    }
    
    private static Map<String , RestResponseCollectionXero.Invoice> GenerateXeroInvoiceMap(List<Opportunity> oppList)
    {
        Map<String , RestResponseCollectionXero.Invoice> xeroInvoiceMap = new Map<String , RestResponseCollectionXero.Invoice>();
        
        for(Opportunity opp : oppList)
        {
            RestResponseCollectionXero.Invoice xeroInvoice = new RestResponseCollectionXero.Invoice();
            xeroInvoice.InvoiceID = opp.XeroId__c;
            xeroInvoice.Reference = opp.Id;
            xeroInvoice.DueDateString = invoiceDueDate;
            xeroInvoice.LineItems = GenerateXeroInvoiceLineItemList(opp.OpportunityLineItems);
            
            xeroInvoiceMap.put(opp.XeroId__c , xeroInvoice);
        }
        
        return xeroInvoiceMap;
    }
    
    private static List<RestResponseCollectionXero.LineItem> GenerateXeroInvoiceLineItemList(List<OpportunityLineItem> oppLineItemList)
    {
        List<RestResponseCollectionXero.LineItem> xeroInvoiceLineItemList = new List<RestResponseCollectionXero.LineItem>();
        
        for(OpportunityLineItem oppLineItem : oppLineItemList)
        {
            RestResponseCollectionXero.LineItem xeroInvoiceLineItem = new RestResponseCollectionXero.LineItem();
            xeroInvoiceLineItem.Description = oppLineItem.Id;
            xeroInvoiceLineItem.LineItemID = oppLineItem.XeroId__c;
            xeroInvoiceLineItem.UnitAmount = invoiceLineItemAmount;
            xeroInvoiceLineItem.Quantity = invoiceLineItemQuantity;
            xeroInvoiceLineItemList.add(xeroInvoiceLineItem);
        }
        
        return xeroInvoiceLineItemList;
    }
    
    private static RestResponseCollectionXero.Address GenerateXeroAddress(XeroAddressParams addressParams)
    {
        RestResponseCollectionXero.Address xeroAddress = new RestResponseCollectionXero.Address();
        xeroAddress.AddressType = addressParams.AddressType;
        xeroAddress.AddressLine1 = addressParams.AddressLine1;
        xeroAddress.City = addressParams.City;
        xeroAddress.Region = addressParams.Region;
        xeroAddress.PostalCode = addressParams.PostalCode;
        xeroAddress.Country = addressParams.Country;
        
        return xeroAddress;
    }
    
    private static RestResponseCollectionXero.Phone GenerateXeroPhone(String phoneType , String phoneNumber)
    {
        RestResponseCollectionXero.Phone phone = new RestResponseCollectionXero.Phone();
        phone.PhoneType = phoneType;
        phone.PhoneNumber = phoneNumber;
        
        return phone;
    }
    
    @isTest
    private static void DoPostContactSuccess()
    {
        List<String> xeroContactIdList = new List<String>{xeroContactId1 , xeroContactId2 , xeroContactId3};
        
        XeroAPIRequestCollection.PostRequestContact webhookRequestBody = new XeroAPIRequestCollection.PostRequestContact();
        webhookRequestBody.events = SetWebhookEvents(xeroContactIdList, CONSTANTS_BRIC.INTEGRATION_XERO_EVENT_TYPE_UPDATE , CONSTANTS_BRIC.INTEGRATION_XERO_EVENT_CATEGORY_CONTACT);
        
        Map<String , RestResponseCollectionXero.XeroContact> xeroContactMap = GenerateXeroContactMap(xeroContactIdList);
        
        RestResponseCollectionXero.GetContactResponseBody getContactResponse = new RestResponseCollectionXero.GetContactResponseBody();
        getContactResponse.Contacts = xeroContactMap.values();
        
        MockResponse response = new MockResponse(CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_200 , JSON.serialize(getContactResponse));
        
        String webhookRequestBodyString = JSON.serialize(webhookRequestBody);
        
        RestRequest xeroRequest = new RestRequest();
        xeroRequest.requestURI = 'https://test.com';
        xeroRequest.httpMethod = CONSTANTS_BRIC.INTEGRATION_REST_METHOD_POST;
        xeroRequest.requestBody = Blob.valueOf(webhookRequestBodyString);
        
        RestContext.request = xeroRequest;
        
        test.startTest();
        
        test.setMock(HttpCalloutMock.class, response);
        XeroAPI.DoPost();
        
        test.stopTest();
        
        List<XeroWebhookStorage__c> xeroWebhookStorageInsertedList = [SELECT Id FROM XeroWebhookStorage__c];
        List<Account> acctUpdatedList = [SELECT Name, XeroId__c FROM Account WHERE XeroId__c IN :xeroContactMap.keySet()];
        
        System.assert(!xeroWebhookStorageInsertedList.isEmpty());
        System.assertEquals(webhookRequestBody.events.size() , xeroWebhookStorageInsertedList.size());
        System.assert(!acctUpdatedList.isEmpty());
        
        for(Account acctRecord : acctUpdatedList)
        {
            RestResponseCollectionXero.XeroContact xeroContact = xeroContactMap.get(acctRecord.XeroId__c);
            
            System.assert(xeroContact != NULL);
            //System.assertEquals(xeroContact.Name, acctRecord.Name);
        }
    }
    
    @isTest
    private static void DoPostContactFail()
    {
        List<String> xeroContactIdList = new List<String>{xeroContactId1 , xeroContactId2 , xeroContactId3};
        MockResponse response = new MockResponse(CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_400 , NULL);
        
        RestRequest xeroRequest = new RestRequest();
        xeroRequest.requestURI = 'https://test.com';
        xeroRequest.httpMethod = CONSTANTS_BRIC.INTEGRATION_REST_METHOD_POST;
        
        RestContext.request = xeroRequest;
        
        test.startTest();
        
        test.setMock(HttpCalloutMock.class, response);
        XeroAPI.DoPost();
        
        test.stopTest();
        
        List<XeroWebhookStorage__c> xeroWebhookStorageInsertedList = [SELECT Id FROM XeroWebhookStorage__c];
        
        System.assert(xeroWebhookStorageInsertedList.isEmpty());
    }
    
    @isTest
    private static void UpdateAccountAsyncFromXero()
    {
        List<String> xeroContactIdList = new List<String>{xeroContactId1 , xeroContactId2 , xeroContactId3};
        Map<String , RestResponseCollectionXero.XeroContact> xeroContactMap = GenerateXeroContactMap(xeroContactIdList);
        
        test.startTest();
        
        AsyncUpdateFromXero updateFromXero = new AsyncUpdateFromXero();
        updateFromXero.InstantiateProperties();
        updateFromXero.SetUpdateToRun(CONSTANTS_BRIC.SOBJECT_ACCOUNT); 
        updateFromXero.SetXeroObjectList(xeroContactMap.values());
        updateFromXero.SetXeroIdList(xeroContactIdList);
        
        System.enqueueJob(updateFromXero);
        
        test.stopTest();
        
        List<Account> acctUpdatedList = [SELECT Name, XeroId__c FROM Account WHERE XeroId__c IN :xeroContactMap.keySet()];
        
        System.assert(!acctUpdatedList.isEmpty());
        
        for(Account acctRecord : acctUpdatedList)
        {
            RestResponseCollectionXero.XeroContact xeroContact = xeroContactMap.get(acctRecord.XeroId__c);
            
            System.assert(xeroContact != NULL);
            System.assertEquals(xeroContact.Name, acctRecord.Name);
        }
    }
    
    @isTest
    private static void DoPostInvoiceSuccess()
    {
        List<String> xeroInvoiceIdList = new List<String>{xeroInvoiceId};
        Map<String , RestResponseCollectionXero.Invoice> xeroInvoiceMap = GenerateXeroInvoiceMap([SELECT Id, XeroId__c, (SELECT Id, XeroId__c FROM OpportunityLineItems) FROM Opportunity]);
            
        XeroAPIRequestCollection.PostRequestContact webhookRequestBody = new XeroAPIRequestCollection.PostRequestContact();
        webhookRequestBody.events = SetWebhookEvents(xeroInvoiceIdList, CONSTANTS_BRIC.INTEGRATION_XERO_EVENT_TYPE_UPDATE , CONSTANTS_BRIC.INTEGRATION_XERO_EVENT_CATEGORY_INVOICE);
        
        RestResponseCollectionXero.GetInvoiceResponseBody getInvoiceResponseBody = new RestResponseCollectionXero.GetInvoiceResponseBody();
        getInvoiceResponseBody.Invoices = xeroInvoiceMap.values();
        
        MockResponse response = new MockResponse(CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_200 , JSON.serialize(getInvoiceResponseBody));
        
        String webhookRequestBodyString = JSON.serialize(webhookRequestBody);
        
        RestRequest xeroRequest = new RestRequest();
        xeroRequest.requestURI = 'https://test.com';
        xeroRequest.httpMethod = CONSTANTS_BRIC.INTEGRATION_REST_METHOD_POST;
        xeroRequest.requestBody = Blob.valueOf(webhookRequestBodyString);
        
        RestContext.request = xeroRequest;
        
        test.startTest();
        
        test.setMock(HttpCalloutMock.class, response);
        XeroAPI.DoPost();
        
        test.stopTest();
        
        List<XeroWebhookStorage__c> xeroWebhookStorageInsertedList = [SELECT Id FROM XeroWebhookStorage__c];
        List<Opportunity> oppUpdatedList = [SELECT 
                                                Name, XeroId__c, CloseDate,
                                                (SELECT Quantity, UnitPrice FROM OpportunityLineItems)
                                            FROM Opportunity WHERE XeroId__c IN :xeroInvoiceIdList];
        
        System.assert(!xeroWebhookStorageInsertedList.isEmpty());
        System.assertEquals(webhookRequestBody.events.size() , xeroWebhookStorageInsertedList.size());
        System.assert(!oppUpdatedList.isEmpty());
        
        for(Opportunity oppRecord : oppUpdatedList)
        {
            RestResponseCollectionXero.Invoice xeroInvoice = xeroInvoiceMap.get(oppRecord.XeroId__c);
            
            System.assert(xeroInvoice != NULL);
            System.assertEquals(Date.valueOf(invoiceDueDate + CONSTANTS_BRIC.GENERIC_SPACE + CONSTANTS_BRIC.DATE_AND_TIME_TIME_EXTENSION), oppRecord.CloseDate);
            
            for(OpportunityLineItem oppLineItem : oppRecord.OpportunityLineItems)
            {
                System.assertEquals(invoiceLineItemQuantity, oppLineItem.Quantity);
                System.assertEquals(invoiceLineItemAmount, oppLineItem.UnitPrice);
            }
        }
    }
    
    @isTest
    private static void DoPostInvoiceFail()
    {
        List<String> xeroInvoiceIdList = new List<String>{xeroInvoiceId};
        MockResponse response = new MockResponse(CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_400 , NULL);
        
        RestRequest xeroRequest = new RestRequest();
        xeroRequest.requestURI = 'https://test.com';
        xeroRequest.httpMethod = CONSTANTS_BRIC.INTEGRATION_REST_METHOD_POST;
        
        RestContext.request = xeroRequest;
        
        test.startTest();
        
        test.setMock(HttpCalloutMock.class, response);
        XeroAPI.DoPost();
        
        test.stopTest();
        
        List<XeroWebhookStorage__c> xeroWebhookStorageInsertedList = [SELECT Id FROM XeroWebhookStorage__c];
        
        System.assert(xeroWebhookStorageInsertedList.isEmpty());
    }
    
    @isTest
    private static void UpdateOpportunityAsyncFromXero()
    {
        List<String> xeroInvoiceIdList = new List<String>{xeroInvoiceId};
        Map<String , RestResponseCollectionXero.Invoice> xeroInvoiceMap = GenerateXeroInvoiceMap([SELECT Id, XeroId__c, (SELECT Id, XeroId__c FROM OpportunityLineItems) FROM Opportunity]);
        
        test.startTest();
        
        AsyncUpdateFromXero updateFromXero = new AsyncUpdateFromXero();
        updateFromXero.InstantiateProperties();
        updateFromXero.SetUpdateToRun(CONSTANTS_BRIC.SOBJECT_OPPORTUNITY); 
        updateFromXero.SetXeroObjectList(xeroInvoiceMap.values());
        updateFromXero.SetXeroIdList(xeroInvoiceIdList);
        
        System.enqueueJob(updateFromXero);
        
        test.stopTest();
        
        List<Opportunity> oppUpdatedList = [SELECT 
                                                Name, XeroId__c, CloseDate,
                                                (SELECT Quantity, UnitPrice FROM OpportunityLineItems)
                                            FROM Opportunity WHERE XeroId__c IN :xeroInvoiceIdList];

        System.assert(!oppUpdatedList.isEmpty());
        
        for(Opportunity oppRecord : oppUpdatedList)
        {
            RestResponseCollectionXero.Invoice xeroInvoice = xeroInvoiceMap.get(oppRecord.XeroId__c);
            
            System.assert(xeroInvoice != NULL);
            System.assertEquals(Date.valueOf(invoiceDueDate + CONSTANTS_BRIC.GENERIC_SPACE + CONSTANTS_BRIC.DATE_AND_TIME_TIME_EXTENSION), oppRecord.CloseDate);
            
            for(OpportunityLineItem oppLineItem : oppRecord.OpportunityLineItems)
            {
                System.assertEquals(invoiceLineItemQuantity, oppLineItem.Quantity);
                System.assertEquals(invoiceLineItemAmount, oppLineItem.UnitPrice);
            }
        }
    }
    }