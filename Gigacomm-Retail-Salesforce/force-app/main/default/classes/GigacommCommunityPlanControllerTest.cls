@IsTest
public class GigacommCommunityPlanControllerTest {
    
    public static testMethod void testCreateLead(){
        
        lead l = new Lead();
        l.LastName = 'Test';
        l.Company = 'Company';       
        
        Test.StartTest();
        Lead createdLead = GigacommCommunityPlanController.createLead(JSON.serialize(l));
        GigacommCommunityPlanController.getPicklistValues('Lead', 'StateCode', '');
        Test.StopTest();
         
        system.assert(createdLead != null, 'New Lead Created');
        
    }
    
}