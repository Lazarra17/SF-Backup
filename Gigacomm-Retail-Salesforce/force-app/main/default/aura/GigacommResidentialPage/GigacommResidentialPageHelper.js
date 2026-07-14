({
   getPlans : function(component,helper) {
        
        var action = component.get("c.getPlans");         
        
        action.setParams({       
            
        });    
        action.setCallback(this, function(response) {            
            
            var state = response.getState();            
            
            if (state === "SUCCESS") {     
                var res = response.getReturnValue();  
              //  console.log('PLANS RESPONSE');
              //  console.log(res);
                /*
                res.forEach(function(item) {
                     console.log('##');
                    if(item.Plan.Product2.Banner_bric__c != null){
                        const bannerImg = item.Plan.Product2.Banner_bric__c.split('"');
                        item.Plan.Product2.Banner_bric__c = bannerImg[1].replaceAll('&amp;','&');
                        console.log(item.Plan.Product2.Banner_bric__c);
                    }
                    
                });
                */
               // console.log('PLANS');
               // console.log(res);
                component.set('v.plans', res); 
            } else if (state === "INCOMPLETE") {
                console.log("No response from server or client is offline.")
                this.showModalError(component, event);
                // Show offline error
            }
                else if (state === "ERROR") {
                    var errors = response.getError();  
                    console.log("Error: " + errors[0].message);
                    this.showModalError(component, event);
                    // Show error message
                }        
        });               
        
        $A.enqueueAction(action);     
        
    },
})