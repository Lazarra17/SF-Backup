({
       
    getEziDebit : function(component,event) {
        
        const searchParams = new URLSearchParams(window.location.search);
        const enquiry = searchParams.get('enquiry');
        
        if(enquiry != null 	){
            
            var action = component.get("c.getEziDebit");         
            
            action.setParams({       
                enquiryId : enquiry
            });    
            action.setCallback(this, function(response) {            
                
                var state = response.getState();            
                
                if (state === "SUCCESS") {
                    
                    var res = response.getReturnValue(); 
                    console.log(res);
                    component.set('v.eziDebit', res);
                    
                    
                    
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
            
        }else{
            this.navigateTo(component, event);
        }
        
        
        
    },
    
    
    navigateTo : function (component, event) {
        var urlEvent = $A.get("e.force:navigateToURL");
        var url = '/';
        
        urlEvent.setParams({
            "url": url
        });
        urlEvent.fire();
    },
    
})