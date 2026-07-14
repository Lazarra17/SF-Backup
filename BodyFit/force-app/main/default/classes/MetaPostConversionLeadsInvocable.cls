/*
@Author: Chad Lazarra (Bricoleur Technology)
@Date: 12-Sept-25
@Desc:
@History:
[1] CLAZARRA 12-Sept-25 : Created
*/
public class MetaPostConversionLeadsInvocable {
    
    @InvocableMethod(label='Invoke Meta Conversions API' description='Send sf payload to Meta')
    public static List<Results> processConversionLeads(List<Requests> requestList) {
        List<Results> responseList = new List<Results>();
        for (Requests req : requestList) {
            
            //Invoke API via Asyncronous Flow
            MetaPostConversionLeads.PostConversionLead(req.lead);
        }
        
        
        return responseList;
    }
    
    // Inner class for input parameters
    public class Requests {
        @InvocableVariable(label='Lead' description='Lead Object')
        public Lead lead;
    }
    
    // Inner class for output parameters
    public class Results {
        @InvocableVariable(label='Lead' description='The name of the processed leads.')
        public Lead lead;
    }
}