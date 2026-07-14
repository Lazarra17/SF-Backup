public class LeadSummary {
    public static void summarizeLeads(){
        List<AggregateResult> leadList = [SELECT LeadSource, 
                                          ConvertedOpportunity.StageName ConvertStage, 
                                          count(ID) leadCount
                                  from lead group by LeadSource, convertedopportunity.stageName order 
                                  by LeadSource];
        
        Set<String> convertStages = new Set<String>();
        Map<String,Map<String,Integer>> pivot = new Map<String,Map<String,Integer>>();
        List<LeadSummaryLine> pivot2 = new List<LeadSummaryLine>();
        Integer i = 0;
        for (AggregateResult ar : leadList){
            String cStage = (String)ar.get('ConvertStage');
            convertStages.add(cStage);
            
            //Insert entry if required
            String lSource = (String)ar.get('leadSource');
            if(!pivot.containsKey(lSource)){
                pivot.put(lSource, new Map<String,Integer>());
            }
            //insert value
            pivot.get(lSource).put(cstage, (Integer)ar.get('leadCount'));
            
            System.Debug( ar);
            if (i >=50) break;
            i++;
            
        }
        for(String k : pivot.keyset()){
            Map<String, Integer> kReasons = pivot.get(k);
            LeadSummaryLine l = new LeadSummaryLine(k, kReasons);
            pivot2.add(l);
            
                
        }
        
        System.Debug(convertStages);
        System.Debug(pivot);
        System.Debug(pivot2);
    
    }

}