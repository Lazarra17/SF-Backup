/**
 * @description Handler class for OppProductTrigger
 * @date Feb 12 2025
 * @author Bricoleur Technologies
 */
public without sharing class OppProductTriggerHandler extends TriggerHandlerNAO {

    private Map<Id, OpportunityLineItem> oliNewMap;
    private Map<Id, OpportunityLineItem> oliOldMap;

    public OppProductTriggerHandler() {
        this.oliNewMap = (Map<Id, OpportunityLineItem>) Trigger.newMap;
        this.oliOldMap = (Map<Id, OpportunityLineItem>) Trigger.oldMap;
    }

    public override void afterInsert() {
        CalculateTaxPerLineHelper.calcOppTotalTax(oliNewMap, oliOldMap, false);
    }

    public override void afterUpdate() {
        CalculateTaxPerLineHelper.calcOppTotalTax(oliNewMap, oliOldMap, false);
    }

    public override void afterDelete() {
        CalculateTaxPerLineHelper.calcOppTotalTax(null, oliOldMap, true);
    }
}