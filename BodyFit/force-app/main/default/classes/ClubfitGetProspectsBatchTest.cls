@isTest
public class ClubfitGetProspectsBatchTest {
    
    @testSetup
    public static void setupData(){
        Lead l = TestDataFactory.createLead(false);
        Club__c club =  TestDataFactory.createClub(true);
        l.Club__c = club.Id;
        insert l;
        
        
        Clubfit_API_Settings__c metaApi = new Clubfit_API_Settings__c();
        metaApi.Active__c = true;
        metaApi.Endpoint__c = 'callout:Clubfit_App';
        metaApi.Last_Sync_DateTime__c = system.now();
        insert metaApi;
        
        // Create a test API Key record associated with the club name
        APIKeys__c testKey = new APIKeys__c(
            Name = 'API Key',
            Club__c = club.Name, // Match the Name field for the map lookup
            Key__c = 'TEST_API_KEY_123'
        );
        
        insert testKey;
        
    }
    
    
    public static testMethod void testGetProspectsAPI(){
        Test.setMock(HttpCalloutMock.class, new ClubfitTokenMockResponseGenerator());
        
        
        Map<String, String> clubMap = ClubfitProspectsScheduler.getClubMap();
        Map<String, String> apiKeyMap = ClubfitProspectsScheduler.getApiKeyMap();
        Map<String, String> paramMap = new Map<String, String>();
        
        //create a map for Club Id and API Key.   Club OBject and API Key Custom Setting
        for(String club : clubMap.keySet()){
            if(apiKeyMap.containsKey(club)){
                //Id of Club and API Key
                paramMap.put(clubMap.get(club), apiKeyMap.get(club));
            }
        } 
        
        system.debug('#paramMap: ' + paramMap.size());
        
        
        test.startTest();
        Database.executeBatch(new ClubfitGetProspectsBatch(paramMap, system.now()));
        
        test.stopTest();
        
    }
    
    public static testMethod void testGetProspectsAPIFail(){
        Test.setMock(HttpCalloutMock.class, new ClubfitTokenFailMockResponseGenerator());
        
        
        Map<String, String> clubMap = ClubfitProspectsScheduler.getClubMap();
        Map<String, String> apiKeyMap = ClubfitProspectsScheduler.getApiKeyMap();
        Map<String, String> paramMap = new Map<String, String>();
        
        //create a map for Club Id and API Key.   Club OBject and API Key Custom Setting
        for(String club : clubMap.keySet()){
            if(apiKeyMap.containsKey(club)){
                //Id of Club and API Key
                paramMap.put(clubMap.get(club), apiKeyMap.get(club));
            }
        } 
        
        system.debug('#paramMap: ' + paramMap.size());
        
        
        test.startTest();
        Database.executeBatch(new ClubfitGetProspectsBatch(paramMap, system.now()));
        
        test.stopTest();
        
    }
    
    public static testMethod void testUtilities(){
        
        test.startTest();
        try{
            Lead lisd = [SELECT ID FROM Lead WHERE Id='00QMo00000RlXtpMAF'];
        }
        catch(Exception e){
            Utilities.CreateExceptionLog(e, 'test');   
            Utilities.CreateException(e, 'test');  
            Utilities.CreateExceptionLog(e);  
        }
        
        
        test.stopTest();
    }
    
    
    /*
    public static testMethod void testConversionsAPIPostFail(){
        Test.setMock(HttpCalloutMock.class, new MetaMockHttpResponseGeneratorFail());
        Lead l = [SELECT Id, FirstName, LastNAme, Email, MobilePhone, Postcode__c, sfleadcaphfprod__External_Lead_ID__c, TECH_Date_of_Birth_bric__c, 
                  City, State, PostalCode, Country, ConvertedOpportunityId FROM Lead LIMIT 1];
        test.startTest();
        MetaPostConversionLeads.PostConversionLead(l);
        test.stopTest();
    }
    */

}