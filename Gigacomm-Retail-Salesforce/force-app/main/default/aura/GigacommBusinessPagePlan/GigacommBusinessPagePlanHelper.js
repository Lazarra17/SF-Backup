({
	getStates : function(component, event) {
        
        var action = component.get("c.getPicklistValues");     
        action.setParams({       
            objObject : 'Lead',
            fld : 'StateCode',
            selected_string : null
        });    
        action.setCallback(this, function(response) {            
            
            var state = response.getState();            
            
            if (state === "SUCCESS") {
                
                var res = response.getReturnValue();  
             
                component.set('v.stateOptions', res);
                
            } else if (state === "INCOMPLETE") {
                console.log("No response from server or client is offline.")
                // Show offline error
            }
                else if (state === "ERROR") {
                    var errors = response.getError();  
                    console.log("Error: " + errors[0].message);
                    this.navigateTo(component, event);
                    // Show error message
                }        
        });               
        
        $A.enqueueAction(action);     
        
    },
})