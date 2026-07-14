({

    toggleCheckboxes: function (component, event) {
        
        var checkbox = event.currentTarget.checked;
        
        if (checkbox) {
            var isChecked = checkbox.checked;
            document.getElementById("checkbox-1").checked = true;
            document.getElementById("checkbox-2").checked = true;
            document.getElementById("checkbox-3").checked = true;
			document.getElementById("checkbox-4").checked = true;
			document.getElementById("checkbox-5").checked = true;
            document.getElementById("checkbox-6").checked = true;
			document.getElementById("checkbox-7").checked = true;
            
            component.set('v.acceptedTC', true);
        }else{
            component.set('v.acceptedTC', false);
            document.getElementById("checkbox-1").checked = false;
            document.getElementById("checkbox-2").checked = false;
            document.getElementById("checkbox-3").checked = false;
			document.getElementById("checkbox-4").checked = false;
			document.getElementById("checkbox-5").checked = false;
            document.getElementById("checkbox-6").checked = false;
			document.getElementById("checkbox-7").checked = false;
        }
    },
    
    
    isTCsAccepted: function (component, event) {
        
        var tc1 = document.getElementById("checkbox-1").checked;
        var tc2 = document.getElementById("checkbox-2").checked;
        var tc3 = document.getElementById("checkbox-3").checked;
        var tc4 = document.getElementById("checkbox-4").checked;
        var tc5 = document.getElementById("checkbox-5").checked;
        var tc6 = document.getElementById("checkbox-6").checked;
        var tc7 = document.getElementById("checkbox-7").checked;
        
        if(tc1 && tc2 && tc3 && tc4 && tc5 && tc6 && tc7){
            component.set('v.acceptedTC', true);
        }else{
            component.set('v.acceptedTC', false);
        }

        
    },
    
                    
    termsAccepted : function(component, event) {

        let allTermsAccepted = true;

        for(let i = 0; i < 7; i++) {
            if(document.getElementById("checkbox-" + (i+1)).checked == false) {
                allTermsAccepted = false;
                break;
            }
        }

        return allTermsAccepted;
    },
    
    
    updateLead: function(component, event) {
        var dml = '';
        var cmpEvent = component.getEvent("cmpEvent");
        var payload = component.get('v.lead');
        
        dml = 'UPDATE';
        cmpEvent.setParams({
            "payload" : payload,
            "dml" : dml,	
        });
        cmpEvent.fire();
        
        console.log('EVENT FIRED');
        
       
       
    },
    
    navigateToPayment : function (component, event) {
        const searchParams = new URLSearchParams(window.location.search);
        const enquiry = searchParams.get('enquiry');
        var urlEvent = $A.get("e.force:navigateToURL");
        var url = '/giga/s/payment?enquiry=' + enquiry;
        
        urlEvent.setParams({
            "url": url
        });
        urlEvent.fire();
    },
    
})