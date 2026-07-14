trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert) {
    
    if(trigger.isinsert && trigger.isafter){
        SNIntegrationService.uploadFile(trigger.new);
    }
}