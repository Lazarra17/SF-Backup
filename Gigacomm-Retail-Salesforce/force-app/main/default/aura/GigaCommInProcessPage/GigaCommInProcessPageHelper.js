/**
 * @description Helper JS for GigacommOrderWizard cmp
 * @author Bricoleur Technologies
 * [1] JPS 31 May 2025 - Update pushToGTM code structure
 */
({
    
    updateLead: function(component, event) {
        const searchParams = new URLSearchParams(window.location.search);
        const uref = searchParams.get('uref');
        const cref = searchParams.get('cref');
        console.log(uref);
         console.log(cref);
        var action = component.get("c.updateLead");  
        
        action.setParams({
            'uref' : uref,
            'cref' : cref
        });    
            
            action.setCallback(this, function(response) {            
            
            var state = response.getState();   
            if (state == "SUCCESS") {   
                var res = response.getReturnValue();  
                this.pushToGTM(res);
                
                
                
                
                
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
        });               
        
        $A.enqueueAction(action);     
        
        
        
    },
    
    
    navigateToSuccessPage : function (response) {
        var urlEvent = $A.get("e.force:navigateToURL");
        var url = '/giga/s/payment-success';
        
        urlEvent.setParams({
            "url": url
        });
        urlEvent.fire();
    },
    
    //Method for Google Tag Manager
    pushToGTM : function (response) {
  
		var voucher = this.getCookie('voucher');
        var detail = new Object();
        
        detail.event = 'checkout_payment';
        detail.state = response.Oppty.Account.BillingStateCode;
        detail.postcode = response.Oppty.Account.BillingPostalCode;
        detail.plan_id = response.Oppty.Plan_bric__r.ProductCode;
        detail.plan_length = response.Oppty.Term_bric__c;
        detail.plan_type = response.Oppty.Plan_bric__r.Download_Upload_Limit_bric__c;
        detail.hardware_include = response.hardwareInclude;
        detail.order_id = response.Oppty.Id;
        detail.lead_id = response.Oppty.Lead_bric__c;
        detail.coupon = voucher;
        detail.direct_debit = 'successful';

        if(detail != null) {
            var event = new CustomEvent("datalayerpush", {
                detail,
                bubbles: true,
                composed: true // optional in Aura, but safe to include
            });
            document.dispatchEvent(event);
            console.log('Google Tag Manager Fired');
        }

        //Delete Cookies
        document.cookie = 'voucher=;';
        
        /** [1] JPS 31 May 2025 - Update pushToGTM code structure */
        this.navigateToSuccessPage(response);
        
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
    
    showModalError : function (component, event) {
        component.set('v.apiHasError', true);
    },
})