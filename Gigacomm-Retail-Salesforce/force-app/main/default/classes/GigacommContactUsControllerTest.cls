@IsTest
public class GigacommContactUsControllerTest {
    
    public static testMethod void testCreateLead(){
        
        lead l = new Lead();
        l.LastName = 'Test';
        l.Company = 'Company';       
        
        Test.StartTest();
        Lead createdLead = GigacommContactUsController.createLead(JSON.serialize(l));
        Test.StopTest();
        
        system.assert(createdLead != null, 'New Lead Created');
        
    }
    
    
    
}