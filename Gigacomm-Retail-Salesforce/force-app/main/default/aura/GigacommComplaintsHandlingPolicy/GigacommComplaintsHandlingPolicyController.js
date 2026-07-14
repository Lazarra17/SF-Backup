({
    doInit : function(component, event, helper) {
        const searchParams = new URLSearchParams(window.location.search);
        const status = searchParams.get('status');
        console.log(searchParams);
        console.log(status);
        if(status == 'submitted'){
            component.set('v.isSubmitted', true);
        }
    }
})