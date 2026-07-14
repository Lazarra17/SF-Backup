({
     doInit : function(component, event, helper) {
        helper.getIpAddress(component, event); 
       
       
    },
    validateForm : function(component, event, helper) {
        var allValid = component.find('addressField').reduce(function (validSoFar, inputCmp) {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        
        if (allValid) {
            console.log('valid');
           helper.createLead(component, event);
           
        } else {
            
        }
    }
})