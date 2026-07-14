@isTest
 public class MetaPostConversionLeadsTest {
     
     @testSetup
     public static void setupData(){
         Lead l = TestDataFactory.createLead(false);
         Club__c club =  TestDataFactory.createClub(true);
         l.Club__c = club.Id;
         insert l;
         
           
        Meta_API_Settings__c metaApi = new Meta_API_Settings__c();
        metaApi.Active__c = true;
        metaApi.Endpoint__c = 'callOut:';
        insert metaApi;
         
         
     }
     
     
     public static testMethod void testConversionsAPIPost(){
         Test.setMock(HttpCalloutMock.class, new MetaMockHttpResponseGenerator());
         Lead l = [SELECT Id, FirstName, LastNAme, Email, MobilePhone, Postcode__c, sfleadcaphfprod__External_Lead_ID__c, TECH_Date_of_Birth_bric__c, 
                   City, State, PostalCode, Country, ConvertedOpportunityId FROM Lead LIMIT 1];
         test.startTest();
         MetaPostConversionLeads.PostConversionLead(l);
         
         
         test.stopTest();
         
     }
     
     public static testMethod void testConversionsAPIPostFail(){
         Test.setMock(HttpCalloutMock.class, new MetaMockHttpResponseGeneratorFail());
         Lead l = [SELECT Id, FirstName, LastNAme, Email, MobilePhone, Postcode__c, sfleadcaphfprod__External_Lead_ID__c, TECH_Date_of_Birth_bric__c, 
                   City, State, PostalCode, Country, ConvertedOpportunityId FROM Lead LIMIT 1];
         test.startTest();
         MetaPostConversionLeads.PostConversionLead(l);
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
     
 }