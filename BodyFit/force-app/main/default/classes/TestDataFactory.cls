/*
@Author: Chad Lazarra (Bricoleur Technology)
@Date: 13-Sept-25
@History: 
[1] CLAZARRA - 13-Sept-25 - Created
*/
public class TestDataFactory {
	
    public static Lead createLead(Boolean isInsert){
        
        Lead l = new Lead();
        l.FirstName = 'First';
        l.LastName = 'Last';
        l.Email = 'email@gmail.com';
        l.MobilePhone = '044232134';
        l.Postcode__c = '6817';
        l.sfleadcaphfprod__External_Lead_ID__c = '2121212121';
        
        if(isInsert){
            insert l;
        }
        
        return l;
        
        
    }
    
    public static Club__c createClub(Boolean isInsert){
        
        Club__c club = new Club__c();
       	club.Name = 'club';
        club.Default_Lead_Owner__c = UserInfo.getUserId();
        
        if(isInsert){
            insert club;
        }
        
        return club;
        
        
    }
}