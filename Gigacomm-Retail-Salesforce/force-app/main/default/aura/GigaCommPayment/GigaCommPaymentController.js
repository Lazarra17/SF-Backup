({
    doInit : function(component, event, helper) {
        helper.getEziDebit(component, event);
    },
    
    navigateToPersonPage : function (component, event) {
        const searchParams = new URLSearchParams(window.location.search);
        const enquiry = searchParams.get('enquiry');
        var urlEvent = $A.get("e.force:navigateToURL");
        var url = '/giga/s/personal-details?enquiry=' + enquiry;
        
        urlEvent.setParams({
            "url": url
        });
        urlEvent.fire();
    },
})