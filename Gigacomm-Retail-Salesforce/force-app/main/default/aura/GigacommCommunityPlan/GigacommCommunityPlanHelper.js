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
    
    
    
    createLead : function(component, event) {
        var l = component.get('v.lead');
        var tc = component.get('v.tc');
        l.LeadSource = 'Gigacomm Community';
        l.IP_Address_bric__c = component.get('v.ipAddress');
        l.Agree_Terms_bric__c = tc.tc2;
        
        var action = component.get("c.createLead");    
        action.setParams({       
            lead : JSON.stringify(l)
        });    
        action.setCallback(this, function(response) {            
            
            var state = response.getState();            
            
            if (state === "SUCCESS") {
                var res = response.getReturnValue();  
                
                component.set('v.showAgreement', false);
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