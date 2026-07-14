/**
 * @description Handler class for QuoteLineTrigger
 * @date Feb 12 2025
 * @author Bricoleur Technologies
 */
public without sharing class QuoteLineTriggerHandler extends TriggerHandlerNAO {

    private Map<Id, QuoteLineItem> qliNewMap;
    private Map<Id, QuoteLineItem> qliOldMap;

    public QuoteLineTriggerHandler() {
        this.qliNewMap = (Map<Id, QuoteLineItem>) Trigger.newMap;
        this.qliOldMap = (Map<Id, QuoteLineItem>) Trigger.oldMap;
    }

    public override void afterInsert() {
        CalculateTaxPerLineHelper.calcQuoteTotalTax(qliNewMap, qliOldMap, false);
    }

    public override void afterUpdate() {
        CalculateTaxPerLineHelper.calcQuoteTotalTax(qliNewMap, qliOldMap, false);
    }

    public override void afterDelete() {
        CalculateTaxPerLineHelper.calcQuoteTotalTax(null, qliOldMap, true);
    }
}