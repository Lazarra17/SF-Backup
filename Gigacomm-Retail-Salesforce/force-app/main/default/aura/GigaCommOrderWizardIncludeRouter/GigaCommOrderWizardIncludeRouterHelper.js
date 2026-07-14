({
    upsertLead: function(component, event, qty) {
        
        var dml = '';
        var cmpEvent = component.getEvent("cmpEvent");
        //var payload = component.get('v.lead');
        var router = component.get('v.router');
        var lead = component.get('v.lead');
        var payload = new Object();
        if(lead != ''){
            if(lead.Id != null){
                dml = 'UPDATE';
                payload.Id = lead.Id;
            }
            
        }
        payload.PlanSelected = lead.PlanSelected;
        payload.Router = new Object();
        payload.Router.Id = router.Id;
        payload.Router.TECH_PriceBookEntryId_bric__c = router.Id;
        payload.Router.Product_bric__c = router.Product2Id;
        payload.Router.Quantity_bric__c = qty;
        payload.Router.Unit_Price_bric__c = router.UnitPrice;
        payload.AgentPriceOverride = lead.AgentPriceOverride;
        payload.TotalRouterQuantity = qty;
        payload.Status = 'Router Added';
        payload.IncludeRouter = true;
        
        
        if(lead.RouterPromo != null){
            payload.RouterPromo = lead.RouterPromo;
           	 
        }
        
        cmpEvent.setParams({
            "payload" : payload,
            "dml" : dml,	
        });
        cmpEvent.fire();
        
     
                
     
        
        
        
    }, 
    
    updateFreeRouter: function(component, event) {
        
        var dml = '';
        var cmpEvent = component.getEvent("cmpEvent");
        var lead = component.get('v.lead');
        var payload = new Object();
        
        if(lead.Router != null){
            
            dml = 'UPDATE';
            payload.Id = lead.Id;
            payload.Router = lead.Router;
            payload.AgentPriceOverride = lead.AgentPriceOverride;
            payload.Status = 'Router Added';
            payload.PlanSelected = lead.PlanSelected;
            payload.IncludeRouter = true;
            cmpEvent.setParams({
                "payload" : payload,
                "dml" : dml,	
            });
            cmpEvent.fire();
            
        }     
        
        
        
        
    }, 
    
    includeRouter: function(component, event) {
        var dml = '';
        var cmpEvent = component.getEvent("cmpEvent");
        var lead = component.get('v.lead');
        var router = component.get('v.router');
        var payload = new Object();
        
        if(lead != ''){
            if(lead.Id != null){
                dml = 'UPDATE';
                payload.Id = lead.Id;
            }
            
        }
        payload.Term = lead.Term;
        payload.IncludeRouter = true;
        payload.PlanSelected = lead.PlanSelected;
        payload.Router = new Object();
        payload.Router.Id = router.Id;
        payload.Router.TECH_PriceBookEntryId_bric__c = router.Id;
        payload.Router.Product_bric__c = router.Product2Id;
        payload.Router.Quantity_bric__c = 1;
        payload.Router.Unit_Price_bric__c = router.UnitPrice;
        payload.AgentPriceOverride = lead.AgentPriceOverride;
        payload.TotalRouterQuantity = 1;
        payload.Status = 'Plan Selected';
     
        cmpEvent.setParams({
            "payload" : payload,
            "dml" : dml,	
        });
        cmpEvent.fire();
        
    },
    
    
    
    removeRouter: function(component, event) {
        var dml = '';
        var cmpEvent = component.getEvent("cmpEvent");
        var router = component.get('v.router');
        var lead = component.get('v.lead');
        var payload = new Object();
        
        if(lead != ''){
            if(lead.Id != null){
                dml = 'DELETE';
                payload.Id = lead.Id;
            }
            
        }
        payload.IncludeRouter = false;
        if(lead.Router != null){
            payload.ItemToDelete = lead.Router.Id;
            payload.Router = new Object();
            payload.Router.Id = lead.Router.Id;
            payload.Router.Lead_bric__c = lead.Router.Lead_bric__c;
            
          
        }
        cmpEvent.setParams({
            "payload" : payload,
            "dml" : dml,	
        });
        cmpEvent.fire();
        
    },
    
    toggleEvent : function(component, event) {
        
        var routerBool;
        var routerEvent = $A.get("e.c:GigaCommOrderWizardEvent");
        var routerToggle = event.target.id;
        
        if(routerToggle == 'pills-home-tab'){
            routerBool = true;
        }
        else if(routerToggle == 'pills-profile-tab') {
            routerBool = false;
        }

        routerEvent.setParams(
            {routerToggle: routerBool}
        );
        routerEvent.fire();
    },

})