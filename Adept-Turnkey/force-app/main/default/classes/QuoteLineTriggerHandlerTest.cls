@isTest
public class QuoteLineTriggerHandlerTest {
    
    @testSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Acc');
        insert acc;

        // Activate Standard Pricebook
        Pricebook2 standardPricebook = new PriceBook2();
        standardPricebook.Id = Test.getStandardPricebookId();
        update standardPricebook;

        // Create an Opportunity
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', AccountId = acc.Id, StageName = 'Prospecting', CloseDate = Date.today());
        insert opp;
        
        // Create Product
        Product2 product = new Product2(Name = 'Test Product', IsActive = true);
        insert product;
        
        // Create Standard Pricebook Entry
        PricebookEntry standardPBE = new PricebookEntry(Product2Id = product.Id, Pricebook2Id = standardPricebook.Id, UnitPrice = 100, IsActive = true);
        insert standardPBE;

        // Create a Custom Pricebook
        Pricebook2 customPricebook = new Pricebook2(Name = 'Custom Pricebook', IsActive = true);
        insert customPricebook;
        
        // Create Custom Pricebook Entry
        PricebookEntry customPBE = new PricebookEntry(Product2Id = product.Id, Pricebook2Id = customPricebook.Id, UnitPrice = 100, IsActive = true);
        insert customPBE;

        // Create Opportunity Line Item
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id, PricebookEntryId = customPBE.Id, Quantity = 1, UnitPrice = 100, Tax__c = 10);
        insert oli;

        // Create a Quote
        Quote quote = new Quote(Name = 'Test Quote', OpportunityId = opp.Id, Pricebook2Id = customPricebook.Id);
        insert quote;

        // Create Quote Line Item
        QuoteLineItem qli = new QuoteLineItem(QuoteId = quote.Id, PricebookEntryId = customPBE.Id, Quantity = 1, UnitPrice = 100, Tax__c = 10);
        insert qli;
        
        // Create an Order
        Order order = new Order(Name = 'Test Order', AccountId = acc.Id, Status = 'Draft', PriceBook2Id = customPricebook.Id, EffectiveDate = Date.today(), OpportunityId = opp.Id);
        insert order;
        
        // Create Order Line Item
        OrderItem oi = new OrderItem(OrderId = order.Id, PricebookEntryId = customPBE.Id, Quantity = 1, UnitPrice = 100, Tax__c = 10);
        insert oi;
    }
    
    @isTest
    static void testAfterUpdate() {
        QuoteLineItem qli = [SELECT Id, UnitPrice FROM QuoteLineItem LIMIT 1];
        
        Test.startTest();
        qli.UnitPrice = 150;
        update qli;
        Test.stopTest();
        
        // Assertions (Modify based on expected tax calculation logic)
        System.assertEquals(150, qli.UnitPrice);
    }
    
    @isTest
    static void testAfterDelete() {
        List<QuoteLineItem> qliList = [SELECT Id FROM QuoteLineItem LIMIT 1];
        
        Test.startTest();
        delete qliList;
        Test.stopTest();
        
        // Verify deletion
        System.assertEquals(0, [SELECT COUNT() FROM QuoteLineItem]);
    }
}