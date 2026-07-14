/**
 * @description Controller class for GigaCommOppProductGrouping vf component
 * @author JP Sulit (jp@bricoleurtech.com)
 * @date 17 May 2025
 * [1] JPS 20 May 2025 - Add without sharing keyword
 * [2] JPS 09 Jul 2025 - Add Voucher_Term_bric__c in Opp Line Query
 * [3] JPS 09 Jul 2025 - Add logic to retrieve total of monthly fees where the amount > 0
 * [4] JPS 11 Jul 2025 - Add wrapper class to retrieve opp products and voucher terms from offers
 * [5] JPS 11 Jul 2025 - for the normal product, the text below the display name should be the contract length e.g. “1 month contract, 12 month contract, 24 month contract).
 * [6] JPS 09 Dec 2025 - Fix The value 'null' is not valid for operator '>'. flow error
 */
public without sharing class GigaCommOppProductGroupingCtrl {
    
    public Id oppId { get; set; }
    public String frequency { get; set; }

    public List<OpportunityLineItem> getProductsByFrequency() {
        return [
            SELECT Id, UnitPrice, Opportunity.Term_bric__c, Opportunity.Voucher_bric__c, Voucher_bric__c, PriceBookEntry.Product2Id,  PriceBookEntry.Product2.Name, TotalPrice, PriceBookEntry.Product2.Order_Confirmation_Line_Description_Bric__c,
            Voucher_Term_bric__c //[2] JPS 09 Jul 2025 - Add Voucher_Term_bric__c in Opp Line Query
            FROM OpportunityLineItem WHERE OpportunityId =: oppId AND Frequency_Bric__c != null AND Frequency_Bric__c =: frequency ORDER BY UnitPrice ASC
        ];
    }

    public Decimal getProductTotals() {
        
         AggregateResult ar;
        
        try {
            ar = [SELECT OpportunityId, SUM(TotalPrice) total FROM OpportunityLineItem WHERE OpportunityId =: oppId AND Frequency_Bric__c =: frequency GROUP BY OpportunityId];
            return (Decimal) ar.get('total');
        }
        catch(Exception e) {
            System.debug('Exception: '+e);
        }
        return 0;
    }

    //[3] JPS 09 Jul 2025 - Add logic to retrieve total of monthly fees where the amount > 0
    public Decimal getProductTotalsNotZero() {
        
         AggregateResult ar;
        
        try {
            ar = [SELECT OpportunityId, SUM(TotalPrice) total FROM OpportunityLineItem WHERE OpportunityId =: oppId AND Frequency_Bric__c =: frequency AND TotalPrice > 0 GROUP BY OpportunityId];
            return (Decimal) ar.get('total');
        }
        catch(Exception e) {
            System.debug('Exception: '+e);
        }
        return 0;
    }
	
    //[1] JPS 11 Jul 2025 - Add wrapper class to retrieve opp products and voucher terms from offers
    public List<PlansWrapper> getPlans() {

        Set<Id> offerIdSet = new Set<Id>();
        Set<Id> productIdSet = new Set<Id>();
        Set<Id> voucherIdSet = new Set<Id>();

        List<PlansWrapper> plansList = new List<PlansWrapper>();
        Map<String, Integer> voucherTermMap = new Map<String, Integer>();

        if(frequency == 'Monthly') {

            for(OpportunityLineItem oli : getProductsByFrequency()) {

                if(oli.Voucher_bric__c != null) {
                    voucherIdSet.add(oli.Voucher_bric__c);
                    offerIdSet.add(oli.PriceBookEntry.Product2Id); 
                }
            }
            
            for(Voucher_Product__c vp : [SELECT Id, Voucher_bric__c, Duration_months_bric__c, Apply_if_Product_Present_bric__c, Product_to_Apply_bric__c FROM Voucher_Product__c WHERE Voucher_bric__c IN : voucherIdSet AND Product_to_Apply_bric__c IN : offerIdSet]) {
                
                String key = vp.Voucher_bric__c + ';' + vp.Apply_if_Product_Present_bric__c;
                voucherTermMap.put(key, Integer.valueOf(vp.Duration_months_bric__c));
            }
           
            for(OpportunityLineItem oli : getProductsByFrequency()) {

                PlansWrapper plan = new PlansWrapper();
                String key = oli.Opportunity.Voucher_bric__c + ';' + oli.PriceBookEntry.Product2Id;
                plan.voucherTerm = voucherTermMap.containsKey(key) ? voucherTermMap.get(key) : Integer.valueOf(oli.Voucher_Term_bric__c);
                //[6]
                plan.voucherTerm = plan.voucherTerm != null ? plan.voucherTerm : 0;
                //[6]
                if(plan.oppProduct == null) {
                    plan.oppProduct = new OpportunityLineItem();
                } 
                plan.oppProduct = oli;
                plan.monthContract = getPlanTerm(oli.Opportunity.Term_bric__c);

                plansList.add(plan);
            }

            return plansList;
        }
        else {

            for(OpportunityLineItem oli : getProductsByFrequency()) {
                PlansWrapper plan = new PlansWrapper();
                
                if(plan.oppProduct == null) {
                    plan.oppProduct = new OpportunityLineItem();
                } 
                plan.oppProduct = oli;
                plan.monthContract = getPlanTerm(oli.Opportunity.Term_bric__c);

                plansList.add(plan);
            }

            return plansList;
        }
    }

    //[5] JPS 11 Jul 2025 - for the normal product, the text below the display name should be the contract length e.g. “1 month contract, 12 month contract, 24 month contract).
    public String getPlanTerm(String month) {
        
        if(month == '12 Months') {
            return '12 month contract';
        }
        else if(month == '24 Months') {
            return '24 month contract';
        }
        return '1 month contract';
    }
	
    //[4] JPS 11 Jul 2025 - Add wrapper class to retrieve opp products and voucher terms from offers
    public class PlansWrapper {
        public Integer voucherTerm {get; set;}
        public OpportunityLineItem oppProduct {get; set;}
        public String monthContract {get; set;} //[5] JPS 11 Jul 2025 - for the normal product, the text below the display name should be the contract length e.g. “1 month contract, 12 month contract, 24 month contract).
    }

}