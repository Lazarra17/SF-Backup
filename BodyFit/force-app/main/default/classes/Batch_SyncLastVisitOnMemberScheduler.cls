public class Batch_SyncLastVisitOnMemberScheduler implements Schedulable {

    public void execute(SchedulableContext context) {
        
        Batch_SyncLastVisitOnMember batch = new Batch_SyncLastVisitOnMember();
        Database.executeBatch(batch, 2000);
    }
}