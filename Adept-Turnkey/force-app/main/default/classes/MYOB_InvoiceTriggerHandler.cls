/*
* Author: Bricoleur Technologies 
* Created Date: Feb 26, 2025
* Description: 
*/

public class MYOB_InvoiceTriggerHandler extends MYOB_TriggerHandler{
    
    private Map<Id, MYOB_Invoice__c> newInvoiceMap;
    private Map<Id, MYOB_Invoice__c> oldInvoiceMap;
    private List<MYOB_Invoice__c> newInvoices;
    private List<MYOB_Invoice__c> oldInvoices;
    
    public MYOB_InvoiceTriggerHandler() {
        this.newInvoiceMap = (Map<Id, MYOB_Invoice__c>) Trigger.newMap;
        this.oldInvoiceMap = (Map<Id, MYOB_Invoice__c>) Trigger.oldMap;
        this.newInvoices = (List<MYOB_Invoice__c>) Trigger.new;
        this.oldInvoices = (List<MYOB_Invoice__c>) Trigger.old;
    }
    
    public override void afterInsert() {
        
        Set<String> myobInvoiceIdsSet = new Set<String>();
        for(MYOB_Invoice__c myobInvoice : newInvoices){
            myobInvoiceIdsSet.add(myobInvoice.MYOB_UID_bric__c);
        }
        
        system.debug('InvoiceId: ' + myobInvoiceIdsSet);
        MYOB_InvoiceTriggerHandlerHelper.upsertNaoInvoices(newInvoices, myobInvoiceIdsSet);
        
        
    }
    
    public override void afterUpdate() {
        
        Set<String> myobInvoiceIdsSet = new Set<String>();
        for(MYOB_Invoice__c myobInvoice : newInvoices){
            myobInvoiceIdsSet.add(myobInvoice.MYOB_UID_bric__c);
        }
        
        system.debug('InvoiceId: ' + myobInvoiceIdsSet);
        MYOB_InvoiceTriggerHandlerHelper.upsertNaoInvoices(newInvoices, myobInvoiceIdsSet);
        
        
    }
    
    
    
    
    
}