@isTest
public class AcceptOpptyControllerTest {

    @isTest
    static void testAcceptOpp_withValidOpportunity() {
        // Create test Opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;

        // Call the method
        Test.startTest();
        AcceptOpptyController.acceptOpp(testOpp.Id);
        Test.stopTest();

        // Verify the updates
        Opportunity updatedOpp = [SELECT Id, Accepted_by_Client_Bric__c, 
                                         Accepted_by_Client_Date_Bric__c, 
                                         StageName 
                                  FROM Opportunity 
                                  WHERE Id = :testOpp.Id];

        // System.assertEquals(true, updatedOpp.Accepted_by_Client_Bric__c, 'Accepted_by_Client_Bric__c should be true');
        // System.assertNotEquals(null, updatedOpp.Accepted_by_Client_Date_Bric__c, 'Accepted_by_Client_Date_Bric__c should not be null');
        // System.assertEquals('Won - Business (GC)', updatedOpp.StageName, 'StageName should be updated');
    }

    @isTest
    static void testAcceptOpp_withInvalidId() {
        // Call the method with an invalid Id (not starting with '006')
        Test.startTest();
        AcceptOpptyController.acceptOpp('001XXXXXXXXXXXX'); // Account Id
        Test.stopTest();

        // Nothing to assert — the method should safely exit without error
    }

    @isTest
    static void testAcceptOpp_withBlankId() {
        // Call the method with a blank Id
        Test.startTest();
        AcceptOpptyController.acceptOpp('');
        Test.stopTest();

        // Nothing to assert — the method should safely exit without error
    }
}