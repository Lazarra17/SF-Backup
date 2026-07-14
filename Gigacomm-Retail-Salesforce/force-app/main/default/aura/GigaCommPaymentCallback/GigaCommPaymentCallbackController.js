({
    doInit : function(component, event, helper) {
        const searchParams = new URLSearchParams(window.location.href);
        const uref = searchParams.get('uref');
        const cref = searchParams.get('cref');
        var urlEvent = $A.get("e.force:navigateToURL");
        var url = '/giga/s/payment-in-process?&sf=&uref=' + uref + '&cref=' + cref;
        
        window.open(url, '_parent');
        /*
        urlEvent.setParams({
            "url": url
        });
        urlEvent.fire();
        */
    }
})