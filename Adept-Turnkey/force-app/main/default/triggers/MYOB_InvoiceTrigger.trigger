/*
* Author: Bricoleur Technologies 
* Created Date: June 26, 2025
* Description: 
*/

trigger MYOB_InvoiceTrigger on MYOB_Invoice__c (before insert, before update, after insert, after update) {
    
    new MYOB_InvoiceTriggerHandler().run();

}