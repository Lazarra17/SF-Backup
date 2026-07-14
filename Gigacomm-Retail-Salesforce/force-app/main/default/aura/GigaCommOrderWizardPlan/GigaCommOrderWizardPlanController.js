({
    
    selectPlan : function(component, event, helper) {
        helper.upsertLead(component, event);
    }, 
    
    
    
    navigateTo : function (component, event) {
        const searchParams = new URLSearchParams(window.location.search);
        
        var urlEvent = $A.get("e.force:navigateToURL");
        var url = '/our-plans?';
        
        var utm_source = searchParams.get('utm_source');
        var utm_medium = searchParams.get('utm_medium');
        var utm_campaign = searchParams.get('utm_campaign');
        var utm_term = searchParams.get('utm_term');
        var utm_content = searchParams.get('utm_content'); 
        
        
        if(utm_source != null){
            url = url +  'utm_source=' + utm_source + '&';
        }
        
        if(utm_medium != null){
            url = url +  'utm_medium=' + utm_medium + '&';
        }
        
        if(utm_campaign != null){
            url = url +  'utm_campaign=' + utm_campaign + '&';
        }
        
        if(utm_term != null){ 
            url = url +  'utm_term=' + utm_term + '&';
        }
        
        if(utm_content != null){
            url = url +  'utm_content=' + utm_content + '&';
        }
        
        
        urlEvent.setParams({
            "url": url
        });
        urlEvent.fire();
    },
    
    
    termClick : function(component, event, helper) {
        helper.setPaymentTerm(component, event);
    }
})