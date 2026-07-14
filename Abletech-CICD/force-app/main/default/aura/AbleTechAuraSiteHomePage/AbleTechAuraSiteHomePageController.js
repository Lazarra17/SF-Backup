({
    contactUs : function(component, event, helper) {
        
        var modalBody;
        // Dynamically create the content component
        $A.createComponent(
            "c:AbleTechAuraSiteFlowModal",
            {
                "recordId": "",
                "flowApiName": "Create_a_Case_Bric"
            },
            function(content, status, errorMessage) {
                if (status === "SUCCESS") {
                    modalBody = content;
                    // Open the modal using overlayLibrary
                    component.find('overlayLib').showCustomModal({
                        body: modalBody,
                        showCloseButton: true,
                        cssClass: "slds-modal_medium no-flex-modal" // Adjust size as needed (small, medium, large)
                    });
                } else if (status === "ERROR") {
                    console.error("Error creating component: " + errorMessage);
                }
            }
        );
        
    },
    
    RequestQuote : function(component, event, helper) {
        
        var modalBody;
        // Dynamically create the content component
        $A.createComponent(
            "c:AbleTechAuraSiteFlowModal",
            {
                "recordId": "",
                "flowApiName": "Request_a_Quote_Bric"
            },
            function(content, status, errorMessage) {
                if (status === "SUCCESS") {
                    modalBody = content;
                    // Open the modal using overlayLibrary
                    component.find('overlayLib').showCustomModal({
                        body: modalBody,
                        showCloseButton: true,
                        cssClass: "slds-modal_medium no-flex-modal" // Adjust size as needed (small, medium, large)
                    });
                } else if (status === "ERROR") {
                    console.error("Error creating component: " + errorMessage);
                }
            }
        );
        
    },
    
    handleStatusChange : function(component, event, helper) {
        // Optional: Handle what happens when the flow finishes or changes status
        if(event.getParam("status") === "FINISHED") {
            // Take action when the flow completes, like closing a modal or refreshing the page
            var dismissActionPanel = $A.get("e.force:closeQuickAction");
            if (dismissActionPanel) {
                dismissActionPanel.fire();
            }
        }
    }
})