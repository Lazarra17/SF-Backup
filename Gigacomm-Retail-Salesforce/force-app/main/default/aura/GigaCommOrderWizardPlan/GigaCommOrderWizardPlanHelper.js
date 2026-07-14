/*
[1] CL 05-Jun-2025 Fixed the Bug on the Installation Free

*/
({
    upsertLead: function(component, event) {
        var btnVal = event.currentTarget.value.split(':');
        var dml = '';
        var cmpEvent = component.getEvent("cmpEvent");
        var selectedPlan = btnVal[0];
        var term = btnVal[1];
        var priceBookEntry = btnVal[2]; 
        //var payload = document.getElementById('payload').value;
        var payload = component.get('v.lead');
        //console.log('paylaod');
        if(payload != null){
            if(payload.Id != null){
                dml = 'UPDATE';
            }else{
                dml = 'INSERT';
            }
            
        }else{
            dml = 'INSERT';
            payload = new Object();
        }


        payload.PlanSelected = new Object();
        payload.PlanSelected.Id = priceBookEntry;
        payload.PlanSelected.TECH_PriceBookEntryId_bric__c = priceBookEntry;
        payload.PlanSelected.Product_bric__c = selectedPlan;
        payload.PlanSelected.Quantity_bric__c = 1;
        payload.Status = 'Plan Selected';
        payload.Term = term;
        
        if(this.getCookie('voucher') != null){
        payload.PromoCodeReferral = this.getCookie('voucher') ;
        }
        
        //console.log('PAYLOaD: ' + dml);
        //console.log('TERM'  + payload.Term);
        cmpEvent.setParams({
            "payload" : payload,
            "dml" : dml,	
        });
        
         //console.log('PAYLOaD: FIRE');
        cmpEvent.fire();
        
        console.log('ORDER PLAN: event fired from PLan');
                

        
        
        
    },
    setPaymentTerm : function(component, event) {
		var payload = component.get('v.lead');
        var cmpEvent = component.getEvent("cmpEvent");
        var selectedTab = event.target.id;
		var term = '';
        var dml = '';
        
        if(selectedTab == 'pills-home-tab') {
            component.set("v.selectedTerm", 'Monthly');
            component.set("v.selectedTermNum", 1);
            term = 'Monthly';
        }
        else if(selectedTab == 'pills-profile-tab') {
            component.set("v.selectedTerm", '12 Months');
            component.set("v.selectedTermNum", 12);
            term = '12 Months';
        }
        else if(selectedTab == 'pills-contact-tab') {
            component.set("v.selectedTerm", '24 Months');
            component.set("v.selectedTermNum", 24);
            term = '24 Months';
        } 
        
        
        if(payload != ''){
            if(payload.Id != null){
                dml = 'UPDATE';
            }
            
        }else{
            payload = new Object();
        }
        
        
        payload.Term = term;
        payload.Status = 'Plan Selected';
        cmpEvent.setParams({
            "payload" : payload,
            "dml" : dml,	
        });
        cmpEvent.fire();
        
        
    },
    
    getCookie : function(queryParam) {
        
        let name = queryParam + "=";
        let decodedCookie = decodeURIComponent(document.cookie);
        let ca = decodedCookie.split(';');
        for(let i = 0; i <ca.length; i++) {
            let c = ca[i];
            while (c.charAt(0) == ' ') {
                c = c.substring(1);
            }
            if (c.indexOf(name) == 0) {
                return c.substring(name.length, c.length);
            }
        }
        return "";
    },
})