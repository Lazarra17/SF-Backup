/**
 * @description Helper JS for GigacommPersonalDetails cmp
 * @author Bricoleur Technologies
 * [1] JPS 3 Jun 2025 - Add a seperate gtm event for Place orders function
 */
({
    
    getLead : function(component,event) {
        
        const searchParams = new URLSearchParams(window.location.search);
        const enquiry = searchParams.get('enquiry');
        var tc = component.get('v.tc');
        //console.log(enquiry);
        
        if(enquiry != null 	){
            
            var action = component.get("c.getLead");         
            
            action.setParams({       
                enquiryId : enquiry
            });    
            action.setCallback(this, function(response) {            
                
                var state = response.getState();            
                
                if (state === "SUCCESS") {
                      
                    var res = response.getReturnValue();  
                    //console.log('GET LEAD: ' );
                    //console.log(res);
                    if(res == null){
                        this.navigateTo(component, event);
                    }
                  
                    if(res.Installation != null && res.InstallationPromo){
                        res.InstallationsTotalPrice = res.Installation.Total_Price_bric__c + res.InstallationPromo.Total_Price_bric__c;
                    }else if(res.Installation != null){
                        res.InstallationsTotalPrice = res.Installation.Total_Price_bric__c;
                    }
                    
                    component.set('v.lead', res);
                    
                    if(res.Lead.Voucher_bric__c != null){
                        component.set('v.promoCode', res.Lead.Voucher_bric__r.Voucher_Code_bric__c);
                    }
                    
                    tc.tc1 = res.Lead.Agree_Terms_bric__c;
                    tc.tc2 = res.Lead.Agree_Cooling_Off_bric__c;
                    tc.tc3 = res.Lead.Permit_Technician_Access_bric__c;
                    tc.tc4 = res.Lead.Accept_Marketing_Terms_bric__c;
                    //tc.tc5 = res.Lead.Has_Voucher_T_C_bric__c;
                    component.set('v.tc', tc);
                   
                    console.log(tc);
                    //Enable TC button if
                    if(res.PlanSelected.Product_bric__r.Installer_Access_Required_bric__c && res.Lead.Agree_Terms_bric__c && res.Lead.Agree_Cooling_Off_bric__c && res.Lead.Permit_Technician_Access_bric__c){
                        component.set('v.acceptedTC', true);
                        component.set('v.enableBtn', true);
                      
                      
                        
                    }else if(!res.PlanSelected.Product_bric__r.Installer_Access_Required_bric__c && res.Lead.Agree_Terms_bric__c && res.Lead.Agree_Cooling_Off_bric__c){
                        component.set('v.acceptedTC', true);
                        component.set('v.enableBtn', true);
                       
                    }
                  
                    
                    
                    if(res.Lead.FirstName == null || res.Lead.TECH_LastName_bric__c == null || res.Lead.Email == null || res.Lead.MobilePhone == null){
                        component.set('v.confirmDetails', false);
                          
                     
                    }else{
                        component.set('v.confirmedDetails', true);
                        component.set('v.showTCMobile', true);
                    }
                    
                    
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
    
    
    updateLead: function(component, event) {
        component.set('v.showSpinner', true);
        var btnVal = event.currentTarget.value;
        var action = component.get("c.updateLead");  
        var lead = component.get("v.lead");
        var convertLead = false;
        var device = $A.get("$Browser.formFactor");
        var acceptedTC = component.get('v.acceptedTC');
        var promoCode = component.get("v.promoCode");
        //console.log(device);
        //console.log('BTN VAL: ' + btnVal);
        if(btnVal == 'placeOrder'){
            convertLead = true;
        }
        action.setParams({
            'siteLead' : JSON.stringify(lead),
            'convertLead' : convertLead
        });    
        
        action.setCallback(this, function(response) {            
            
            var state = response.getState();   
            if (state == "SUCCESS") {   
                var res = response.getReturnValue();  
                
                
                component.set('v.showSpinner', false);
                if(btnVal == 'confirmDetails' && device != 'PHONE' && !acceptedTC){
                    document.getElementById('collapseAddress').classList.remove("collapse");
                    document.getElementById('collapseAddress').classList.add("show");
                }else if(btnVal == 'confirmDetails' && device == 'PHONE'){
                    component.set('v.showTCMobile', true);
                    scrollTo({top: 1340, behavior: "smooth"});
                    
                }
                
                
				component.set('v.confirmedDetails', true);                
                //[1] JPS 3 Jun 2025 - Add a seperate gtm event for Place orders function
                //this.pushToGTM(res);
                this.pushToGTM(res, btnVal, promoCode);
                //[1] JPS 3 Jun 2025 - Add a seperate gtm event for Place orders function
                
                //console.log('BUTTON: ' + btnVal);
                if(btnVal == 'placeOrder'){
                    
                    this.navigateToCongrats(res);
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
            
             component.set('v.showSpinner', false);
        });               
        
        $A.enqueueAction(action);     
        
        
        
    },
    
    updateLeadTC: function(component, event) {
        component.set('v.showSpinner', true);
        var action = component.get("c.updateLeadTC");  
        var tc = component.get('v.tc');
        var lead = component.get("v.lead");
        var device = $A.get("$Browser.formFactor");
        var payload = new Object();
        payload.Id = lead.Lead.Id;
        payload.Agree_Terms_bric__c = tc.tc1;
        payload.Agree_Cooling_Off_bric__c = tc.tc2;
        payload.Permit_Technician_Access_bric__c = tc.tc3; 
        payload.Accept_Marketing_Terms_bric__c = tc.tc4;
        
        /*
        if(lead.VoucherTCs != null){
            payload.Has_Voucher_T_C_bric__c = tc.tc5;
            payload.Voucher_T_C_bric__c = lead.VoucherTCs[0].Voucher_T_C__c;
        }
        */
        
        action.setParams({
            'siteLead' : JSON.stringify(payload)
        });    
        
        action.setCallback(this, function(response) {            
            
            var state = response.getState();   
            if (state == "SUCCESS") {   
                var res = response.getReturnValue();  
                component.set('v.showSpinner', false);
            	 component.set("v.enableBtn", true);
                
                window.setTimeout(
                    $A.getCallback(function() {
                        document.getElementById("PlaceOrderSection").scrollIntoView(); //Scroll to Place Order Section
                    }), 500
                );
                
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
    
    applyPromoCode: function(component, event) {
        component.set('v.showSpinner', true);
        var action = component.get("c.applyPromoCode");  
        var lead = component.get("v.lead");
        var promoCode = component.get("v.promoCode");
		var device = $A.get("$Browser.formFactor");        
        action.setParams({
            'siteLead' : JSON.stringify(lead),
            'promoCode' : promoCode
        });    
        
        action.setCallback(this, function(response) {            
            
            var state = response.getState();   
            if (state == "SUCCESS") {   
                var res = response.getReturnValue();  
                
                if(res.Installation != null && res.InstallationPromo){
                    res.InstallationsTotalPrice = res.Installation.Total_Price_bric__c + res.InstallationPromo.Total_Price_bric__c;
                }else if(res.Installation != null){
                    res.InstallationsTotalPrice = res.Installation.Total_Price_bric__c;
                }
                
                component.set('v.lead', res);
                component.set('v.showSpinner', false);
                //Disable the placeorder button 
                
          
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
    
    
    deleteVouchers: function(component, event) {
        component.set('v.showSpinner', true);
        var action = component.get("c.deleteVouchers");  
        var lead = component.get("v.lead");
        var promoCode = component.get("v.promoCode");
        
        action.setParams({
            'siteLead' : JSON.stringify(lead),
            'promoCode' : promoCode
        });    
        
        action.setCallback(this, function(response) {            
            
            var state = response.getState();   
            if (state == "SUCCESS") {   
                var res = response.getReturnValue();  
                
                component.set('v.lead', res);
                component.set('v.showSpinner', false);
                component.set('v.promoCode', '');
                
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
        var url = '/';
        
        urlEvent.setParams({
            "url": url
        });
        urlEvent.fire();
    },
    
    
    navigateToCongrats : function (res) {
        
      
        var urlEvent = $A.get("e.force:navigateToURL");
        var url = '/giga/s/congratulations?enquiry=' + res.OpportunityId;
        
        window.open(url, '_self');
        /*
        urlEvent.setParams({
            "url": url
        });
        urlEvent.fire();
        */
    },    
    
    toggleCheckboxes: function (component, event) {
        var lead = component.get("v.lead");
        var checkbox = event.currentTarget.checked;
        var tc = component.get('v.tc');
       
        
        if (checkbox) {
            tc.tc1 = true; //Terms Agreement checkbox
            tc.tc2 = true; //Cooling off checkbox
            tc.tc4 = true; // Marketing Checkbox
            
            /*
            if(lead.VoucherTCs != null){
                tc.tc5 = true; //TC Checkbox
            }  
            */
            
            if(lead.PlanSelected.Product_bric__r.Installer_Access_Required_bric__c){
                tc.tc3 = true;
            }
            component.set('v.acceptedTC', true); //[7] CL 6 Jun 2025 - Fix mobile TC Button
        }
        else{ 
            tc.tc1 = false;
            tc.tc2 = false;
            tc.tc3 = false;
            tc.tc4 = false;
            //tc.tc5 = false;
            component.set('v.acceptedTC', false);
            component.set("v.enableBtn", false); //[7] CL 6 Jun 2025 - Fix mobile TC Button
        } 
        component.set('v.tc', tc);
        
    },
    
    
    isTCsAccepted: function (component, event) {
        var tc = component.get('v.tc');
  		var lead = component.get("v.lead");
        var tcAccepted = true;
        
       
        if(!tc.tc1 || !tc.tc2){
            tcAccepted = false
        }
        
         if(lead.PlanSelected.Product_bric__r.Installer_Access_Required_bric__c && !tc.tc3){
            tcAccepted = false;
        }
        /*
        if(lead.VoucherTCs != null && !tc.tc5){
            tcAccepted = false;
        }
        */
        
        if(tcAccepted){
            component.set('v.acceptedTC', true); 
        }else{
            component.set('v.acceptedTC', false);
            component.set("v.enableBtn", false);
        }
        
        
      /*
        if(lead.PlanSelected.Product_bric__r.Installer_Access_Required_bric__c){
       
            if(tc.tc1 && tc.tc2 && tc.tc3){
                component.set('v.acceptedTC', true); 
            }else{
                component.set('v.acceptedTC', false);
                component.set("v.enableBtn", false);
            }
            
        }
        else if(!lead.PlanSelected.Product_bric__r.Installer_Access_Required_bric__c && tc.tc1 && tc.tc2){
            component.set('v.acceptedTC', true);
        }else{
            component.set('v.acceptedTC', false);
            component.set("v.enableBtn", false);
        }
        */
        
        
        
        
    },
    
    
	pushToGTM : function (response, btnVal, promoCode) {
        var hasRouter;
        
        
        if(response.Router != null){
            hasRouter = true;
        }else{
            hasRouter = false;
        }
        
        var gtmEvt;
        
        if(btnVal == 'placeOrder') {
            gtmEvt = 'checkout_place_order';
        }
        else if(btnVal == 'confirmDetails') {
            gtmEvt = 'checkout_customer_details';
        }
        
        var detail = new Object();
        detail.user_id = response.ContactId;
        detail.event = gtmEvt;
        detail.lead_id = response.Lead.Id;
        detail.state = response.Lead.StateCode;
        detail.postcode = response.Lead.PostalCode;
        detail.plan_id = response.PlanSelected.Product_bric__r.ProductCode;
        detail.plan_length = response.Lead.Term_bric__c;
        detail.plan_type = response.PlanSelected.Product_bric__r.Download_Upload_Limit_bric__c;
        detail.hardware_include = hasRouter;
        detail.order_id = response.OpportunityId;
        detail.coupon = promoCode;
        
        if(detail != null){
            var event = new CustomEvent("datalayerpush", {
                detail,
                bubbles: true,
                composed: true // optional in Aura, but safe to include
            });
            document.dispatchEvent(event);
        }  
    },
    //[1] JPS 3 Jun 2025 - Add a seperate gtm event for Place orders function
    
    showModalError : function (component, event) {
        component.set('v.apiHasError', true);
    },
    
})