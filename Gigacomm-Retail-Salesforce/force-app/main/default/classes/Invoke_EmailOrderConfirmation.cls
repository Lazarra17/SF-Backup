/**
 * @author Bricoleur Technologies
 * @date May 20 2025
 * @description Invocable class to asynchronously execute Email Order Confirmation Record-Autolaunch Flow from Platform Event Flow.
 * [1] JPS 10 Jul 2025 - Refactor class and make it async
 */
public without sharing class Invoke_EmailOrderConfirmation {

    @InvocableMethod(label='Run flow with params asynchronously')
    public static void invokeFlowAsync(List<FlowInput> inputList) {
        if (inputList != null && !inputList.isEmpty()) {
            Id opportunityId = inputList[0].oppId;
            runFlowsInBackground(opportunityId);
        } 
    }

    @future
    public static void runFlowsInBackground(Id oppId) {
        try {
            Map<String, Object> flowParams = new Map<String, Object>();
            flowParams.put('recordId', oppId);

            Flow.Interview.Email_Order_Confirmation_Record_Autolaunch_Flow_Bric flowInterview =
                new Flow.Interview.Email_Order_Confirmation_Record_Autolaunch_Flow_Bric(flowParams);
            flowInterview.start();

        } catch(Exception e) {
            System.debug('Error executing flow for Opportunity ID ' + oppId + ': ' + e.getMessage());
        }
    }

    public class FlowInput {
        @InvocableVariable(label='OppId' description='Opportunity ID' required=true)
        public String oppId;

        @InvocableVariable(label='Opp Status' description='Opportunity Status')
        public String oppStatus;
    }
}