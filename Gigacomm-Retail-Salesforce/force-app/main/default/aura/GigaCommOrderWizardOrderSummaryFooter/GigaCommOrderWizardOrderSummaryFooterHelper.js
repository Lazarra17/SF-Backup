/**
 * @description Helper JS for GigaCommOrderWizardOrderSummaryFooter cmp
 * @author Bricoleur Technologies
 * [1] JPS 31 May - Update pushToGTM code structure
 */
({
	 //Method for Google Tag Manager
    pushToGTM : function (response) {
        
        var hasRouter;
        if(response.Router != null){
            hasRouter = true;
        }else{
            hasRouter = false;
        }
        
        var detail = new Object();
        var voucher = this.getCookie('voucher');
        
        detail.event = 'checkout_plans_addons';
        detail.lead_id = response.Id;
        detail.state = response.State;
        detail.postcode = response.PostCode;
        detail.plan_id = response.PlanSelected.Product_bric__r.ProductCode;
        detail.plan_length = response.Term;
        detail.plan_type = response.PlanSelected.Product_bric__r.Download_Upload_Limit_bric__c;
        detail.hardware_include = hasRouter;
        detail.coupon = voucher;
        
        
        if(detail != null){
            var event = new CustomEvent("datalayerpush", {
                detail,
                bubbles: true,
                composed: true // optional in Aura, but safe to include
            });
            document.dispatchEvent(event);
    
        }
        /** [1] JPS 31 May - Update pushToGTM code structure */      
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