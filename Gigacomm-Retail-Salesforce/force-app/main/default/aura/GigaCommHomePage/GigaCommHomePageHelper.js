/*
@Author: Chad Lazarra
@date: 
@History: [1] CL - 09-June-2025 - Capture address Ip address
		  [2] CL - 18-June-2025 - Autoredirect to Our Plan Page
*/
({
    

            
	createLead: function(component, event, lead) {
        var ipAddress = component.get('v.ipAddress');
        var action = component.get("c.createLead");
      
       // console.log('CREATE A LEAD');
        //console.log(JSON.stringify(lead));
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
              //  console.log(res);
              //  console.log('CALLBACK SUCCESS');
                document.getElementById("gcIconCross").style.display = "none";
                
                this.pushToGTM(res);
                
                if(res.StatusCode >= 400){
                    this.showModalError(component, event);
                }else if(res.Serviceable){
                    this.navigateTo(component, event, res);
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
                document.getElementById("gcIconCross").style.display = "block";
                // Show error message
            }else{
                document.getElementById("gcIconCross").style.display = "block";
            }
            
             component.set('v.showLoading', false);  
            
        });               
        
        $A.enqueueAction(action);     
        
        
    },
    
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
    
    //Method for Google Tag Manager
    pushToGTM : function (response) {
        
        var serviceable;
        if(response.Serviceable){
            serviceable = 'eligible';
        }else{
            serviceable = 'ineligible';
        }
        
        var detail = new Object();
        if(response.Status == 'Address Check'){
            
            detail.event = 'address_check';
            detail.lead_id = response.Id;
            detail.serviceability = serviceable;
            detail.state = response.State;
            detail.postcode = response.PostCode;
            
        }
        
        
        if(detail != null){
            //window.dataLayer = window.dataLayer || [];
            //window.dataLayer.push(obj);
            var event = new CustomEvent("datalayerpush", {
                detail,
                bubbles: true,
                composed: true // optional in Aura, but safe to include
            });
            document.dispatchEvent(event);
            //console.log('Google Tag Manager Fired');
        }
        
    },
    
    //JPS 20 May
    displayAddrThankyou : function(component, event) {
        
        var urlParams = new URLSearchParams(window.location.search);
        var leadRedirect = urlParams.get('leadredirect');

        if (leadRedirect === 'true') {
            component.set("v.leadRedirect", true);
            // You can add further redirect or processing logic here
        }
    },
    
    showModalError : function (component, event) {
        component.set('v.apiHasError', true);
    },
    
    navigateTo : function (component, event, res) {
        var urlEvent = $A.get("e.force:navigateToURL");
        var url = '/our-plans?';
    
        
        
        if(res != null){
            url = url + 'enquiry=' + res.Id;
        }
        
        urlEvent.setParams({
            "url": url
        });
        urlEvent.fire();
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
            component.set("v.ipAddress", Http.responseText);
        }
            
        },
    
    
})