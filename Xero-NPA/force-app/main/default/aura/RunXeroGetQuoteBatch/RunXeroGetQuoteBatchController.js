({
    doInit : function(component, event, helper) {
        var action =component.get('c.runXeroGetQuoteBatch');
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                $A.get("e.force:closeQuickAction").fire();
            }
            else if (state === "INCOMPLETE") {
                $A.get("e.force:closeQuickAction").fire();
            }
                else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + 
                                        errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                    
                    $A.get("e.force:closeQuickAction").fire();
                }
        });
        
        $A.enqueueAction(action);
        
    }
})