/*
 * Author: 			Alfonso Maquilan
 * Created Date: 	May 20, 2021
 * Description: 	Apex Trigger for XeroWebhookStorage__c object
 * Test Class: 		N/A
 * History: 		May  20, 2021 - Creation
 */
trigger XeroWebhookStorageTrigger on XeroWebhookStorage__c (before insert , before update , before delete , after insert , after update , after delete) 
{
	TriggerRunner.RunTriggerHandler(CONSTANTS_Bric.SOBJECT_XERO_WEBHOOK_STORAGE);
}