trigger CaseTrigger on Case(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    
    if(trigger.isupdate && trigger.isbefore){
        SNIntegrationService.updateIncident(trigger.new,trigger.OldMap);
    }
  
}