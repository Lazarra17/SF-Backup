@isTest
public class GigaCommAddressInterestControllerTest {
    
    private static testMethod void createLeadTest() {
        
        
        GigaCommAddressInterestController.SiteLead siteLead = new GigaCommAddressInterestController.SiteLead();
        siteLead.FirstName ='test';
        siteLead.LastName ='test';
        siteLead.Email ='test';
        Test.startTest();
        GigaCommAddressInterestController.createLead(JSON.serialize(siteLead));
        Test.stopTest();
        
    }
    
}