/*
@Author: Chad Lazarra 
@Date: 3-Nov-2026
@Desc: A Reusable Test method
@History: [1] Created - 4-Nov-2026
*/
public class TestDataFactory {
    
    
    public static List<Account> createAccount(Integer count, Boolean isCreate){
        List<Account> accList = new List<Account>();
        for(Integer c = 1; c <= count; c++){
            Account acc = new Account();
            acc.Name = 'AccTest' + c;
            acc.UPRN__c = '101';
            acc.Client_Journey__c = 101;
            acc.Ready_For_Sale__c = true;
            acc.Available_For_Pre_Order__c = true;
            accList.add(acc);
        }
        
        if(isCreate){
            insert accList;
        }
        
        return accList;
        
        
    }
    
    public static User createStandardUser(Boolean isCreate) {
        
        Profile standardProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Standard User'
            LIMIT 1
        ];
        
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            Username = 'testuser' + Datetime.now().getTime() + '@example.com',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'Australia/Sydney',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        
        if(isCreate){
            insert testUser;
        }
        
        
        return testUser;
    }

}