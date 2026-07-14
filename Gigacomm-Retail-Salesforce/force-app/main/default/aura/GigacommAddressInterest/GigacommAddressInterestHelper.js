/**
 * @description Helper JS for GigacommOrderWizard cmp
 * @author Bricoleur Technologies
 * [1] JPS 31 May 2025 - Update pushToGTM code structure
 */
({
	createLead: function(component, event) {
        var payload = document.getElementById('payload').value;
        //console.log('payload' + JSON.stringify(payload));
        var address = JSON.parse(payload); 
        var lead = component.get('v.lead');
        //console.log('address');
        //console.log(address);
        address.FirstName = lead.FirstName;
        address.LastName = lead.LastName;
        address.Email = lead.Email;
        address.IPAddress = component.get('v.ipAddress');
        var action = component.get("c.createLead");
        action.setParams({  
            'siteLead' : JSON.stringify(address)
        });    
        
        action.setCallback(this, function(response) {            
            
            var state = response.getState();   
            if (state == "SUCCESS") {   
                var res = response.getReturnValue();  
                
                this.pushToGTM(res);
                
           
				document.getElementById('collapseRegisterAddress').classList.remove("show");
                document.getElementById('collapseRegisterAddressThankYou').classList.add("show");
                
              
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
    
    //Method for Google Tag Manager
    pushToGTM : function (response) {
        //console.log('Google Tag Manager Fired');
        var voucher = this.getCookie('voucher');
        
        var serviceable;
        if(response.Serviceable){
            serviceable = 'eligible';
        }else{
            serviceable = 'ineligible';
        }

        var detail = new Object();
        
        detail.event = 'generate_lead';
        detail.lead_id = response.Id;
        detail.lead_source = 'form_unserviceable_area';
        detail.state = response.StateCode;
        detail.postcode = response.PostalCode;
        detail.coupon = voucher;
        
        if(detail != null) {
            var event = new CustomEvent("datalayerpush", {
                detail,
                bubbles: true,
                composed: true // optional in Aura, but safe to include
            });
            document.dispatchEvent(event);
        
        }
        /** [1] JPS 31 May 2025 - Update pushToGTM code structure */
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