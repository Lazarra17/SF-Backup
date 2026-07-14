({
	createLead: function(component, event, lead) {
        
        var action = component.get("c.createLead");
 		lead.IPAddress = component.get('v.ipAddress');
        action.setParams({  
            'siteLead' : JSON.stringify(lead)
        });    
        
        action.setCallback(this, function(response) {            
            
            var state = response.getState();   
            if (state == "SUCCESS") {   
                var res = response.getReturnValue();  
                res.Address = lead.Address; 
                component.set('v.lead', res);
                
             
                this.pushToGTM(res);
                
                if(res.StatusCode >= 400){
                    this.showModalError(component, event);
                }
                
              
                
            } else if (state == "INCOMPLETE") {
                console.log("No response from server or client is offline.");
                this.showModalError(component, event);
                // Show offline error
            }else if (state == "ERROR") {
                console.log('ERROR');
                console.log(response);
                var errors = response.getError();  
                console.log("Error: " + errors[0].message);
                this.showModalError(component, event);
                // Show error message
            }else{
               
            }
            
            
        });               
        
        $A.enqueueAction(action);     
        
        
    },
    
     showModalError : function (component, event) {
        component.set('v.apiHasError', true);
    },
    
    //Method for Google Tag Manager
    pushToGTM : function (response) {
        var voucher = this.getCookie('voucher');
        var serviceable;
        if(response.Serviceable){
            serviceable = 'eligible';
        }else{
            serviceable = 'ineligible';
        }
        
        var detail = new Object();
        if(response.Status == 'Address Check' && response.Serviceable){
            
            detail.event = 'address_check';
            detail.lead_id = response.Id;
            detail.serviceability = serviceable;
            detail.state = response.State;
            detail.postcode = response.PostCode;
            detail.coupon = voucher;
            
            
            var event = new CustomEvent("datalayerpush", {
                detail,
                bubbles: true,
                composed: true // optional in Aura, but safe to include
            });
            document.dispatchEvent(event);
            
            
            
        }
        
        
        
    },
    
    getCookie : function(queryParam) {
        
        let name = queryParam + "=";
        let decodedCookie = decodeURIComponent(document.cookie);
        let ca = decodedCookie.split(';');
        for(let i = 0; i <ca.length; i++) {
            let c = ca[i];
            while (c.charAt(0) == ' ') {
                c = c.substring(1);
            }
            if (c.indexOf(name) == 0) {
                return c.substring(name.length, c.length);
            }
        }
        return "";
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