/*
@Author: Chad Lazarra (Bricoleur Technology)
@Date: 2-October-25
@Desc:
@History: 
[1] CLAZARRA 2-October-25 Created
*/
public class MefGetOrderStatusInvocable {
    
    // Custom class for input and output parameters
    public class MefGetOrderStatusInput {
        @InvocableVariable(label='Opportunity ID' description='ID of the record' required=true)
        public Id recordId;
        
        
    }
    
    public class MefGetOrderStatusOutput {
        @InvocableVariable(label='Processed Status' description='Mef Status')
        public String status;
    }
    
    @InvocableMethod(label='Perform Action on Record' description='Get the Mef Order Status')
    public static List<MefGetOrderStatusOutput> performAction(List<MefGetOrderStatusInput> records) {
        List<MefGetOrderStatusOutput> results = new List<MefGetOrderStatusOutput>();
        system.debug('RECORDS');
        system.debug(records);
        
        
        for (MefGetOrderStatusInput record : records) {
            MefGetOrderStatusOutput output = new MefGetOrderStatusOutput();
            
            Opportunity opp = [SELECT Id, Completion_Date_bric__c, Expected_Completion_Date_bric__c, Mef_Product_Order_Note_Ids_bric__c,
                               Mef_Order_Product_Id_bric__c, Mef_Status_bric__c, Service_Identification_Number_bric__c  FROM Opportunity WHERE Id =: String.valueOf(record.recordId)];
            
            system.debug('opp');
            system.debug(opp);
            HttpResponse response = MefGetOrderStatus.getOrderStatus(opp);
            output.status = String.valueOf(response.getStatusCode());
            
            results.add(output);
        }
        return results;
    }
    
    
}