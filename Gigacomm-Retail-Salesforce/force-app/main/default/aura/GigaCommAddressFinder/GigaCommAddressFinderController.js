({
	doInit : function(component, event, helper) {
        
        var urlPath = window.location.pathname;
        component.set('v.urlPath', urlPath);
        //console.log('urlPath: ' + urlPath );
        if(urlPath != null){
            
        }
        
        helper.getStates(component, event);
        helper.getStreetTypes(component, event);
        helper.loadAddressFinder(component, 'addrs', true);
        helper.loadAddressFinder(component, 'addrs2', true);
        helper.loadAddressFinder(component, 'addrs3', true);
        helper.loadAddressFinder(component, 'addrs4', true);
        //helper.checkEnquiry(component, event);
    },
    
    
    seePlan : function(component, event, helper) {
        var lead = component.get('v.lead');
        
        if(lead != null){
            if(lead.Id == null){
                helper.navigateTo(component, event, lead);
            }else if(lead.Id != null){
                helper.navigateTo(component, event, lead);
            }
            
        }else{
            helper.navigateTo(component, event, null);
          
        }
        
    },
    
    //Removed the check icon if the address is not coming from the Address Finder
    isAddressChanged : function(component, event, helper) {
        //var addrs = document.getElementById('addrs').value;
        document.getElementById('GcCheckCircle').classList.add("slds-hidden")
        document.getElementById('isAddressValid').checked = false;
    },
    
    
    
    deleteAddress : function(component, event, helper) {
        
        document.getElementById("addrs").value = "";
        /*
        var cmpEvent = component.getEvent("cmpEvent");
        document.getElementById("gcIconCross").style.display = "none";
        
        var payload = document.getElementById("payload").value;
        if(payload != ''){
            payload = JSON.parse(payload); 
        }else{
            payload =  new Object();
        }
        cmpEvent.setParams({
            "payload" : payload,
            "hideWizard" : true
        });
        
        cmpEvent.fire();
        */
        
    }
    
    

    
})