@isTest
public class GigaCommPaymentControllerTest {
    @testSetup
    public static void setupData(){
        // Prepare test data
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create a Contact for the Account
        Contact con = new Contact(FirstName = 'John', LastName = 'Doe', AccountId = acc.Id, Email = 'john.doe@test.com');
        insert con;
        
        // Insert a Product2 and PricebookEntry for OpportunityLineItem
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(Product2Id = prod.Id, Pricebook2Id = pricebookId, UnitPrice = 100, IsActive = true);
        insert pbe;
        
        // Create Opportunity
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', EziDebit_Reference_bric__c = 'cref', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = acc.Id);
        insert opp;
        
        
    }
    
    public static testmethod void getEziDebitTest(){
        Opportunity oppty = [SELECT Id FROM Opportunity LIMIT 1];
        
        GigaCommPaymentController.getEziDebit(oppty.Id);
    }

}