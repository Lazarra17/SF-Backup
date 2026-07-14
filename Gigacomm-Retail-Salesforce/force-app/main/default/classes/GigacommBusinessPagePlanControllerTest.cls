@isTest
public class GigacommBusinessPagePlanControllerTest {
    
      public static testMethod void testCreateLead(){
        
        lead l = new Lead();
        l.LastName = 'Test';
        l.Company = 'Company';       
        
        Test.StartTest();
        GigacommBusinessPagePlanController.getPicklistValues('Lead', 'StateCode', '');
        Test.StopTest();
         
      
        
    }

}