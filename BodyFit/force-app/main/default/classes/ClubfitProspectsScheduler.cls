/*
@Author: Chad Lazarra (Bricoleur Technology)
@Date: 
@Desc: !IMPORTANT NOTE
	   To Stop the JOB.   Go to Clubfit Custom Settings and Tick the Active checkbox.
@History:
[1] CLAZARRA 12-Oct-25 : Created
[1] CLAZARRA 29-Jan-26 : run every 30 min of Job
*/
public class ClubfitProspectsScheduler implements Schedulable {
    
     public void execute(SchedulableContext sc) {
        // Run the batch job
         
         Map<String, String> clubMap = getClubMap();
         Map<String, String> apiKeyMap = getApiKeyMap();
         Map<String, String> paramMap = new Map<String, String>();
         
         //create a map for Club Id and API Key.   Club OBject and API Key Custom Setting
         for(String club : clubMap.keySet()){
             if(apiKeyMap.containsKey(club)){
                 //Id of Club and API Key
                 paramMap.put(clubMap.get(club), apiKeyMap.get(club));
             }
         } 
         
         system.debug('#paramMap: ' + paramMap.size());

		 //Minus 35 minutes because of the delay needed for Online Incomplete Signup.  So that it can capture data starting 35 minute before the current time   
		 //There is 5minute allowance for Online Incomplete Signup to Sync       
         Database.executeBatch(new ClubfitGetProspectsBatch(paramMap, system.now().addMinutes(-35)));

        // Schedule next run after 30 minutes
        scheduleNextRun();
    }

    public void scheduleNextRun() {
        String jobName = Constants.CLUBFIT_ALL_CLUBS_PROSPECTS_SCHEDULER;

        // Abort any existing scheduled job with same name
        for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :jobName]) {
            System.abortJob(ct.Id);
        }

        // Compute next run time (30 minutes from now)
        Datetime nextRun = System.now().addMinutes(30);
       
        // Build CRON expression
        String cron = getCronExpression(nextRun);

        // Schedule job using same name
        System.schedule(jobName, cron, new ClubfitProspectsScheduler());
        System.debug('Next run scheduled at: ' + nextRun);
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
    
    
    public static Map<String, String> getApiKeyMap(){
        
        Map<String, String> apiKeyMap = new Map<String, String>();
        for(APIKeys__c key : [SELECT Id, Club__c, Key__c FROM APIKeys__c]){
            apiKeyMap.put(key.Club__c, key.Key__c);
        }
        
        return apiKeyMap;
        
    }  
    
    public static Map<String, String> getClubMap(){
        
        Map<String, String> clubMap = new Map<String, String>();
        for(Club__c club : [SELECT Id, Name FROM Club__c]){
            clubMap.put(club.Name, club.Id);
        }
        
        return clubMap;
        
    }  
    
}