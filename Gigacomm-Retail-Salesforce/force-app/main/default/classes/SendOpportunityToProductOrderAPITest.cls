@isTest
public class SendOpportunityToProductOrderAPITest {
    
    @isTest static void testSendOpportunityToProductOrderAPI() {
        // Prepare test data
        Account acc = new Account(Name = 'Test Account');
        insert acc;
       

        // Create a Contact for the Account
        Contact con = new Contact(FirstName = 'John', LastName = 'Doe', AccountId = acc.Id, Email = 'john.doe@test.com', MobilePhone = '04444444');
        insert con;
 		SendOpportunityToGigaAPIQueueable.getContactID(acc.Id);
        
        
        // Insert a Product2 and PricebookEntry for OpportunityLineItem
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(Product2Id = prod.Id, Pricebook2Id = pricebookId, UnitPrice = 100, IsActive = true);
        insert pbe;
        
        //Data Product
        //
        Product2 prodData = new Product2(Name = 'Test Product', IsActive = true, Family = 'Data');
        insert prodData;

        PricebookEntry pbeData = new PricebookEntry(Product2Id = prodData.Id, Pricebook2Id = pricebookId, UnitPrice = 100, IsActive = true);
        insert pbeData;

        // Create Opportunity
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = acc.Id, Service_Level_Number_bric__c = '10',
                                         Service_Unit_Number_bric__c = '10', Term_bric__c = '12 Months');
        insert opp;
        
        //Create Opportunity Contact Role
        OpportunityContactRole contactRole = new OpportunityContactRole(ContactId = con.Id, IsPrimary = TRUE, OpportunityId = opp.Id);
        insert contactRole;

        // Add OpportunityLineItem
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id, PricebookEntryId = pbe.Id, Quantity = 1, UnitPrice = 100);
        insert oli;
        
        // Add OpportunityLineItem
        OpportunityLineItem oli2 = new OpportunityLineItem(OpportunityId = opp.Id, PricebookEntryId = pbeData.Id, Quantity = 1, UnitPrice = 100);
        insert oli2;
        
        Test.setMock(HttpCalloutMock.class, new MefPostPOMock());
        
        Test.startTest();
        // Call invocable method with the Opportunity Id
        SendOpportunityToProductOrderAPI.SendOpportunityToProductOrderAPI(new List<Id>{opp.Id});

        // Verify queueable job was enqueued
        List<AsyncApexJob> jobs = [SELECT Id, JobType, Status FROM AsyncApexJob WHERE JobType = 'Queueable' AND Status = 'Queued'];
        System.assert(!jobs.isEmpty(), 'Expected at least one queueable job enqueued.');

        Test.stopTest();
    }
    
    // Mock class for error response
    private class MefPostPOMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"error": "Bad Request"}');
            return res;
        }
    }
}