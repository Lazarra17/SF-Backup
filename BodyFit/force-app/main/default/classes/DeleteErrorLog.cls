public class DeleteErrorLog implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
            [SELECT Id FROM Error_Log__c WHERE CreatedDate < :System.today().addDays(-30)]
        );
    }

    public void execute(Database.BatchableContext BC, List<Error_Log__c> scope) {
        
        if (!scope.isEmpty()) {
            delete scope;
        }
    }

    public void finish(Database.BatchableContext BC) {}
}