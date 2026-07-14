@isTest
public class UtilitiesTest {
    
    @isTest
    static void testCreateExceptionLogWithCustomString() {
        try {
            Integer result = 1 / 0; 
            
        } catch(Exception e) {
            String customString = 'Custom String';
            
            Test.startTest();
            Utilities.CreateExceptionLog(e, customString);
            Test.stopTest();
            
            Integer exceptionCount = [SELECT COUNT() FROM Exception_Log__c];
            System.assertEquals(1, exceptionCount, 'Exception_Log__c record should be inserted');
        }
    }
    
    @isTest
    static void testCreateExceptionLog() {
        try {
            Integer result = 1 / 0; 
            
        } catch(Exception e) {
            Test.startTest();
            Utilities.CreateExceptionLog(e);
            Utilities.CreateRequestResponseLog('DELETE','test','test',200,'test');
            Utilities.GenerateRestResponse(200,'Test');
            Utilities.CheckStringIfNullOrBlank('Test');
                Utilities.CheckIfPersonAccountEnabled();
            Test.stopTest();
            
            Integer exceptionCount = [SELECT COUNT() FROM Exception_Log__c];
            System.assertEquals(1, exceptionCount, 'Exception_Log__c record should be inserted');
        }
    }
    
    
}