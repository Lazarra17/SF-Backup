({
    
    doInit : function(component, event, helper) {
      
        window.open('/', '_self');
        
        helper.cookiePromoCode(component, event);
        helper.getIpAddress(component, event); 
		helper.getPlans(component, event);  
        helper.displayAddrThankyou(component, event); //JPS 20 May
        var voucher = helper.getCookie('voucher');
        if(voucher != '' || voucher != null){
            component.set('v.promoCodeReferral', voucher);
        }
    },
    
    navigateTo : function (component, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/our-plans"
        });
        urlEvent.fire();
    },

    
    
    handleComponentEvent : function(component, event, helper) {
        
      	component.set('v.showLoading', true);
        
        var payload = event.getParam("payload");
        var dml = event.getParam("dml");
        var hideWizard = event.getParam("hideWizard");
        var apiHasError = event.getParam("apiHasError"); //This is to reset the Modal UnServiceable
        if(apiHasError != null){
            component.set('v.apiHasError', apiHasError);
        }
        
        var voucher = component.get('v.promoCodeReferral');
        if(voucher != '' || voucher != null){
            payload.promoCodeReferral = voucher;
        }
        
        var registerAddressSubmitted = event.getParam("registerAddressSubmitted");
        if(registerAddressSubmitted != null){
            component.set('v.registerAddressSubmitted', registerAddressSubmitted);
        }
        
        if(dml == 'INSERT'){
            helper.createLead(component,event, payload);
            document.getElementById('payload').value = JSON.stringify(payload);
        }
        
        if(hideWizard){
            var lead = component.get('v.lead');
            lead.Address = null;
            component.set('v.lead', lead);
            component.set('v.hideWizard', hideWizard);
            component.set('v.showLoading', false);
        }
        
        
        
        
    },
    
    scrollToPlans : function (component,event, helper) {
        var target = component.find("planSection");
        var element = target.getElement();
        var rect = element.getBoundingClientRect();
        
        scrollTo({top: rect.top, behavior: "smooth"});
        
        
    },
    
    
})