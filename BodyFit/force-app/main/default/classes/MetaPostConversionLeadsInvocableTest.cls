/*
@Author: Chad Lazarra (Bricoleur Technology)
@Date: 12-Sept-25
@Desc:
@History:
[1] CLAZARRA 12-Sept-25 : Created
*/
@isTest
public class MetaPostConversionLeadsInvocableTest {

    @testSetup
    public static void setupData(){
         Lead l = TestDataFactory.createLead(false);
         Club__c club =  TestDataFactory.createClub(true);
         l.Club__c = club.Id;
         insert l;
         
        
    }
    
    
    public static testMethod void testConversionLeadInvocable(){
        MetaPostConversionLeadsInvocable.Requests req = new MetaPostConversionLeadsInvocable.Requests();
        req.lead = [SELECT Id FROM Lead LIMIT 1];
        List<MetaPostConversionLeadsInvocable.Requests> reqs = new List<MetaPostConversionLeadsInvocable.Requests>();
        reqs.add(req);
        MetaPostConversionLeadsInvocable.processConversionLeads(reqs);
        
    }
}