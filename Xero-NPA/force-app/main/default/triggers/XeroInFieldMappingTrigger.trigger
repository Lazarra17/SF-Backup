trigger XeroInFieldMappingTrigger on XeroInboundFieldMapping__c (before insert , before update , before delete , after insert , after update , after delete) 
{
	TriggerRunner.RunTriggerHandler(CONSTANTS_Bric.SOBJECT_XERO_INBOUND_FIELD_MAPPING);
}