/*
 * Author: 			Bricoleur Technologies
 * Created Date: 	September 28, 2021
 * Description: 	Runs XeroGetQuoteBatch
 * Test Class: 		XeroGetQuoteBatchTest
 * History: 		September 28, 2021 - Creation
 */
public class RunXeroGetQuoteBatchCtrl {
    
    @AuraEnabled
     public static void runXeroGetQuoteBatch()
    {
        Database.executeBatch(new XeroGetQuoteBatch());
    }

}