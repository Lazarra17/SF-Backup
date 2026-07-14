({
    init : function(component, event, helper) {
        // Find the flow component by aura:id
        var flow = component.find("flowData");
        var flowApiName = component.get("v.flowApiName");
        // Optional: Pass input variables into the flow (e.g., recordId)
        var inputVariables = [
            { name : "recordId", type : "String", value : component.get("v.recordId") }
        ];
        
        // Start the flow using its unique API Name
        flow.startFlow(flowApiName, inputVariables);
    },

    handleStatusChange : function(component, event, helper) {
        // Check if the flow is finished
        var status = event.getParam("status");
        if (status === "FINISHED") {
            component.find("refreshChannel").publish({ refresh: true });
            component.find("overlayLib").notifyClose();
            /*
            // Optional: Show a success toast or refresh the view
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Success!",
                "message": "New record has been created successfully.",
                "type": "success"
            });
            toastEvent.fire();
            */
        }
    }
})