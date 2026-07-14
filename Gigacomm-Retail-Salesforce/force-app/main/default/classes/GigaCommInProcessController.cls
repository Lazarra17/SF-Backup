/*
@Author: Chad Lazarra
@Date: 
@History: [1]CL 10-Oct-25 : GR-265 Update Ezidebit on Account Level
*/
public without sharing class GigaCommInProcessController {
    
    public class SiteLead{
        @AuraEnabled
        public Opportunity Oppty;
        @AuraEnabled
        public Boolean hardwareInclude;
    }
    
    @AuraEnabled
    public static GigaCommInProcessController.SiteLead updateLead(String uref, String cref){
        system.debug('uref: ' + uref);
        system.debug('cref: ' + cref);
        GigaCommInProcessController.SiteLead sl = new GigaCommInProcessController.SiteLead();
        sl.hardwareInclude = false;
        Opportunity oppty = new Opportunity();
        if(uref != ''){
             
          	oppty = [SELECT Id, AccountId, EziDebit_Reference_bric__c, Lead_bric__c, EziDebit_Customer_Id_bric__c, EziDebit_Submitted_Date_Time_bric__c, Account.BillingStateCode, Account.BillingPostalCode, ContactId,
                     Plan_bric__c, Term_bric__c, Plan_bric__r.Download_Upload_Limit_bric__c, Plan_bric__r.ProductCode
                     FROM Opportunity WHERE EziDebit_Reference_bric__c =: uref];
            
            List<OpportunityLineItem> hardWares = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId =: oppty.Id AND ProductCode =: Constants.GIGACOMM_ROUTER_SKU];
            
            oppty.EziDebit_Customer_Id_bric__c = cref;
            oppty.EziDebit_Submitted_Date_Time_bric__c = System.Now();
            update oppty;
            
            
            //[1]CL 10-Oct-25 : GR-265 Update Ezidebit on Account Level
            Account acc = new Account();
            acc.Id = oppty.AccountId;
            acc.Ezidebit_Reference__c = 'confirmed:' + oppty.EziDebit_Reference_bric__c;
            update acc;
            
            //Construct SiteLead Response
            sl.Oppty = oppty;
            if(hardWares.size() > 0){
                sl.hardwareInclude = true;
            }
        }
        
        return sl;
        
        
    }
    
    
    /*
    public static void copyLeadProductsToOpportunity(Id leadId, Id opportunityId) {

        // Fetch Lead Products
        List<Lead_Product_Item__c> leadProducts = [
            SELECT Product_bric__c, Quantity_bric__c, Unit_Price_bric__c, TECH_PriceBookEntryId_bric__c
            FROM Lead_Product_Item__c
            WHERE Lead_bric__c = :leadId
        ];
        
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        
        for (Lead_Product_Item__c lp : leadProducts) {
            system.debug('pb: ' + lp.TECH_PriceBookEntryId_bric__c);
            OpportunityLineItem oli = new OpportunityLineItem(
                OpportunityId = opportunityId,
                PricebookEntryId = lp.TECH_PriceBookEntryId_bric__c,
                Quantity = lp.Quantity_bric__c,
                UnitPrice = lp.Unit_Price_bric__c
            );
            oppLineItems.add(oli);
        }
        
        insert oppLineItems;
        
        
        //Update Opportunity to Close Won
         Opportunity opp = [
            SELECT Id, StageName FROM Opportunity WHERE Id = :opportunityId LIMIT 1
        ];
        opp.StageName = 'Closed Won';
        update opp;
        
    } */
    
}