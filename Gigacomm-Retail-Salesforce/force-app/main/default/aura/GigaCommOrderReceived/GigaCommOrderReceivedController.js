({ 
    doInit : function (component, event, helper) {
        const searchParams = new URLSearchParams(window.location.search);
        const enquiry = searchParams.get('enquiry');

        var action = component.get("c.acceptOpp");
        action.setParams({ oppId: enquiry });

        action.setCallback(this, function(response) {
            const state = response.getState();
            if (state === "SUCCESS") {
                console.log("Opportunity updated successfully.");
            } else {
                const errors = response.getError();
                console.error("Error updating opportunity: ", errors);
            }
        });

        $A.enqueueAction(action);
    }
})