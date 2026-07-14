public class SimplifyLeadStatus {
    public static List<Schema.PicklistEntry> getLeadClosedReasons(){
       Schema.DescribeFieldResult fieldResult = Lead.Lead_Closed_Reason__c.getDescribe(); 
       List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
       return ple;
    }
    
    public static void getClosedLeads(){
        list<Lead> allLeads = [SELECT Id, Lead_Closed_Reason__c FROM Lead];
        for(Lead l : allLeads) {
            String[] reason = new List<String>();
            if(l.Lead_Closed_Reason__c !=null){ 
                reason = l.Lead_Closed_Reason__c.split(';');
                if(reason.size()>1){
                    System.debug(l.Lead_Closed_Reason__c);
                }
            }
            
        }
        
    }
    public static Integer leadReasonCount(Lead theLead){
        String[] reason = new List<String>();
        Integer ret;
        if(theLead.Lead_Closed_Reason__c !=null){
            reason = theLead.Lead_Closed_Reason__c.split(';');
            return reason.size();
        }
        else
            return 0;
    }
    
    //This appears trivial, but is made a method to allow a more sophisticated 
    //implementation if required.
    public static String getPrimaryReason(String LCR) {
        return LCR.split(';')[0];
    }
    
    public static void updateReasons(){
        list<Lead> allLeads = [SELECT Id, Lead_Closed_Reason__c, AT_ReasonCount__c, AT_Primary_Reason__c FROM Lead WHERE Lead_Closed_Reason__c != null ];
        for(Lead l : allLeads) {
            Integer reasons= 0;
            if(l.Lead_Closed_Reason__c !=null){ 
                reasons = leadReasonCount(l);
                l.AT_Primary_Reason__c = getPrimaryReason(l.Lead_Closed_Reason__c);
                
            }
            l.AT_ReasonCount__c = reasons;
                
        }
        Update allLeads;
 
    }
        

}