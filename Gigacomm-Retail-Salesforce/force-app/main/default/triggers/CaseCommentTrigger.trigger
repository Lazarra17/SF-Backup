trigger CaseCommentTrigger on CaseComment (before insert,before update, after insert,after update) {
    if(trigger.isupdate && trigger.isafter){
        SNIntegrationService.updateCommentInServiceNow(trigger.new,trigger.OldMap);
    }
    if(trigger.isinsert && trigger.isafter){
        SNIntegrationService.createCommentInServiceNow(trigger.new);
     }
}