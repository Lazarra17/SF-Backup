/**
 * @description Controller class for VoucherTermsConditions vf component
 * @author JP Sulit (jp@bricoleurtech.com)
 * @date 09 Jul 2025
 */
public without sharing class VoucherTermsConditionsCtrl {
    
    public Id oppId { get; set; }

    public String getTermsConditions() {
        
        try {
            Opportunity opp = [SELECT Id, Voucher_bric__c FROM Opportunity WHERE Id =: oppId];
            Voucher__c voucher = [SELECT Id, Terms_Conditions__c FROM Voucher__c WHERE Id =: opp.Voucher_bric__c];
            
            if(voucher != null) {
                return voucher?.Terms_Conditions__c;
            } 
        }
        catch(Exception e) {
            return '';
        }
        return '';        
    }
}