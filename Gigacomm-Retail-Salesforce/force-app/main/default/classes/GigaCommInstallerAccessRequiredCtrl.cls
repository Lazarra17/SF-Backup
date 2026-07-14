/**
 * @description Controller class for GigaCommInstallerAccessRequired vf component
 * @author JP Sulit (jp@bricoleurtech.com)
 * @date 17 May 2025
 */
public with sharing class GigaCommInstallerAccessRequiredCtrl {
    
    public String oppId {get; set;}

    public Boolean getHasInstallerAccess() {
        
        try {
            OpportunityLineItem oli = [SELECT Id, PriceBookEntry.Product2.Installer_Access_Required_Bric__c FROM OpportunityLineItem WHERE OpportunityId =: oppId AND PriceBookEntry.Product2.Installer_Access_Required_Bric__c = true LIMIT 1];

            if(oli != null) {
                return true;
            }
        }
        catch(Exception e) {
            System.debug('Exception : '+e);
            return false;
        }
        return false;
    }
}