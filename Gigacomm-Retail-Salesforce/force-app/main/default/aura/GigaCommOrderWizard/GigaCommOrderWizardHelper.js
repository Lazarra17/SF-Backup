/**
 * @description Helper JS for GigacommOrderWizard cmp
 * @author Bricoleur Technologies
 * [1] JPS 31 May - Update pushToGTM code structure
 * [2] CL 6 June - commented out console logs
 * [3] CL Aug 12 - Added coupon to GTM
 * [4] CL Feb 4 - Use Cookie for capturing the Enquiry Id if null
 */
({
    getLead : function(component,event) {
        
        const searchParams = new URLSearchParams(window.location.search);
        var enquiry = searchParams.get('enquiry');
        
        //[4] CL Feb 4 - Use Cookie for capturing the Enquiry Id if null
        if(enquiry == null){
            enquiry = this.getCookie('leadId');
        }
        if(enquiry != null 	&& enquiry != ''){
            
            var action = component.get("c.getLead");         
            
            action.setParams({       
                enquiryId : enquiry
            });   
            action.setCallback(this, function(response) {   
                var state = response.getState();      
                if (state === "SUCCESS") {
                    var res = response.getReturnValue();  
                    
                    if(res == null){
                        window.open('/giga/s/our-plans', '_self');
                        return;
                    }
                    
                    if(res.Installation != null && res.InstallationPromo){
                        res.InstallationsTotalPrice = res.Installation.Total_Price_bric__c + res.InstallationPromo.Total_Price_bric__c;
                    }else if(res.Installation != null){
                        res.InstallationsTotalPrice = res.Installation.Total_Price_bric__c;
                    }
                    
                    component.set('v.lead', res);
                  
                    /*
                    	Get the Plans from POQ API
                    */
                    if(res.Plans != null){
                        component.set('v.plans', res.Plans); 
                    }
                    
                    this.onLoadPushToGTM(res);
                    
                    document.getElementById('payload').value = JSON.stringify(res);
                    document.getElementById("gcIconCross").style.display = "block";
                    
                } else if (state === "INCOMPLETE") {
                    //console.log("No response from server or client is offline.");
                    this.showModalError(component, event);
                    // Show offline error
                }
                    else if (state === "ERROR") {
                        var errors = response.getError();  
                        //console.log("Error: " + errors[0].message);
                        this.showModalError(component, event);
                        // Show error message
                    }        
            });               
            
            $A.enqueueAction(action);     
            
        }
        
    },
    
    getPlans : function(component,helper) {
        
        var action = component.get("c.getPlans");         
        
        action.setParams({       
            
        });     
        action.setCallback(this, function(response) {            
            
            var state = response.getState();            
            
            if (state === "SUCCESS") {     
                var res = response.getReturnValue();  
                
                component.set('v.plans', res); 
            } else if (state === "INCOMPLETE") {
                console.log("No response from server or client is offline.")
            }
                else if (state === "ERROR") {
                    var errors = response.getError();  
                    console.log("Error: " + errors[0].message);
                }        
        });               
        
        
        $A.enqueueAction(action);     
        
    },
    
    getRouter : function(component,helper) {
        
        var action = component.get("c.getRouter");         
        
        action.setParams({       
            
        });    
        action.setCallback(this, function(response) {            
            
            var state = response.getState();            
            
            if (state === "SUCCESS") {     
                var res = response.getReturnValue();  
                component.set('v.router', res); 
            } else if (state === "INCOMPLETE") {
                console.log("No response from server or client is offline.");
                // Show offline error
            }
                else if (state === "ERROR") {
                    var errors = response.getError();  
                    console.log("Error: " + errors[0].message);
                    // Show error message
                }        
        });               
        
        $A.enqueueAction(action);     
        
    },
    
    
    createLead: function(component, event, lead) {
        var action = component.get("c.createLead");
        var ipAddress = component.get('v.ipAddress');
        
        lead.IPAddress = ipAddress;
        action.setParams({  
            'siteLead' : JSON.stringify(lead)
        });    
        
        action.setCallback(this, function(response) {            
            
            var state = response.getState();   
            if (state == "SUCCESS") {   
                var res = response.getReturnValue();  

                
                res.Address = lead.Address;
                component.set('v.lead', res);
                component.set('v.plans', res.Plans); 
                
                //Add leadId to Cookie
                document.cookie = 'leadId=' + res.Id;
                
                component.set('v.showLoading', false);
                component.set('v.showSpinner', false);
                
              
                if(res.Status == 'Address Check' && res.Serviceable){
                     scrollTo({top: 700, behavior: "smooth"});
                }
                
                //Push to Google Tag Manager
                this.pushToGTM(res);
                
                
                //Show Error whenever API is Down
                if(res.StatusCode != null && res.StatusCode >= 400){
                    this.showModalError(component, event);
                }
                
                document.getElementById("gcIconCross").style.display = "block";
                document.getElementById('payload').value = JSON.stringify(res);
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
            document.getElementById("gcIconCross").style.display = "block";
            component.set('v.showLoading', false);
            component.set('v.showSpinner', false);
        });               
        
        $A.enqueueAction(action);     
        
        
        
    },
    
    updateLead: function(component, lead) {
        
        var action = component.get("c.updateLead");  
           action.setParams({
            'siteLead' : JSON.stringify(lead)
        });    
        
        action.setCallback(this, function(response) {            
            
            var state = response.getState();   
            if (state == "SUCCESS") {   
                var res = response.getReturnValue();  
                
                component.set('v.lead', res);
                component.set('v.plans', res.Plans); 
                //Push to Google Tag Manager
                this.pushToGTM(res);
                
                if(res.Status == 'Address Check' && res.Serviceable){
                    
                    
               
                    
                    scrollTo({top: 700, behavior: "smooth"});
                }else if(res.Status == 'Plan Selected' && res.PlanSelected != null && res.Serviceable){
                    
                    window.setTimeout(
                        $A.getCallback(function() {
                             document.getElementById("routerSection").scrollIntoView(); //Scroll to Router Section
                        }), 500
                    );
                   
                    
                }
                
                component.set('v.showSpinner', false);
                //Show Error whenever API is Down
                if(res.StatusCode != null && res.StatusCode >= 400){
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
            }     
            
            component.set('v.showLoading', false);
            component.set('v.showSpinner', false);
            //show the deleteAddress
            document.getElementById("gcIconCross").style.display = "block";
            
        });               
        
        $A.enqueueAction(action);     
        
        
        
    },
    
    
    
    removeItem: function(component, lead) {
        var action = component.get("c.removeItem");  
        action.setParams({
            'siteLead' : JSON.stringify(lead)
        });    
        action.setCallback(this, function(response) {            
            
            var state = response.getState();   
            if (state == "SUCCESS") {   
                var res = response.getReturnValue();  
                component.set('v.lead', res);
                
                document.getElementById('payload').value = JSON.stringify(res);
                res.ItemDeleted = true;
                
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
            }   
            
             component.set('v.showSpinner', false);
        });               
        
        $A.enqueueAction(action);     
                
    },
    
    navigateTo : function (component, event) {
        var urlEvent = $A.get("e.force:navigateToURL");
        var url = '/giga/s/our-plans';
        urlEvent.setParams({
            "url": url
        });
        urlEvent.fire(); 
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
        
        if(response.Status == 'Address Check' && response.Serviceable){
           
            //View Plans Eligible
            var detail = new Object();
            detail.event = 'view_plans_eligible';
            detail.lead_id = response.Id;
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
        
       /** [1] JPS 31 May - Update pushToGTM code structure */
        
    },
    
    
    //Method for Google Tag Manager
    onLoadPushToGTM : function (response) {
        var voucher = this.getCookie('voucher');
        var detail = new Object();
        //View Plans Eligible
        detail.event = 'view_plans_eligible';
        detail.lead_id = response.Id;
        detail.state = response.State;
        detail.postcode = response.PostCode;
        detail.coupon = voucher;
        
        var event = new CustomEvent("datalayerpush", {
            detail,
            bubbles: true,
            composed: true // optional in Aura, but safe to include
        });
        document.dispatchEvent(event);
        
        
        
        
        
        
    },
    
    cookiePromoCode : function (component, event) {
        const searchParams = new URLSearchParams(window.location.search);
        
        if(searchParams.get('voucher') != null){
            var voucher = 'voucher=' + searchParams.get('voucher'); 
            document.cookie = voucher;
            component.set('v.promoCodeReferral', searchParams.get('voucher'));
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