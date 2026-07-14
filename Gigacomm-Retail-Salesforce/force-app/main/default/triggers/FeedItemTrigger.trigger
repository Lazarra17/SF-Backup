trigger FeedItemTrigger on FeedItem (before insert,before update, after insert,after update) {
    
 if(trigger.isinsert && trigger.isafter){
        SNIntegrationService.createCommentInServiceNow(trigger.new);
    }
    if(trigger.isupdate && trigger.isafter){
        SNIntegrationService.updateCommentInServiceNow(trigger.new,trigger.OldMap);
    }
}