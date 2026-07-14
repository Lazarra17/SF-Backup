({
    navigateToHome : function (component, event, helper) {
        /*var urlEvent = $A.get("e.force:navigateToURL");
        var url = '/../../';
      
        urlEvent.setParams({
            "url": url
        });
        urlEvent.fire();
        */
        window.open('/', '_self');
        
    },
    
    
     navigateToPersonPage : function (component, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        var url = '/giga/s/personal-details?enquiry=';
        var lead = component.get('v.lead');
         
        helper.pushToGTM(lead);
        if(lead != null){
            url = url + lead.Id;
        }
        urlEvent.setParams({
            "url": url 
        });
        urlEvent.fire();
    },
    
   
    
})