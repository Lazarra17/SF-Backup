({
    
    
    createLead : function(component, event) {
        var l = component.get('v.lead');
        var action = component.get("c.createLead");   
        l.LeadSource = component.get('v.leadSource');
        l.IP_Address_bric__c = component.get('v.ipAddress');
        l.Accept_Marketing_Terms_bric__c = component.get('v.tc');
        action.setParams({       
            lead : JSON.stringify(l)
        });    
        action.setCallback(this, function(response) {            
            
            var state = response.getState();            
            
            if (state === "SUCCESS") {
                var res = response.getReturnValue();  
                component.set('v.showForm', false);
                component.set('v.showAcknowledgement', true);
   
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
    
    getIpAddress : function(component,helper) {
        const Http = new XMLHttpRequest();
        const url='https://api.ipify.org/';
        Http.open("GET", url);
        Http.send();
        Http.onreadystatechange=(e)=>{
            console.log(Http.responseText); // This prints Ip address
            component.set("v.ipAddress", Http.responseText);
        }
            
        },
    
})