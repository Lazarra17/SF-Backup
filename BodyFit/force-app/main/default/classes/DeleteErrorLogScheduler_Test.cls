@isTest
public class DeleteErrorLogScheduler_Test {

    @isTest
    public static void scheduleJob() {
        String cronExp = '0 0 0 1 * ?';
        System.schedule('Monthly Delete Error Log Job', cronExp, new DeleteErrorLogScheduler());
    }
}