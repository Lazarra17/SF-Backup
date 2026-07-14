({
    
    doInit : function(component, event, helper) {
        helper.getIpAddress(component, event); 
       
       
    },
    
    handleComponentEvent : function(component, event, helper) {
        
        var payload = event.getParam("payload");
        var dml = event.getParam("dml");
        console.log(payload);
        console.log(dml);
        
        if(dml == 'INSERT'){
            helper.createLead(component,event, payload);
            document.getElementById('payload').value = JSON.stringify(payload);
        }
     
        
        
    },
})