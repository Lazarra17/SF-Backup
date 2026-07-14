/*
 * Author:          Bricoleur Technologies
 * Created Date:    July 15, 2021
 * Description:     Apex Test Class for XeroRequest for No Person Account
 * Test Class:      N/A
 * History:         July 15, 2021 - Creation
*/

@isTest
public class XeroRequestTest_NoPersonAccount 
{
    @testSetup
    private static void Setup()
    {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User userRecord = new User();
        userRecord.FirstName = 'Test';
        userRecord.LastName = 'User';
        userRecord.Alias = 'testuser';
        userRecord.Email='testuser123@bricoleur.com';
        userRecord.EmailEncodingKey='UTF-8';
        userRecord.LanguageLocaleKey='en_US';
        userRecord.LocaleSidKey='en_US';
        userRecord.ProfileId = p.Id;
        userRecord.TimeZoneSidKey='Australia/Sydney';
        userRecord.UserName='testuser123@bricoleur.com';
        insert userRecord;
        
        List<Account> testAcctList = TestDataFactory.CreateAccounts(3 , TRUE);
        
        Contact testCon = TestDataFactory.CreateContacts(1 , testAcctList[0].Id, FALSE)[0];
        //testCon.OwnerId = userRecord.Id;
        //insert testCon;
        
        Opportunity testOpp = TestDataFactory.CreateOpportunities(1 , testAcctList[0].Id , testCon.Id , TRUE)[0];
        List<Product2> testProductList = TestDataFactory.CreateProducts(3 , TRUE);
        Id pricebookId = Test.getStandardPricebookId();
        
        TestDataFactory.PricebookEntryParameters pbEParams1 = SetPricebookEntryParams(pricebookId , testProductList[0].Id , 100);
        TestDataFactory.PricebookEntryParameters pbEParams2 = SetPricebookEntryParams(pricebookId , testProductList[1].Id , 200);
        TestDataFactory.PricebookEntryParameters pbEParams3 = SetPricebookEntryParams(pricebookId , testProductList[2].Id , 300);
        
        List<PricebookEntry> testPbEList = new List<PricebookEntry>{TestDataFactory.CreatePricebookEntries(1 , pbEParams1, FALSE)[0],
                                                                    TestDataFactory.CreatePricebookEntries(1 , pbEParams2, FALSE)[0],
                                                                    TestDataFactory.CreatePricebookEntries(1 , pbEParams3, FALSE)[0]};
                                                                        
        Insert testPbEList;
        
        TestDataFactory.OpportunityLineItemParameters oppLineItemParams1 = SetOppLineItemsParams(testOpp.Id , testPbEList[0].Id , 2 , 100);
        TestDataFactory.OpportunityLineItemParameters oppLineItemParams2 = SetOppLineItemsParams(testOpp.Id , testPbEList[1].Id , 3 , 200);
        TestDataFactory.OpportunityLineItemParameters oppLineItemParams3 = SetOppLineItemsParams(testOpp.Id , testPbEList[2].Id , 1 , 300);
                
        List<OpportunityLineItem> oppLineItemTestList = TestDataFactory.CreateOpportunityLineItems(2 , oppLineItemParams2, FALSE);
        oppLineItemTestList.add(TestDataFactory.CreateOpportunityLineItems(1 , oppLineItemParams1, FALSE)[0]);
        oppLineItemTestList.add(TestDataFactory.CreateOpportunityLineItems(1 , oppLineItemParams3, FALSE)[0]);
        
        Insert oppLineItemTestList;
        
        Schema.SObjectType OrderObject = Schema.getGlobalDescribe().containsKey('Order') ? Schema.Order.getSObjectType() : null;
        if(OrderObject != null){
            Order orderRecord = new Order(AccountId = testAcctList[0].Id, EffectiveDate = date.today(), Status = 'Draft',
                                          Pricebook2Id = pricebookId);
            insert orderRecord;
            
            OrderItem orderItemRecord = new OrderItem(OrderId = orderRecord.Id, PricebookEntryId =testPbEList[0].Id,
                                                      UnitPrice = 100, Quantity = 1);
            insert orderItemRecord;
        }

        XeroAPISettings__c xeroAPISettings = new XeroAPISettings__c();
        xeroAPISettings.Name = Label.Xero_Setting;
        xeroAPISettings.Endpoint__c = 'callout:Xero_App/api.xro/2.0';
        
        Insert xeroAPISettings;
        
        XeroInboundFieldMapping__c contactInboundFieldMapping = new XeroInboundFieldMapping__c();
        contactInboundFieldMapping.Active__c = true;
        contactInboundFieldMapping.Is_Person_Account_Bric__c = false;
        contactInboundFieldMapping.SalesforceObject__c = 'Account';
        contactInboundFieldMapping.XeroObject__c = 'CONTACT';
        contactInboundFieldMapping.FieldMapping__c = 'Name=Name,Phone=Phone,Xero_Email__c=EmailAddress,ABN_Bric__c=TaxNumber,Xero_Contact_First_Name_Bric__c=FirstName,Xero_Contact_Last_Name_Bric__c=LastName,ShippingStreet=poboxAddressLine1,ShippingCity=poboxCity,ShippingState=poboxRegion,ShippingPostalCode=poboxPostalCode,ShippingCountry=poboxCountry,BillingStreet=AddressLine1,BillingCity=City,BillingState=Region,BillingPostalCode=PostalCode,BillingCountry=Country';
        insert contactInboundFieldMapping;
        
        XeroInboundFieldMapping__c invoiceInboundFieldMapping = new XeroInboundFieldMapping__c();
        invoiceInboundFieldMapping.Active__c = true;
        invoiceInboundFieldMapping.Is_Person_Account_Bric__c = false;
        invoiceInboundFieldMapping.SalesforceObject__c = 'Xero_Loading_Object__c';
        invoiceInboundFieldMapping.XeroObject__c = 'INVOICE';
        invoiceInboundFieldMapping.FieldMapping__c = 'Total__c=Total,InvoiceNumber__c=InvoiceNumber,InvoiceID__c=InvoiceID,ContactID__c=ContactId,ContactStatus__c=ContactStatus,Status__c=Status,EmailAddress__c=EmailAddress,DueDate__c=DueDateString,AmountDue__c=AmountDue,SubTotal__c=SubTotal,TotalTax__c=TotalTax,Reference__c=Reference,ContactName__c=ContactName,Date__c=DateString,Invoice_Type__c=Type,AmountPaid__c=AmountPaid';
        insert invoiceInboundFieldMapping;
        
        XeroInboundFieldMapping__c invoiceItemInboundFieldMapping = new XeroInboundFieldMapping__c();
        invoiceItemInboundFieldMapping.Active__c = true;
        invoiceItemInboundFieldMapping.Is_Person_Account_Bric__c = false;
        invoiceItemInboundFieldMapping.SalesforceObject__c = 'Xero_Line_Item_Load__c';
        invoiceItemInboundFieldMapping.XeroObject__c = 'INVOICE LINE ITEM';
        invoiceItemInboundFieldMapping.SalesforceLookupField__c ='Xero_Loading_Object__c';
        invoiceItemInboundFieldMapping.FieldMapping__c = 'UnitAmount__c=UnitAmount,TaxAmount__c=TaxAmount,LineItemID__c=LineItemID,Quantity__c=Quantity,ItemCode__c=ItemCode,LineAmount__c=LineAmount,TaxType__c=Taxtype,AccountCode__c=AccountCode,Description__c=Description';
        insert invoiceItemInboundFieldMapping;
                
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
    
    public static RestResponseCollectionXero.XeroTenantIdResponseBody SetXeroTenantIdResponseBody(String testTenantId)
    {
        RestResponseCollectionXero.XeroTenantIdResponseBody responseBody = new RestResponseCollectionXero.XeroTenantIdResponseBody();
        responseBody.id = 'testId';
        responseBody.authEventId = 'testAuthEventId';
        responseBody.tenantId = testTenantId;
        responseBody.tenantType = 'testTenantType';
        responseBody.tenantName = 'testTenantName';
        responseBody.createdDateUtc = '2020-01-01';
        responseBody.updatedDateUtc = '2020-01-01';
        
        return responseBody;
    }
    
    private static void SetTenantId(String tenantId)
    {
        XeroAPISettings__c xeroAPISettings = XeroAPISettings__c.getInstance(Label.Xero_Setting);
        if(xeroAPISettings != NULL)
        {
            xeroAPISettings.TenantId__c = tenantId;
            Database.Update(xeroAPISettings);
        }
    }
    
    private static void SetInvoiceLineItems(List<OpportunityLineItem> oppLineItemList , XeroReqFlowParamsInvoice paramsInvoice , RestResponseCollectionXero.Invoice xeroInvoice , List<String> invoiceLineItemXeroIdList)
    {
        for(Integer ctr = 0; ctr < oppLineItemList.size(); ctr++)
        {
            XeroReqFlowLineItemParams paramsInvoiceLineItem = new XeroReqFlowLineItemParams();
            paramsInvoiceLineItem.Description = oppLineItemList[ctr].Id;
            paramsInvoice.LineItems.add(paramsInvoiceLineItem);
            
            String invoiceLineItemId = '11111' + ctr;
            invoiceLineItemXeroIdList.add(invoiceLineItemId);
            
            RestResponseCollectionXero.LineItem lineItem = new RestResponseCollectionXero.LineItem();
            lineItem.Description = oppLineItemList[ctr].Id;
            lineItem.LineItemID = invoiceLineItemId;
            xeroInvoice.LineItems.add(lineItem);
        }  
    }
    
    private static void SetInvoiceLineItemsFromOrder(List<OrderItem> ordLineItemList , XeroReqFlowParamsInvoice paramsInvoice , RestResponseCollectionXero.Invoice xeroInvoice , List<String> invoiceLineItemXeroIdList)
    {
        for(Integer ctr = 0; ctr < ordLineItemList.size(); ctr++)
        {
            XeroReqFlowLineItemParams paramsInvoiceLineItem = new XeroReqFlowLineItemParams();
            paramsInvoiceLineItem.Description = ordLineItemList[ctr].Id;
            paramsInvoice.LineItems.add(paramsInvoiceLineItem);
            
            String invoiceLineItemId = '11111' + ctr;
            invoiceLineItemXeroIdList.add(invoiceLineItemId);
            
            RestResponseCollectionXero.LineItem lineItem = new RestResponseCollectionXero.LineItem();
            lineItem.Description = ordLineItemList[ctr].Id;
            lineItem.LineItemID = invoiceLineItemId;
            xeroInvoice.LineItems.add(lineItem);
        }  
    }
    
    private static void SetPOLineItemsFromOrder(List<OrderItem> ordLineItemList , XeroReqFlowParamsPurchaseOrder paramsPO , RestResponseCollectionXero.PurchaseOrder xeroPO , List<String> poLineItemXeroIdList)
    {
        for(Integer ctr = 0; ctr < ordLineItemList.size(); ctr++)
        {
            XeroReqFlowLineItemParams paramsPOLineItem = new XeroReqFlowLineItemParams();
            paramsPOLineItem.Description = ordLineItemList[ctr].Id;
            paramsPO.LineItems.add(paramsPOLineItem);
            
            String poLineItemId = '11111' + ctr;
            poLineItemXeroIdList.add(poLineItemId);
            
            RestResponseCollectionXero.LineItem lineItem = new RestResponseCollectionXero.LineItem();
            lineItem.Description = ordLineItemList[ctr].Id;
            lineItem.LineItemID = poLineItemId;
            xeroPO.LineItems.add(lineItem);
        }  
    }
    
    @isTest
    private static void GetTenantIdSuccessful()
    {
        String testTenantId = '1111111111111';
        List<RestResponseCollectionXero.XeroTenantIdResponseBody> responseBody = new List<RestResponseCollectionXero.XeroTenantIdResponseBody>{SetXeroTenantIdResponseBody(testTenantId)};
        MockResponse response = new MockResponse(CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_200 , JSON.serialize(responseBody));
        
        test.startTest();
        
        test.setMock(HttpCalloutMock.class, response);
        XeroRequestUtilities.GetTenantId();
        
        test.stopTest();

        System.assertEquals(testTenantId, XeroAPISettings__c.getInstance(Label.Xero_Setting)?.TenantId__c);
    }
    
    @isTest
    private static void GetTenantIdFail()
    {
        MockResponse response = new MockResponse(CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_400 , NULL);
        
        test.startTest();
        
        test.setMock(HttpCalloutMock.class, response);
        XeroRequestUtilities.GetTenantId();
        
        test.stopTest();

        System.assertEquals(NULL, XeroAPISettings__c.getInstance(Label.Xero_Setting)?.TenantId__c);
    }
    
    @isTest
    private static void SyncAccountToXero()
    {
        Id acctId = [SELECT Id FROM Account LIMIT 1].Id;
        
        test.startTest();
        
        LWCObjects.ResponseToast response = SyncWithXeroController_NoPersonAccount.SendToXero(acctId , CONSTANTS_BRIC.SOBJECT_ACCOUNT);
        
        test.stopTest();
        
        System.assertEquals(CONSTANTS_BRIC.GENERIC_UPPERCASE_SUCCESS, response.Title);
        System.assertEquals(CONSTANTS_BRIC.TOAST_XERO_SYNC_SUCCESSFUL, response.Message);
        System.assertEquals(CONSTANTS_BRIC.GENERIC_SUCCESS, response.Result);
    }
    
    @isTest
    private static void SyncAccountToXero_Fail()
    {
        //Id conId = [SELECT Id FROM Contact LIMIT 1].Id;
        
        test.startTest();
        
        LWCObjects.ResponseToast response = SyncWithXeroController_NoPersonAccount.SendToXero('' , '');
        
        test.stopTest();
        
        System.assertEquals(CONSTANTS_BRIC.GENERIC_UPPERCASE_SUCCESS, response.Title);
        System.assertEquals(CONSTANTS_BRIC.TOAST_XERO_SYNC_SUCCESSFUL, response.Message);
        System.assertEquals(CONSTANTS_BRIC.GENERIC_SUCCESS, response.Result);
    }
    
    
    @isTest
    private static void GetAccountFromXero()
    {
        Id acctId = [SELECT Id FROM Account LIMIT 1].Id;
        
        test.startTest();
        
        LWCObjects.ResponseToast response = GetContactFromXeroController_NPA.GetFromXero(acctId);
        
        test.stopTest();
        
        System.assertEquals(CONSTANTS_BRIC.GENERIC_UPPERCASE_SUCCESS, response.Title);
        System.assertEquals(CONSTANTS_BRIC.TOAST_XERO_SYNC_SUCCESSFUL, response.Message);
        System.assertEquals(CONSTANTS_BRIC.GENERIC_SUCCESS, response.Result);
    }
    
    @isTest
    private static void SyncOpportunityToXero()
    {
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        
        test.startTest();
        
        LWCObjects.ResponseToast response = SyncWithXeroController_NoPersonAccount.SendToXero(oppId , CONSTANTS_BRIC.SOBJECT_OPPORTUNITY);
        
        test.stopTest();
        
        System.assertEquals(CONSTANTS_BRIC.GENERIC_UPPERCASE_SUCCESS, response.Title);
        System.assertEquals(CONSTANTS_BRIC.TOAST_XERO_SYNC_SUCCESSFUL, response.Message);
        System.assertEquals(CONSTANTS_BRIC.GENERIC_SUCCESS, response.Result);
    }
    
    @isTest
    private static void GetContactSuccess()
    {
        String tenantId = 'testTenantId';
        SetTenantId(tenantId);
        
        Account acctRecordToUpdate = [SELECT Id FROM Account LIMIT 1];
        
        String xeroId = '11111';
        RestResponseCollectionXero.XeroContact xeroContact = new RestResponseCollectionXero.XeroContact();
        xeroContact.ContactID = xeroId;
        
        RestResponseCollectionXero.PostContactResponseBody postContactResponseBody = new RestResponseCollectionXero.PostContactResponseBody();
        postContactResponseBody.Contacts = new List<RestResponseCollectionXero.XeroContact>{xeroContact};
            
        MockResponse response = new MockResponse(CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_200 , JSON.serialize(postContactResponseBody));
        XeroReqGetFlowParamsContact xeroGetContactParams = new XeroReqGetFlowParamsContact();
        xeroGetContactParams.AccountRecord = acctRecordToUpdate;
        xeroGetContactParams.Parameter = 'testParameter';
        xeroGetContactParams.ParameterValue = 'testValue';
        
        test.startTest();
        
        test.setMock(HttpCalloutMock.class , response);
        XeroSearchContactRequestFlow.SearchContactInXero(new List<XeroReqGetFlowParamsContact>{xeroGetContactParams});
        
        test.stopTest();
        
        Account acctRecord = [SELECT XeroId__c FROM Account WHERE Id = :acctRecordToUpdate.Id];
        
        System.assertEquals(xeroId, acctRecord.XeroId__c);
    }
    
    private static void GetContactFail()
    {
        String tenantId = 'testTenantId';
        SetTenantId(tenantId);
        
        Account acctRecordToUpdate = [SELECT Id FROM Account LIMIT 1];
        
        String xeroId = '11111';
        RestResponseCollectionXero.XeroContact xeroContact = new RestResponseCollectionXero.XeroContact();
        xeroContact.ContactID = xeroId;
            
        MockResponse response = new MockResponse(CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_400 , NULL);
        XeroReqGetFlowParamsContact xeroGetContactParams = new XeroReqGetFlowParamsContact();
        xeroGetContactParams.AccountRecord = acctRecordToUpdate;
        xeroGetContactParams.Parameter = 'testParameter';
        xeroGetContactParams.ParameterValue = 'testValue';
        
        test.startTest();
        
        test.setMock(HttpCalloutMock.class , response);
        XeroSearchContactRequestFlow.SearchContactInXero(new List<XeroReqGetFlowParamsContact>{xeroGetContactParams});
        
        test.stopTest();
        
        Account acctRecord = [SELECT XeroId__c FROM Account WHERE Id = :acctRecordToUpdate.Id];
        
        System.assertNotEquals(xeroId, acctRecord.XeroId__c);
    }
    
    @isTest
    private static void InsertXeroWebhookStorage()
    {
        
        String tenantId = 'testTenantId';
        SetTenantId(tenantId);
        
        XeroWebhookStorage__c webhook = new XeroWebhookStorage__c();
        webhook.Event__c = 'UPDATE';
        webhook.XeroId__c = '111';
        webhook.XeroObject__c = 'Contact';
        
        
        XeroWebhookStorage__c webhook2 = new XeroWebhookStorage__c();
        webhook2.Event__c = 'UPDATE';
        webhook2.XeroId__c = '222';
        webhook2.XeroObject__c = 'Contact';
        
        String xeroId = '11111';
        RestResponseCollectionXero.XeroContact xeroContact = new RestResponseCollectionXero.XeroContact();
        xeroContact.ContactID = xeroId;
        
        RestResponseCollectionXero.PostContactResponseBody postContactResponseBody = new RestResponseCollectionXero.PostContactResponseBody();
        postContactResponseBody.Contacts = new List<RestResponseCollectionXero.XeroContact>{xeroContact};
            
            MockResponse response = new MockResponse(CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_200 , JSON.serialize(postContactResponseBody));
        
        test.startTest();        
        test.setMock(HttpCalloutMock.class, response);
        insert webhook;        
        insert webhook2;      
        test.stopTest();
        
    }
    
     @isTest
    private static void InsertXeroInvoiceWebhookStorage()
    {
        Opportunity oppRecord = [SELECT Id, XeroId__c, (SELECT XeroId__c FROM OpportunityLineItems) FROM Opportunity LIMIT 1];

        String tenantId = 'testTenantId';
        SetTenantId(tenantId);
        
        XeroWebhookStorage__c webhook = new XeroWebhookStorage__c();
        webhook.Event__c = 'UPDATE';
        webhook.XeroId__c = '111';
        webhook.XeroObject__c = 'Invoice';
        
        XeroWebhookStorage__c webhook2 = new XeroWebhookStorage__c();
        webhook.Event__c = 'UPDATE';
        webhook.XeroId__c = '222';
        webhook.XeroObject__c = 'Invoice';
        
        String invoiceXeroId = '1111';
        List<String> invoiceLineItemXeroIdList = new List<String>();
        
        XeroReqFlowParamsInvoice paramsInvoice = new XeroReqFlowParamsInvoice();
        paramsInvoice.LineItems = new List<XeroReqFlowLineItemParams>();
        paramsInvoice.SalesforceID = oppRecord.Id;
        paramsInvoice.EmailToXero = false;
        paramsInvoice.CreateContactInXero = false;   
        paramsInvoice.GetInvoiceAsPDF = true;      
        paramsInvoice.Contact = new XeroReqFlowParamsContact();
        paramsInvoice.Payments = new List<XeroReqFlowParamPayment>();
        
        RestResponseCollectionXero.Invoice xeroInvoice = new RestResponseCollectionXero.Invoice();
        xeroInvoice.InvoiceID = invoiceXeroId;
        RestResponseCollectionXero.LineItem lineItem = new RestResponseCollectionXero.LineItem();
        lineItem.Description = 'description';
        lineItem.LineItemID = '222';
        xeroInvoice.LineItems = new List<RestResponseCollectionXero.LineItem>{lineItem};
        xeroInvoice.Contact = new RestResponseCollectionXero.XeroContact();
        
        RestResponseCollectionXero.PostInvoiceResponseBody invoiceResponse = new RestResponseCollectionXero.PostInvoiceResponseBody();
        invoiceResponse.Invoices = new List<RestResponseCollectionXero.Invoice>{xeroInvoice};
            
            MockResponse response = new MockResponse(CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_200 , JSON.serialize(invoiceResponse));
       
        test.startTest();        
        test.setMock(HttpCalloutMock.class, response);
        insert webhook;        
        insert webhook2;        
        test.stopTest();
        
    }
    
    @isTest
    private static void InsertXeroInvoiceWebhookStorage_Fail()
    {
        Opportunity oppRecord = [SELECT Id, XeroId__c, (SELECT XeroId__c FROM OpportunityLineItems) FROM Opportunity LIMIT 1];
        
        String tenantId = 'testTenantId';
        SetTenantId(tenantId);
        
        XeroWebhookStorage__c webhook = new XeroWebhookStorage__c();
        webhook.Event__c = 'UPDATE';
        webhook.XeroId__c = '111';
        webhook.XeroObject__c = 'Invoice';
        
        XeroWebhookStorage__c webhook2 = new XeroWebhookStorage__c();
        webhook.Event__c = 'UPDATE';
        webhook.XeroId__c = '222';
        webhook.XeroObject__c = 'Invoice';
        
        String invoiceXeroId = '1111';
        List<String> invoiceLineItemXeroIdList = new List<String>();
        
        XeroReqFlowParamsInvoice paramsInvoice = new XeroReqFlowParamsInvoice();
        paramsInvoice.LineItems = new List<XeroReqFlowLineItemParams>();
        paramsInvoice.SalesforceID = oppRecord.Id;
        paramsInvoice.EmailToXero = false;
        paramsInvoice.CreateContactInXero = false;   
        paramsInvoice.GetInvoiceAsPDF = true;      
        paramsInvoice.Contact = new XeroReqFlowParamsContact();
        paramsInvoice.Payments = new List<XeroReqFlowParamPayment>();
        
        RestResponseCollectionXero.Invoice xeroInvoice = new RestResponseCollectionXero.Invoice();
        xeroInvoice.InvoiceID = invoiceXeroId;
        xeroInvoice.LineItems = new List<RestResponseCollectionXero.LineItem>();
        xeroInvoice.Contact = new RestResponseCollectionXero.XeroContact();
        
        SetInvoiceLineItems(oppRecord.OpportunityLineItems , paramsInvoice , xeroInvoice , invoiceLineItemXeroIdList);
        
        RestResponseCollectionXero.PostInvoiceResponseBody invoiceResponse = new RestResponseCollectionXero.PostInvoiceResponseBody();
        invoiceResponse.Invoices = new List<RestResponseCollectionXero.Invoice>{xeroInvoice};
            
            MockResponse response = new MockResponse(CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_400 , JSON.serialize(invoiceResponse));
        
        test.startTest();        
        test.setMock(HttpCalloutMock.class, response);
        insert webhook;        
        insert webhook2;        
        test.stopTest();
        
    }
        
    @isTest
    private static void PostContactSuccess()
    {
        String tenantId = 'testTenantId';
        SetTenantId(tenantId);
        
        Id acctId = [SELECT Id FROM Account LIMIT 1].Id;
        XeroReqFlowParamsContact paramsContact = new XeroReqFlowParamsContact();
        paramsContact.RecordId = acctId;
        paramsContact.PaymentTerms = new XeroReqFlowParamsPaymentTerm();
        paramsContact.PaymentTerms.Sales = new XeroReqFlowParamsBillSalesPaymentTerms();
        paramsContact.PaymentTerms.Sales.Day = 8;
        paramsContact.PaymentTerms.Sales.Type_x = 'AFTER DUE DATE';
        
        
        String xeroId = '11111';
        RestResponseCollectionXero.XeroContact xeroContact = new RestResponseCollectionXero.XeroContact();
        xeroContact.ContactID = xeroId;
        
        RestResponseCollectionXero.PostContactResponseBody postContactResponseBody = new RestResponseCollectionXero.PostContactResponseBody();
        postContactResponseBody.Contacts = new List<RestResponseCollectionXero.XeroContact>{xeroContact};
            
        MockResponse response = new MockResponse(CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_200 , JSON.serialize(postContactResponseBody));
        
        test.startTest();
        
        test.setMock(HttpCalloutMock.class, response);
        XeroPostContactRequestFlow.SendContactToXeroFromFlow(new List<XeroReqFlowParamsContact>{paramsContact});
        
        test.stopTest();
        
        Account acctRecord = [SELECT XeroId__c FROM Account WHERE Id = :acctId];
        
        System.assertEquals(xeroId, acctRecord.XeroId__c);
    }
    
    @isTest
    private static void PostContactFail()
    {
        
        String tenantId = 'testTenantId';
        SetTenantId(tenantId);
        
        Id acctId = [SELECT Id FROM Account LIMIT 1].Id;
        XeroReqFlowParamsContact paramsContact = new XeroReqFlowParamsContact();
        paramsContact.RecordId = acctId;
        
        String xeroId = '11111';
        RestResponseCollectionXero.XeroContact xeroContactResponse = new RestResponseCollectionXero.XeroContact();
        xeroContactResponse.ContactID = xeroId;
            
        MockResponse response = new MockResponse(CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_400 , NULL);
        
        test.startTest();
        
        test.setMock(HttpCalloutMock.class, response);
        XeroPostContactRequestFlow.SendContactToXeroFromFlow(new List<XeroReqFlowParamsContact>{paramsContact});
        
        test.stopTest();
        
        Account acctRecord = [SELECT XeroId__c FROM Account WHERE Id = :acctId];
        
        System.assertNotEquals(xeroId, acctRecord.XeroId__c);
    }
    
    @isTest
    private static void PostInvoiceSuccess()
    {
        String tenantId = 'testTenantId';
        SetTenantId(tenantId);
        
        Opportunity oppRecord = [SELECT Id, XeroId__c, (SELECT XeroId__c FROM OpportunityLineItems) FROM Opportunity LIMIT 1];
        
        String invoiceXeroId = '1111';
        List<String> invoiceLineItemXeroIdList = new List<String>();
        
        XeroReqFlowParamsInvoice paramsInvoice = new XeroReqFlowParamsInvoice();
        paramsInvoice.LineItems = new List<XeroReqFlowLineItemParams>();
        paramsInvoice.SalesforceID = oppRecord.Id;
        paramsInvoice.EmailToXero = false;
        paramsInvoice.CreateContactInXero = false;   
        paramsInvoice.GetInvoiceAsPDF = true;      
        paramsInvoice.Contact = new XeroReqFlowParamsContact();
        paramsInvoice.Payments = new List<XeroReqFlowParamPayment>();
        
        RestResponseCollectionXero.Invoice xeroInvoice = new RestResponseCollectionXero.Invoice();
        xeroInvoice.InvoiceID = invoiceXeroId;
        xeroInvoice.LineItems = new List<RestResponseCollectionXero.LineItem>();
        xeroInvoice.Contact = new RestResponseCollectionXero.XeroContact();
        
        SetInvoiceLineItems(oppRecord.OpportunityLineItems , paramsInvoice , xeroInvoice , invoiceLineItemXeroIdList);
        
        RestResponseCollectionXero.PostInvoiceResponseBody invoiceResponse = new RestResponseCollectionXero.PostInvoiceResponseBody();
        invoiceResponse.Invoices = new List<RestResponseCollectionXero.Invoice>{xeroInvoice};
        
        MockResponse response = new MockResponse(CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_200 , JSON.serialize(invoiceResponse));
            
        test.startTest();
        
        test.setMock(HttpCalloutMock.class, response);
        XeroPostInvoiceRequestFlow.SendOpportunityToXeroFlow(new List<XeroReqFlowParamsInvoice>{paramsInvoice});
        
        test.stopTest();
        
        Opportunity oppRecordToCheck = [SELECT Id, XeroId__c, (SELECT XeroId__c FROM OpportunityLineItems) FROM Opportunity WHERE Id = :oppRecord.Id LIMIT 1];
        
        System.assertEquals(invoiceXeroId, oppRecordToCheck.XeroId__c);
        
    }
    
    @isTest
    private static void PostInvoiceFail()
    {
        String tenantId = 'testTenantId';
        SetTenantId(tenantId);
        
        Opportunity oppRecord = [SELECT Id, XeroId__c, (SELECT XeroId__c FROM OpportunityLineItems) FROM Opportunity LIMIT 1];
        
        String invoiceXeroId = '1111';
        List<String> invoiceLineItemXeroIdList = new List<String>();
        
        XeroReqFlowParamsInvoice paramsInvoice = new XeroReqFlowParamsInvoice();
        paramsInvoice.LineItems = new List<XeroReqFlowLineItemParams>();
        paramsInvoice.SalesforceID = oppRecord.Id;
        paramsInvoice.EmailToXero = false;
        paramsInvoice.CreateContactInXero = false;   
        paramsInvoice.GetInvoiceAsPDF = true; 
        paramsInvoice.Contact = new XeroReqFlowParamsContact();
        paramsInvoice.Payments = new List<XeroReqFlowParamPayment>();
        
        RestResponseCollectionXero.Invoice xeroInvoice = new RestResponseCollectionXero.Invoice();
        xeroInvoice.InvoiceID = invoiceXeroId;
        xeroInvoice.LineItems = new List<RestResponseCollectionXero.LineItem>();
        xeroInvoice.Contact = new RestResponseCollectionXero.XeroContact();
        
        SetInvoiceLineItems(oppRecord.OpportunityLineItems , paramsInvoice , xeroInvoice , invoiceLineItemXeroIdList);
        
        MockResponse response = new MockResponse(CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_400 , NULL);
            
        test.startTest();
        
        test.setMock(HttpCalloutMock.class, response);
        XeroPostInvoiceRequestFlow.SendOpportunityToXeroFlow(new List<XeroReqFlowParamsInvoice>{paramsInvoice});
        
        test.stopTest();
        
        Opportunity oppRecordToCheck = [SELECT Id, XeroId__c, (SELECT XeroId__c FROM OpportunityLineItems) FROM Opportunity WHERE Id = :oppRecord.Id LIMIT 1];
        
        System.assertNotEquals(invoiceXeroId, oppRecordToCheck.XeroId__c);
        
        for(OpportunityLineItem oppLineItems : oppRecordToCheck.OpportunityLineItems)
        {
            System.assert(!invoiceLineItemXeroIdList.contains(oppLineItems.XeroId__c));
        }
    }
    
    @isTest
    private static void PostInvoiceFromOrder_Success()
    {
        Schema.SObjectType OrderObject = Schema.getGlobalDescribe().containsKey('Order') ? Schema.Order.getSObjectType() : null;
        if(OrderObject != null){
            String tenantId = 'testTenantId';
            SetTenantId(tenantId);
            
            Order ordRecord = [SELECT Id, XeroId__c, (SELECT Id FROM OrderItems) FROM Order LIMIT 1];
            
            String invoiceXeroId = '1111';
            List<String> invoiceLineItemXeroIdList = new List<String>();
            
            XeroReqFlowParamsInvoice paramsInvoice = new XeroReqFlowParamsInvoice();
            paramsInvoice.LineItems = new List<XeroReqFlowLineItemParams>();
            paramsInvoice.SalesforceID = ordRecord.Id;
            paramsInvoice.EmailToXero = false;
            paramsInvoice.CreateContactInXero = true;   
            paramsInvoice.GetInvoiceAsPDF = true; 
            
            String xeroId = '11111';
            XeroReqFlowParamsContact paramsContact = new XeroReqFlowParamsContact();
            paramsContact.ContactID = xeroId;
            paramsInvoice.Contact = paramsContact;
                
            XeroReqFlowParamPayment payment = new XeroReqFlowParamPayment();
            payment.Amount = 100;
            paramsInvoice.Payments = new List<XeroReqFlowParamPayment>{payment};
            
            RestResponseCollectionXero.Invoice xeroInvoice = new RestResponseCollectionXero.Invoice();
            xeroInvoice.InvoiceID = invoiceXeroId;
            xeroInvoice.LineItems = new List<RestResponseCollectionXero.LineItem>();
            xeroInvoice.Contact = new RestResponseCollectionXero.XeroContact();
            
            SetInvoiceLineItemsFromOrder(ordRecord.OrderItems , paramsInvoice , xeroInvoice , invoiceLineItemXeroIdList);
            
            RestResponseCollectionXero.PostInvoiceResponseBody invoiceResponse = new RestResponseCollectionXero.PostInvoiceResponseBody();
            invoiceResponse.Invoices = new List<RestResponseCollectionXero.Invoice>{xeroInvoice};
                
                MockResponse response = new MockResponse(CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_200 , JSON.serialize(invoiceResponse));
            
            test.startTest();
            
            test.setMock(HttpCalloutMock.class, response);
            XeroPostInvoiceRequestFlow.SendOpportunityToXeroFlow(new List<XeroReqFlowParamsInvoice>{paramsInvoice});
            
            test.stopTest();
            
            Order ordRecordToCheck = [SELECT Id, XeroId__c, (SELECT Id FROM OrderItems) FROM Order WHERE Id = :ordRecord.Id LIMIT 1];
            
            System.assertEquals(invoiceXeroId, ordRecordToCheck.XeroId__c);
        }
    }
    
    @isTest
    private static void PostPurchaseOrderFromOrder_Success()
    {
        Schema.SObjectType OrderObject = Schema.getGlobalDescribe().containsKey('Order') ? Schema.Order.getSObjectType() : null;
        if(OrderObject != null){
            
            insert new XeroPurchaseOrderSyncSetting__c(Modified_After__c = DateTime.now());                
            String tenantId = 'testTenantId';
            SetTenantId(tenantId);
            
            Order ordRecord = [SELECT Id, XeroId__c, (SELECT Id FROM OrderItems) FROM Order LIMIT 1];
            
            String poXeroId = '1111';
            List<String> poLineItemXeroIdList = new List<String>();
            
            XeroReqFlowParamsPurchaseOrder paramsPO = new XeroReqFlowParamsPurchaseOrder();
            paramsPO.LineItems = new List<XeroReqFlowLineItemParams>();
            paramsPO.SalesforceID = ordRecord.Id;
            
            RestResponseCollectionXero.PurchaseOrder xeroPO = new RestResponseCollectionXero.PurchaseOrder();
            xeroPO.PurchaseOrderId = poXeroId;
            xeroPO.LineItems = new List<RestResponseCollectionXero.LineItem>();
            
            SetPOLineItemsFromOrder(ordRecord.OrderItems , paramsPO , xeroPO , poLineItemXeroIdList);
            
            RestResponseCollectionXero.GetPurchaseOrderResponseBody poResponse = new RestResponseCollectionXero.GetPurchaseOrderResponseBody();
            poResponse.PurchaseOrders = new List<RestResponseCollectionXero.PurchaseOrder>{xeroPO};
                
                MockResponse response = new MockResponse(CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_200 , JSON.serialize(poResponse));
            
            test.startTest();
            
            test.setMock(HttpCalloutMock.class, response);
            XeroPostPurchaseOrderRequestFlow.SendOrderToXeroFlow(new List<XeroReqFlowParamsPurchaseOrder>{paramsPO});
            Database.executeBatch(new XeroGetPurchaseOrderBatch());
            String cronExp = '0 0 * * * ?';
            system.schedule('XeroGetPurchaseOrderBatchSchedulable', cronExp, new XeroGetPurchaseOrderBatchSchedulable());
            test.stopTest();
            
            Order ordRecordToCheck = [SELECT Id, XeroId__c, (SELECT Id FROM OrderItems) FROM Order WHERE Id = :ordRecord.Id LIMIT 1];
          
        }
    }
    

}