public class Batch_UpdateLastVisitOnAccount implements Database.Batchable<sObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Last_Visit__pc FROM Account';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Account> scope){
        Set<Id> accountIds = new Set<Id>();
        
        for(Account objAccount : scope){
            accountIds.add(objAccount.Id);
        }
        
        List<AggregateResult> visitations = [SELECT Member__c, MAX(Date_Time__c) latestDate
                                             FROM Visitation__c
                                             WHERE Member__c IN :accountIds
                                             GROUP BY Member__c LIMIT 49999
                                            ];
        
        Map<Id, Date> latestVisitDateMap = new Map<Id, Date>();
        for (AggregateResult ar : visitations) {
            Id memberId = (Id) ar.get('Member__c');
            DateTime latestDateTime = (DateTime) ar.get('latestDate');
            latestVisitDateMap.put(memberId, latestDateTime.date());
        }
        
        for (Account acc : scope) {
            if (latestVisitDateMap.containsKey(acc.Id)) {
                acc.Last_Visit__pc = latestVisitDateMap.get(acc.Id);
            }
        }
        
        if (!scope.isEmpty()) {
            update scope;
        }
    }
    
    public void finish(Database.BatchableContext bc){}
}