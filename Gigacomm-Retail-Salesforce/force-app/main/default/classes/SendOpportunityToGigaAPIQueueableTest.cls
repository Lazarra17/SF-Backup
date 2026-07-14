@IsTest
public class SendOpportunityToGigaAPIQueueableTest {
    @IsTest
    static void testQueueableWithContact() {
        // Create test Account
        Account acc = new Account(Name = 'Test Account'
                                  ,Service_Level_Number_bric__c = '123A', Service_Unit_Number_bric__c = '123', Service_Unit_Type_bric__c = '1', Service_Level_Type_bric__c = '1'
                                 );
        insert acc;
        
        // Create a Contact linked to the Account
        Contact con = new Contact(FirstName = 'John', LastName = 'Doe', AccountId = acc.Id, Email = 'john.doe@test.com', MobilePhone = '04444444');
        insert con;
        
        // Create a Product2 for OpportunityLineItem
        Product2 prod = new Product2(Name = 'Test Product', ProductCode = 'TESTPROD', IsActive = true, Family = 'Data');
        insert prod;
        
        // Pricebook2 and PricebookEntry for OpportunityLineItem
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(Product2Id = prod.Id, Pricebook2Id = pricebookId, UnitPrice = 100, IsActive = true);
        insert pbe;
        
        // Create Opportunity linked to Account
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            MefProductOfferingQualificationId_bric__c = 'someQualificationId',
            Term_bric__c = '12 Months'
        );
        insert opp;
        
        // Create OpportunityLineItem
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100
        );
         OpportunityLineItem oli1 = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100
         );
        insert new List<OpportunityLineItem>{oli,oli1};
            
        Test.setMock(HttpCalloutMock.class, new MefProductOrderMock());
        
        // Run the queueable with the Opportunity Id
        Test.startTest();
        System.enqueueJob(new SendOpportunityToGigaAPIQueueable(new List<Id>{opp.Id}));
        Test.stopTest();
        
        Opportunity updatedOpp = [SELECT Id, Mef_Status_bric__c, Mef_Order_Product_Id_bric__c FROM Opportunity WHERE Id = :opp.Id];
        System.assert(updatedOpp != null, 'Opportunity should exist');   
    }
    // Mock class for successful response
    private class MefProductOrderMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            // Construct mock response using GigaOpportunityResponseWrapper
            GigaOpportunityResponseWrapper responseBody = new GigaOpportunityResponseWrapper();
            responseBody.id = 'PO-123';
            responseBody.href = '/api/product-order/PO-123';
            responseBody.orderDate = '2025-05-15T00:00:00Z';
            responseBody.state = 'Acknowledged';
            responseBody.externalId = 'EXT-456';
            responseBody.projectId = 'PROJ-789';
            
            // State Change
            GigaOpportunityResponseWrapper.StateChange stateChange = new GigaOpportunityResponseWrapper.StateChange();
            stateChange.state = 'Acknowledged';
            stateChange.changeDate = '2025-05-15T00:00:00Z';
            responseBody.stateChange = new List<GigaOpportunityResponseWrapper.StateChange>{ stateChange };
                
                // Related Contact Information
                GigaOpportunityResponseWrapper.RelatedContactInformation contactInfo = new GigaOpportunityResponseWrapper.RelatedContactInformation();
            contactInfo.emailAddress = 'test@example.com';
            contactInfo.name = 'John Doe';
            contactInfo.number_x = '1234567890';
            contactInfo.organization = 'TestOrg';
            contactInfo.role = 'Buyer';
            responseBody.relatedContactInformation = new List<GigaOpportunityResponseWrapper.RelatedContactInformation>{ contactInfo };
                
                // Product Order Item
                GigaOpportunityResponseWrapper.ProductOrderItem item = new GigaOpportunityResponseWrapper.ProductOrderItem();
            item.id = 'ITEM-001';
            item.action = 'add';
            item.endCustomerName = 'Customer A';
            item.relatedBuyerPON = 'PO-789';
            item.requestedCompletionDate = '2025-06-01';
            item.agreementName = 'Agreement 1';
            
            // Billing Account
            GigaOpportunityResponseWrapper.BillingAccount billingAccount = new GigaOpportunityResponseWrapper.BillingAccount();
            billingAccount.id = 'BA-001';
            item.billingAccount = billingAccount;
            
            // Product and its nested fields
            GigaOpportunityResponseWrapper.Product product = new GigaOpportunityResponseWrapper.Product();
            
            GigaOpportunityResponseWrapper.ProductOfferingQualificationItem pqItem = new GigaOpportunityResponseWrapper.ProductOfferingQualificationItem();
            pqItem.id = 'POQ-001';
            pqItem.productOfferingQualificationId = 'POQID-001';
            product.productOfferingQualificationItem = pqItem;
            
            GigaOpportunityResponseWrapper.ProductOffering prodOffering = new GigaOpportunityResponseWrapper.ProductOffering();
            prodOffering.id = 'SKU001';
            product.productOffering = prodOffering;
            
            item.product = product;
            responseBody.productOrderItem = new List<GigaOpportunityResponseWrapper.ProductOrderItem>{ item };
                
                // Serialize and return the mock response
                res.setBody(JSON.serialize(responseBody));
            return res;
        }
    }
}