/*
 * Author:          Bricoleur Technologies
 * Created Date:    July 23, 2021
 * Description:     Apex Test Class for XeroGetQuoteBatch
 * Test Class:      N/A
 * History:         July 23, 2021 - Creation
*/
@isTest
public class XeroGetQuoteBatchTest_NPA 
{
    @testSetup
    private static void Setup()
    {
        List<Account> testAcctList = TestDataFactory.CreateAccounts(3 , TRUE);
        
        Contact testCon = TestDataFactory.CreateContacts(1 , testAcctList[0].Id, TRUE)[0];
        Opportunity testOpp = TestDataFactory.CreateOpportunities(1 , testAcctList[0].Id , testCon.Id , TRUE)[0];
        Quote testQuote = new Quote();
        testQuote.OpportunityId = testOpp.Id;
        testQuote.Name = 'Test Quote';
        testQuote.Xero_Quote_Id__c = 'Q11111';
        insert testQuote;
        
        List<Product2> testProductList = TestDataFactory.CreateProducts(3 , TRUE);
        Id pricebookId = Test.getStandardPricebookId();
        testOpp.Xero_Quote_Id__c = 'Q11111';
        update testOpp;

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
        
        XeroAPISettings__c xeroAPISettings = new XeroAPISettings__c();
        xeroAPISettings.Name = Label.Xero_Setting;
        xeroAPISettings.Endpoint__c = 'callout:Xero_App/api.xro/2.0';
        
        Insert xeroAPISettings;

        XeroQuoteBatchSettings__c xeroQuoteSettings = new XeroQuoteBatchSettings__c();
        xeroQuoteSettings.Name = 'XeroQuoteBatchSetting';
        xeroQuoteSettings.LastSycnedDateTime__c = system.now();
        insert xeroQuoteSettings;
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
    
    private static RestResponseCollectionXero.XeroTenantIdResponseBody SetXeroTenantIdResponseBody(String testTenantId)
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
        
    @isTest
    private static void SyncOpptyToXeroQuote()
    {
        
        String tenantId = 'testTenantId';
        SetTenantId(tenantId);
        
        Id quoteId = [SELECT Id FROM Quote LIMIT 1].Id;
        
        test.startTest();
        
        LWCObjects.ResponseToast response = SyncWithXeroController_NoPersonAccount.SendToXero(quoteId , 'Quote');
        
        test.stopTest();
        
        System.assertEquals(CONSTANTS_BRIC.GENERIC_UPPERCASE_SUCCESS, response.Title);
        System.assertEquals(CONSTANTS_BRIC.TOAST_XERO_SYNC_SUCCESSFUL, response.Message);
        System.assertEquals(CONSTANTS_BRIC.GENERIC_SUCCESS, response.Result);
    }
    
     @isTest
    private static void PostQuoteSuccess()
    {
        String tenantId = 'testTenantId';
        SetTenantId(tenantId);

        Opportunity oppty = [SELECT Id,AccountId,Name FROM Opportunity WHERE Xero_Quote_Id__c != NULL LIMIT 1];
        oppty.Xero_Quote_Id__c = '';
        update oppty;
                
        Quote quoteItem = [SELECT Id,AccountId,Name FROM Quote WHERE Xero_Quote_Id__c != NULL LIMIT 1];
        
        Account acc = new Account();
        acc.Id = oppty.AccountId;
        acc.XeroId__c= '11111';
        OpportunityLineItem oli = [SELECT Id,XeroId__c,Product2Id FROM OpportunityLineItem 
                                    WHERE OpportunityId =: oppty.Id LIMIT 1];
        oli.XeroId__c = 'Item1';
        update oli;
        Product2 prod = [SELECT Id,ProductCode FROM Product2 WHERE Id =: oli.Product2Id LIMIT 1 ];
        prod.ProductCode = 'Item1';
        update prod;

        String quoteId = 'Q11111';
        RestResponseCollectionXero.Quote xeroQuote = new RestResponseCollectionXero.Quote();
        xeroQuote.QuoteID = quoteId;
        xeroQuote.DateString = '2021-07-23T00:00:00';
        xeroQuote.ExpiryDateString = '2021-07-23T00:00:00';

        RestResponseCollectionXero.LineItem xeroQuoteLineItem = new RestResponseCollectionXero.LineItem();
        xeroQuoteLineItem.LineItemID = 'Item1';
        xeroQuoteLineItem.ItemCode = 'Item1';
        xeroQuote.LineItems = new List<RestResponseCollectionXero.LineItem>{xeroQuoteLineItem};

        RestResponseCollectionXero.PostQuoteResponseBody postQuoteResponseBody = new RestResponseCollectionXero.PostQuoteResponseBody();
        postQuoteResponseBody.Quotes = new List<RestResponseCollectionXero.Quote>{xeroQuote};
            
        MockResponse response = new MockResponse(CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_200 , JSON.serialize(postQuoteResponseBody));
        
        XeroReqFlowLineItemParams lineitemParam = new XeroReqFlowLineItemParams();
        lineitemParam.LineItemId = 'Item1';
        lineitemParam.ItemCode = 'Item1';        
            
        XeroReqFlowParamsQuote xeroReqQuote = new XeroReqFlowParamsQuote();
        xeroReqQuote.QuoteNumber = 'Q11111';
        xeroReqQuote.QuoteContactID = '11111';
        xeroReqQuote.Date_x = String.valueOf(Date.today());
        xeroReqQuote.Status = 'Draft';
        xeroReqQuote.lineItems = new List<XeroReqFlowLineItemParams>{lineitemParam};    
        xeroReqQuote.SubTotal = 100;
        xeroReqQuote.TotalTax = 100;
        xeroReqQuote.Total = 100;
        xeroReqQuote.Title = quoteItem.Name;
        xeroReqQuote.Summary = 'Summary';
        xeroReqQuote.LineAmountTypes = 'Inclusive';
        xeroReqQuote.SalesforceRecordId = quoteItem.Id;

        test.startTest();
        
        test.setMock(HttpCalloutMock.class, response);
        XeroPostQuoteRequestFlow.SendOpportunityToXeroQuoteFlow(new List<XeroReqFlowParamsQuote>{xeroReqQuote});
        test.stopTest();
    }
    
        
    @isTest
    private static void GetQuoteSuccess()
    {
        String tenantId = 'testTenantId';
        SetTenantId(tenantId);
        
        Opportunity oppty = [SELECT Id,AccountId,Name FROM Opportunity WHERE Xero_Quote_Id__c != NULL LIMIT 1];
        Quote quoteItem = [SELECT Id,AccountId,Name FROM Quote WHERE Xero_Quote_Id__c != NULL LIMIT 1];

        Account acc = new Account();
        acc.Id = oppty.AccountId;
        acc.XeroId__c= '11111';
        OpportunityLineItem oli = [SELECT Id,XeroId__c,Product2Id FROM OpportunityLineItem 
                                    WHERE OpportunityId =: oppty.Id LIMIT 1];
        oli.XeroId__c = 'Item1';
        update oli;
        Product2 prod = [SELECT Id,ProductCode FROM Product2 WHERE Id =: oli.Product2Id LIMIT 1 ];
        prod.ProductCode = 'Item1';
        update prod;

        String quoteId = 'Q11111';
        RestResponseCollectionXero.Quote xeroQuote = new RestResponseCollectionXero.Quote();
        xeroQuote.QuoteID = quoteId;
        xeroQuote.DateString = '2021-07-23T00:00:00';
        xeroQuote.ExpiryDateString = '2021-07-23T00:00:00';

        RestResponseCollectionXero.LineItem xeroQuoteLineItem = new RestResponseCollectionXero.LineItem();
        xeroQuoteLineItem.LineItemID = 'Item1';
        xeroQuoteLineItem.ItemCode = 'Item1';
        xeroQuote.LineItems = new List<RestResponseCollectionXero.LineItem>{xeroQuoteLineItem};

        RestResponseCollectionXero.PostQuoteResponseBody postQuoteResponseBody = new RestResponseCollectionXero.PostQuoteResponseBody();
        postQuoteResponseBody.Quotes = new List<RestResponseCollectionXero.Quote>{xeroQuote};
            
        MockResponse response = new MockResponse(CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_200 , JSON.serialize(postQuoteResponseBody));
        
        XeroReqFlowParamsQuote xeroReqQuote = new XeroReqFlowParamsQuote();
        xeroReqQuote.QuoteId = 'Q11111';
        xeroReqQuote.QuoteNumber = 'Q11111';
        xeroReqQuote.QuoteContactID = '11111';
        xeroReqQuote.Date_x = String.valueOf(Date.today());
        xeroReqQuote.Status = 'Draft';
        xeroReqQuote.lineItems = new List<XeroReqFlowLineItemParams>();    
        xeroReqQuote.SubTotal = 100;
        xeroReqQuote.TotalTax = 100;
        xeroReqQuote.Total = 100;
        xeroReqQuote.Title = quoteItem.Name;
        xeroReqQuote.Summary = 'Summary';
        xeroReqQuote.LineAmountTypes = 'Inclusive';
        xeroReqQuote.SalesforceRecordId = quoteItem.Id;

        test.startTest();
        
        test.setMock(HttpCalloutMock.class, response);
        XeroPostQuoteRequestFlow.SendOpportunityToXeroQuoteFlow(new List<XeroReqFlowParamsQuote>{xeroReqQuote});
        test.stopTest();
    }
    
    @isTest
    private static void GetXeroQuoteBatch()
    {
        String tenantId = 'testTenantId';
        SetTenantId(tenantId);

        Opportunity oppty = [SELECT Id FROM Opportunity LIMIT 1];
        OpportunityLineItem oli = [SELECT Id,XeroId__c,Product2Id FROM OpportunityLineItem 
                                    WHERE OpportunityId =: oppty.Id LIMIT 1];
        oli.XeroId__c = 'Item1';
        update oli;
        Product2 prod = [SELECT Id,ProductCode FROM Product2 WHERE Id =: oli.Product2Id LIMIT 1 ];
        prod.ProductCode = 'Item1';
        update prod;

        String quoteId = 'Q11111';
        RestResponseCollectionXero.Quote xeroQuote = new RestResponseCollectionXero.Quote();
        xeroQuote.QuoteID = quoteId;
        xeroQuote.DateString = '2021-07-23T00:00:00';

        RestResponseCollectionXero.LineItem xeroQuoteLineItem = new RestResponseCollectionXero.LineItem();
        xeroQuoteLineItem.LineItemID = 'Item1';
        xeroQuoteLineItem.ItemCode = 'Item1';
        xeroQuote.LineItems = new List<RestResponseCollectionXero.LineItem>{xeroQuoteLineItem};

        RestResponseCollectionXero.PostQuoteResponseBody postQuoteResponseBody = new RestResponseCollectionXero.PostQuoteResponseBody();
        postQuoteResponseBody.Quotes = new List<RestResponseCollectionXero.Quote>{xeroQuote};
            
        MockResponse response = new MockResponse(CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_200 , JSON.serialize(postQuoteResponseBody));
        
        XeroReqFlowParamsQuote xeroReqQuote = new XeroReqFlowParamsQuote();
        xeroReqQuote.QuoteId = 'Q11111';
            
        test.startTest();        
        test.setMock(HttpCalloutMock.class, response);
        XeroGetQuoteBatch batch= new XeroGetQuoteBatch();
        Id jobid= Database.executeBatch(batch,1);
        test.stopTest();
        
    }
    
    
    @isTest
    private static void GetXeroQuoteBatchSchedulable()
    {
        String tenantId = 'testTenantId';
        SetTenantId(tenantId);

        Opportunity oppty = [SELECT Id FROM Opportunity LIMIT 1];
        OpportunityLineItem oli = [SELECT Id,XeroId__c,Product2Id FROM OpportunityLineItem 
                                    WHERE OpportunityId =: oppty.Id LIMIT 1];
        oli.XeroId__c = 'Item1';
        update oli;
        Product2 prod = [SELECT Id,ProductCode FROM Product2 WHERE Id =: oli.Product2Id LIMIT 1 ];
        prod.ProductCode = 'Item1';
        update prod;

        String quoteId = 'Q11111';
        RestResponseCollectionXero.Quote xeroQuote = new RestResponseCollectionXero.Quote();
        xeroQuote.QuoteID = quoteId;
        xeroQuote.DateString = '2021-07-23T00:00:00';

        RestResponseCollectionXero.LineItem xeroQuoteLineItem = new RestResponseCollectionXero.LineItem();
        xeroQuoteLineItem.LineItemID = 'Item1';
        xeroQuoteLineItem.ItemCode = 'Item1';
        xeroQuote.LineItems = new List<RestResponseCollectionXero.LineItem>{xeroQuoteLineItem};

        RestResponseCollectionXero.PostQuoteResponseBody postQuoteResponseBody = new RestResponseCollectionXero.PostQuoteResponseBody();
        postQuoteResponseBody.Quotes = new List<RestResponseCollectionXero.Quote>{xeroQuote};
            
        MockResponse response = new MockResponse(CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_200 , JSON.serialize(postQuoteResponseBody));
        
        XeroReqFlowParamsQuote xeroReqQuote = new XeroReqFlowParamsQuote();
        xeroReqQuote.QuoteId = 'Q11111';
            
        test.startTest();        
        test.setMock(HttpCalloutMock.class, response);
        XeroGetQuoteBatchSchedulable batch= new XeroGetQuoteBatchSchedulable();
        String cronExp = '0 0 23 * * ?';
        system.schedule('Xero Quote Batch', cronExp, batch);
        test.stopTest();
        
    }
    
    
    @isTest
    private static void runXeroGetQuoteBatchTest()
    {
        test.startTest();
        RunXeroGetQuoteBatchCtrl.runXeroGetQuoteBatch();
        test.stopTest();
    }
    
       
}