/*
[3] CL 9 Captures IP Address
*/
({
    
    doInit : function(component, event, helper) {
        helper.getIpAddress(component, event); 
        helper.getStates(component, event);        
        
    },
    
    
    save : function(component, event, helper) {
        
        helper.createLead(component, event);        
        
    },
    
    
    checkTC : function(component, event, helper) {
        var tc = component.get('v.tc');
        if(tc == null){
            tc = new Object();
        }
        
        if(tc.tc1){
            tc.tc1 = false;
        }else{
            tc.tc1 = true;
        }
        
        component.set('v.tc', tc);
    },
    
    checkTC2 : function(component, event, helper) {
        var tc = component.get('v.tc');
        if(tc == null){
            tc = new Object();
        }
        if(tc.tc2){
            tc.tc2 = false;
        }else{
            tc.tc2 = true;
        }
        component.set('v.tc', tc);
    },
    next : function(component, event, helper) {
        var inputSelect = component.find("stateField");
        var btnVal = event.currentTarget.value;
        console.log(btnVal)
        
    
   

        if(btnVal == 'pd'){
            
            component.set('v.showReview', false);
            component.set('v.showPersonalDetails', true);
            component.set('v.showAgreement', false);
            
        }else if(btnVal == 'rv'){
            
            var allValid = component.find('addressField').reduce(function (validSoFar, inputCmp) {
                inputCmp.reportValidity();
                inputSelect.showHelpMessageIfInvalid(); 
                
                return validSoFar && inputCmp.checkValidity();
            }, true);
            
            if (allValid) {
                
                if(inputSelect.get("v.validity").valid){
                

                    component.set('v.showReview', true);
                    component.set('v.showPersonalDetails', false);
                    component.set('v.showAgreement', false);
                    
                }else{
                    inputSelect.showHelpMessageIfInvalid(); 
                }
          
                
            }
        }else if(btnVal == 'rvv'){
            component.set('v.showReview', true);
            component.set('v.showPersonalDetails', false);
            component.set('v.showAgreement', false);
            
        }else if(btnVal == 'at'){
            component.set('v.showReview', false);
            component.set('v.showPersonalDetails', false);
            component.set('v.showAgreement', true);
        }
        
     
        
        
        
	}
})