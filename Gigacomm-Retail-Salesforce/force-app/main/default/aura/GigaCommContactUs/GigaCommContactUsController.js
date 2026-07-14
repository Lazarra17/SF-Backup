({
    doInit : function(component, event, helper) {
        helper.getIpAddress(component, event); 
        
        
    },
    checkTC : function(component, event, helper) {
        var tc = component.get('v.tc');
        if(tc){
            tc = false;
        }else{
            tc = true;
        }
        
        component.set('v.tc', tc);
        
    },
    
    validateForm : function(component, event, helper) {
        var inputSelect = component.find("stateField");
        var allValid = component.find('addressField').reduce(function (validSoFar, inputCmp) {
            inputCmp.reportValidity();
            inputSelect.showHelpMessageIfInvalid(); 
            
            return validSoFar && inputCmp.checkValidity();
        }, true);
        
        if (allValid) {
            
            if(inputSelect.get("v.validity").valid){
                
                helper.createLead(component, event);
                
            }else{
                inputSelect.showHelpMessageIfInvalid(); 
            }
            
        }
        
    }
    
    
})