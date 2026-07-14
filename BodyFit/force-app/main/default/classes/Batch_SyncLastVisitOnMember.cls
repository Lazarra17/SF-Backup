public class Batch_SyncLastVisitOnMember implements Database.Batchable<sObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime lastOneHour = System.now().addHours(-1);
        return Database.getQueryLocator([SELECT Member__c, Date_Time__c FROM Visitation__c WHERE CreatedDate >= :lastOneHour]);
    }

    public void execute(Database.BatchableContext bc, List<Visitation__c> scope) {
        Map<Id, DateTime> memberLatestVisitMap = new Map<Id, DateTime>();

        for (Visitation__c visitation : scope) {
            if (!memberLatestVisitMap.containsKey(visitation.Member__c) || memberLatestVisitMap.get(visitation.Member__c) < visitation.Date_Time__c) {
                memberLatestVisitMap.put(visitation.Member__c, visitation.Date_Time__c);
            }
        }

        List<Account> accountsToUpdate = new List<Account>();
        List<Account> accountList = [SELECT Id, Last_Visit__pc, IsPersonAccount, RecordType.DeveloperName FROM Account WHERE Id IN :memberLatestVisitMap.keySet()];

        for (Account account : accountList) {
            Date latestVisit = memberLatestVisitMap.get(account.Id).date();

            System.debug('Processing Account: ' + account.Id + ' IsPersonAccount: ' + account.IsPersonAccount);

            if (account.IsPersonAccount) {
                if (account.Last_Visit__pc == null || account.Last_Visit__pc < latestVisit) {
                    account.Last_Visit__pc = latestVisit;
                    accountsToUpdate.add(account);
                }
            } 
        }

        if (!accountsToUpdate.isEmpty()) {
            try {
                update accountsToUpdate;
            } catch (DmlException e) {
                System.debug('Error updating accounts: ' + e.getMessage());
                for (Account acc : accountsToUpdate) {
                    System.debug('Failed Account Id: ' + acc.Id);
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {}
}