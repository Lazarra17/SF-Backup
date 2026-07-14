({
	  navigateToPayment : function (component, event, helper) {
        const searchParams = new URLSearchParams(window.location.search);
        const enquiry = searchParams.get('enquiry');
        var urlEvent = $A.get("e.force:navigateToURL");
        var url = '/giga/s/payment?enquiry=' + enquiry;
        
        window.open(url, '_self');
        /*
        urlEvent.setParams({
            "url": url
        });
        urlEvent.fire();
        */
      },  
    
    
    doInit : function (component, event, helper) {
        window.setTimeout(
            $A.getCallback(function() {
                const searchParams = new URLSearchParams(window.location.search);
                const enquiry = searchParams.get('enquiry');
                var urlEvent = $A.get("e.force:navigateToURL");
                var url = '/giga/s/payment?enquiry=' + enquiry;
                
                window.open(url, '_self'); 
                
            }), 5000
        );
    },  
    
    
})