/**
 * @description Controller JS for GigacommPersonalDetails cmp
 * @author Bricoleur Technologies
 * [1] JPS 31 May 2025 - Add logic to confirm if lead detail has been validated
 * [2] JPS 31 May 2025 - Add new function for Accept T&Cs to enable Place Order button
 * [3] CL 6 Jun 2025 - Fix mobile TC Button
 * [4] CL 9 Jun 2025 - Capture T&C and Marketing Fields
 */
({
    doInit : function(component, event, helper) {
        var tc = new Object();
        tc.tc1 = false;
        tc.tc2 = false;
        tc.tc3 = false;
        tc.tc4 = false;
        component.set('v.tc', tc);
        helper.getLead(component, event);
        
        
        
    },
    
    
    editDetails : function(component, event, helper) {
        component.set('v.confirmedDetails', false);
        
        
        
    },
    
    
    validateForm: function(component, event, helper) {
        var allValid = component.find('personDetailField').reduce(function (validSoFar, inputCmp) {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        
        if (allValid) {
            /*
            setTimeout(
                $A.getCallback(
                    function() {
                        component.find("orderForm").getElement().submit()
                    }
                )
            );
            */
           
            helper.updateLead(component, event);
        } else {
            
        }
        
    },

    /** [2] JPS 31 May 2025 - Add new function for Accept T&Cs to enable Place Order button */
    /** [3] CL 6 Jun 2025 - Fix mobile TC Button */
    /** [4] CL 9 Jun 2025 - Capture T&C and Marketing Fields */
    termsConditionsAccepted : function(component, event, helper) {
        helper.updateLeadTC(component,event);
       
    },
    /** [2] JPS 31 May 2025 - Add new function for Accept T&Cs to enable Place Order button */
    
    checkConfirmedDetails: function (component, event, helper) {
        var allValid = component.find('personDetailField').reduce(function (validSoFar, inputCmp) {
            inputCmp.reportValidity();
            component.set('v.confirmedDetails', false);
            return validSoFar && inputCmp.checkValidity();
        }, true);
        
        if (allValid) {
           // component.set('v.confirmedDetails', true);
           
            
        } else {
            component.set('v.confirmedDetails', false);
        }
        
    },
    
    
    selectAllTerms: function (component, event, helper) {
        helper.toggleCheckboxes(component, event);
    },
    /*
    checkTCs: function (component, event, helper) {
        helper.isTCsAccepted(component, event);
    },
    */
    
    mobileCheckTC1: function (component, event, helper) {
        var tc = component.get('v.tc');
        if(tc.tc1){
            tc.tc1 = false;
        }else{
            tc.tc1 = true;
        }
        
        component.set('v.tc', tc);
        helper.isTCsAccepted(component, event);
        
    },
    
    mobileCheckTC2: function (component, event, helper) {
        var tc = component.get('v.tc');
        if(tc.tc2){
            tc.tc2 = false;
        }else{
            tc.tc2 = true;
        }
        component.set('v.tc', tc);
        helper.isTCsAccepted(component, event);
        
    },
    
    mobileCheckTC3: function (component, event, helper) {
        var tc = component.get('v.tc');
        if(tc.tc3){
            tc.tc3 = false;
        }else{
            tc.tc3 = true;
        }
        component.set('v.tc', tc);
        helper.isTCsAccepted(component, event);
        
    },
    
    mobileCheckTC4: function (component, event, helper) {
        var tc = component.get('v.tc');
        if(tc.tc4){
            tc.tc4 = false;
        }else{
            tc.tc4 = true;
        }
        component.set('v.tc', tc);
        helper.isTCsAccepted(component, event);
        
    },
    
    /*
    mobileCheckTC5: function (component, event, helper) {
        var tc = component.get('v.tc');
        if(tc.tc5){
            tc.tc5 = false;
        }else{
            tc.tc5 = true;
        }
        component.set('v.tc', tc);
        helper.isTCsAccepted(component, event);
        
    },
    */
    
    
    navigateToPlans : function (component, event) {
        const searchParams = new URLSearchParams(window.location.search);
        const enquiry = searchParams.get('enquiry');
        var urlEvent = $A.get("e.force:navigateToURL");
        var url = '/giga/s/our-plans?enquiry=' + enquiry;
        
  
        urlEvent.setParams({
            "url": url
        });
        urlEvent.fire();
     
    },    
    
	checkPromoCode : function (component, event, helper) {
        //helper.updateLead(component, event);
        helper.applyPromoCode(component, event);
    },       
    
    removePromoCode : function (component, event, helper) {
     	
        helper.deleteVouchers(component, event);
    },
    
    
})