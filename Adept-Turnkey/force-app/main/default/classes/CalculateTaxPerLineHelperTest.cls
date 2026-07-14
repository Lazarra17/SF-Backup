@isTest
public class CalculateTaxPerLineHelperTest {
    @testSetup
    static void setupTestData() {

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
    static void testCalcOppTotalTax() {
        OpportunityLineItem oli = [SELECT Id, OpportunityId, Tax__c FROM OpportunityLineItem LIMIT 1];
        
        Map<Id, OpportunityLineItem> newMap = new Map<Id, OpportunityLineItem>{ oli.Id => oli };
        Map<Id, OpportunityLineItem> oldMap = new Map<Id, OpportunityLineItem>();
        
        Test.startTest();
        CalculateTaxPerLineHelper.calcOppTotalTax(newMap, oldMap, false);
        Test.stopTest();
        
        Opportunity opp = [SELECT Id, Tax__c FROM Opportunity WHERE Id = :oli.OpportunityId];
        System.assertEquals(10, opp.Tax__c);
    }

    @isTest
    static void testCalcQuoteTotalTax() {
        QuoteLineItem qli = [SELECT Id, QuoteId, Tax__c FROM QuoteLineItem LIMIT 1];
        
        Map<Id, QuoteLineItem> newMap = new Map<Id, QuoteLineItem>{ qli.Id => qli };
        Map<Id, QuoteLineItem> oldMap = new Map<Id, QuoteLineItem>();
        
        Test.startTest();
        CalculateTaxPerLineHelper.calcQuoteTotalTax(newMap, oldMap, false);
        Test.stopTest();
        
        Quote quote = [SELECT Id, Tax FROM Quote WHERE Id = :qli.QuoteId];
        System.assertEquals(10, quote.Tax);
    }

    @isTest
    static void testCalcOrderTotalTax() {
        OrderItem oi = [SELECT Id, OrderId, Tax__c FROM OrderItem LIMIT 1];
        
        Map<Id, OrderItem> newMap = new Map<Id, OrderItem>{ oi.Id => oi };
        Map<Id, OrderItem> oldMap = new Map<Id, OrderItem>();
        
        Test.startTest();
        CalculateTaxPerLineHelper.calcOrderTotalTax(newMap, oldMap, false);
        Test.stopTest();
        
        Order order = [SELECT Id, Tax__c FROM Order WHERE Id = :oi.OrderId];
        System.assertEquals(10, order.Tax__c);
    }
}