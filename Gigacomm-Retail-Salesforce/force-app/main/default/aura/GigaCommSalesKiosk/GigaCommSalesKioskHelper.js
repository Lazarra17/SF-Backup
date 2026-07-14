({
    createLead: function(component, event, lead) {
        
        var action = component.get("c.createLead");
        const searchParams = new URLSearchParams(window.location.search);
        const kiosk = searchParams.get('Kiosk');
        var agentCode = component.get('v.AgentCode');
        
        action.setParams({  
            'kioskId' : kiosk,
            'agentCode' : agentCode
        });    
        
        action.setCallback(this, function(response) {            
            
            var state = response.getState();   
            if (state == "SUCCESS") {   
                var res = response.getReturnValue();  
                console.log('SUCCESS');
                console.log(res);
				this.navigateTo(component, event, res);
            } else if (state == "INCOMPLETE") {
                console.log("No response from server or client is offline.")
                // Show offline error
            }else if (state == "ERROR") {
                console.log('ERROR');
                console.log(response);
                var errors = response.getError();  
                console.log("Error: " + errors[0].message);
                // Show error message
            }else{
               
            }
        });               
        
        $A.enqueueAction(action);     
        
        
        
    },
    
    
    navigateTo : function (component, event) {
        const searchParams = new URLSearchParams(window.location.search);
        const kiosk = searchParams.get('Kiosk');
        var agentCode = component.get('v.AgentCode');
        
        
        var agentCode = component.get('v.AgentCode');
        if(agentCode != null){
             
            var urlEvent = $A.get("e.force:navigateToURL");
            var url = '/giga/s/our-plans?';
            url = url + 'kiosk=' + kiosk + '&agentCode=' + agentCode;
            console.log(url);
            urlEvent.setParams({
                "url": url
            });
            urlEvent.fire();
            
        }
    },
})