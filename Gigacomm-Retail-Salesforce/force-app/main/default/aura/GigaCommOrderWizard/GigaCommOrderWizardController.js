({
    doInit : function(component, event, helper) {
        helper.cookiePromoCode(component, event);
        helper.getIpAddress(component, event); 
        helper.getPlans(component, event);
        helper.getLead(component, event);
        helper.getRouter(component, event);
        var voucher = helper.getCookie('voucher');
        
        if(voucher != '' || voucher != null){
            component.set('v.promoCodeReferral', voucher);
        }
       
    },
    
    handleComponentEvent : function(component, event, helper) {
        document.getElementById("gcIconCross").style.display = "none";
        component.set('v.showLoading', true);
        component.set('v.showSpinner', true);
        var payload = event.getParam("payload");
        var dml = event.getParam("dml");
        //console.log('dml: ' + dml);
        var apiHasError = event.getParam("apiHasError"); //This is to reset the Modal UnServiceable
        if(apiHasError != null){
            component.set('v.apiHasError', apiHasError);
            component.set('v.showSpinner', false);
            return;
        }
        
        var voucher = component.get('v.promoCodeReferral');
        if(voucher != '' || voucher != null){
            payload.PromoCodeReferral = voucher;
        }
        
        payload.Serviceable = null;
        
        document.getElementById('payload').value = JSON.stringify(payload);
        if(dml == 'INSERT'){
            helper.createLead(component,event, payload);
        }else if(dml == 'UPDATE'){
            helper.updateLead(component, payload);
        }else if(dml == 'DELETE'){
            helper.removeItem(component, payload);
            component.set('v.showLoading', false);
            document.getElementById("gcIconCross").style.display = "block";
        }else{
            component.set('v.showSpinner', false);
            component.set('v.lead', payload);
        }
    },
    
        navigateTo : function (component, event) {
         window.open('/', '_self');
            
        },
    
})
