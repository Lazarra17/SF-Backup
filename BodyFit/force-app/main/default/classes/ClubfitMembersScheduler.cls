/*
@Author: Chad Lazarra (Bricoleur Technology)
@Date: 
@Desc: !IMPORTANT NOTE
	   To Stop the JOB.   Go to Clubfit Custom Settings and Tick the Active checkbox.
@History:
[1] CLAZARRA 11-Feb-26 : Created
*/
public class ClubfitMembersScheduler implements Schedulable {
    
     public void execute(SchedulableContext sc) {
        // Run the batch job
         
         Map<String, String> clubMap = Utilities.getClubMap();
         Map<String, String> apiKeyMap = Utilities.getApiKeyMap();
         Map<String, String> paramMap = new Map<String, String>();
         
         //create a map for Club Id and API Key.   Club OBject and API Key Custom Setting
         for(String club : clubMap.keySet()){
             if(apiKeyMap.containsKey(club)){
                 //Id of Club and API Key
                 paramMap.put(clubMap.get(club), apiKeyMap.get(club));
             }
         } 
         
         system.debug('#paramMap: ' + paramMap.size()); 
   
         Database.executeBatch(new ClubfitGetMembersBatch(paramMap, system.now(), null));

       
        scheduleNextRun();
    }

    public void scheduleNextRun() {
        String jobName = Constants.CLUBFIT_ALL_CLUBS_MEMBERS_SCHEDULER;
        
        // 1. Abort existing jobs to avoid "Job already scheduled" errors
        for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :jobName]) {
            System.abortJob(ct.Id);
        }
        
        // 2. Determine if the next run should be Noon today or Midnight tomorrow
        Datetime now = Datetime.now();
        Datetime nextRun;
        
        // If it's currently before 12:00 PM, set next run to 12:00 PM Today
        if (now.hour() < 12) {
            nextRun = Datetime.newInstance(now.year(), now.month(), now.day(), 12, 0, 0);
        } 
        // If it's already past 12:00 PM, set next run to 12:00 AM Tomorrow
        else {
            Datetime tomorrow = now.addDays(1);
            nextRun = Datetime.newInstance(tomorrow.year(), tomorrow.month(), tomorrow.day(), 0, 0, 0);
        }
        
        // 3. Build CRON and Schedule
        String cron = getCronExpression(nextRun);
        System.schedule(jobName, cron, new ClubfitMembersScheduler());
        
        System.debug('Next run snapped to: ' + nextRun);
    } 

    public static String getCronExpression(Datetime dt) {
        // Seconds Minutes Hours Day Month ? Year
      
        return String.format('{0} {1} {2} {3} {4} ? {5}', new List<String>{
            String.valueOf(dt.second()),
            String.valueOf(dt.minute()),
            String.valueOf(dt.hour()),
            String.valueOf(dt.day()),
            String.valueOf(dt.month()),
            String.valueOf(dt.year())
        });
    
     
     
    }
    
}