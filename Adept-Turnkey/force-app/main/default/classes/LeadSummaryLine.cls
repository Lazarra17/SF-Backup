public class LeadSummaryLine {
    
    public LeadSummaryLine(String leadSource, Map<String, Integer> reasons ){
        this.leadSource = leadSource;
        this.reasons = reasons;
        total = 0;
        winRatio = 0.0;            
    }
    //public:
    String leadSource;
    Map<String, Integer> reasons;
    Integer total;
    Double winRatio;
    
    public override String toString(){
        return leadSource + reasons + total + winRatio + '\n';
    }

}