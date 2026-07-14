({
    loadAddressFinder: function(component, fieldId, isAddress) {
        
   
        var script = document.createElement('script');
        script.src = 'https://api.addressfinder.io/assets/v3/widget.js';
        script.async = true;
        //FIRES whenever user search for an address
        script.onload = function() {
            var widget = new AddressFinder.Widget(
                document.getElementById(fieldId),
                'AGQFDVJXY4LRB3ECPTH6',
                'AU',
                isAddress ? {
                    "address_params": {
                        "au_gnaf": "1",
                        "post_box": "0"
                    },
                    
                    "empty_content": "No addresses were found. This could be a new address, or you may need to check the spelling."
                } : {
                    "show_addresses": false,
                    "show_locations": true,
                    "location_params": {
                        "location_types": "locality, state"
                    },
                    "empty_content": "No addresses were found. This could be a new address, or you may need to check the spelling. Learn more"
                }
            );
            
            widget.on(isAddress ? 'address:select' : 'location:select', function(fullData, metaData) {
                if (isAddress) {
                    
                    
                    const searchParams = new URLSearchParams(window.location.search);
                    const kiosk = searchParams.get('kiosk');
                    const agentCode = searchParams.get('agentCode');
                    
                    
                    
                    let addressLine1 = metaData.address_line_combined;
                    let completeAddress =  metaData.full_address;
                    
                    /* removed due to incompatilibity with native JS
                    component.set('v.addrs', completeAddress);
                    component.set('v.street', addressLine1);
                    component.set('v.suburb', metaData.locality_name);
                    component.set('v.state', metaData.state_territory);
                    component.set('v.postCode', metaData.postcode);
                 	component.set('v.isAddressValid', TRUE);
                    */
                    
                    //Event Fire to capture the lead in main component
                    var cmpEvent = component.getEvent("cmpEvent");
                    var payload = document.getElementById("payload").value;
                    if(payload != ''){
                        payload = JSON.parse(payload); 
                    }else{
                        payload =  new Object();
                    }
                    
                   
                    
                    
                    payload.Address = completeAddress;
                    payload.AddressFinderId = metaData.id;
                    payload.Street = addressLine1;
                    payload.StreetName = metaData.street_name;
                    payload.StreetNr = metaData.street_number_1;
                    payload.StreetNrSuffix = metaData.street_number_2;
                    payload.StreetType = metaData.street_type;
                    
                    
                    payload.UnitNumber = metaData.unit_identifier;
                    payload.UnitType = metaData.unit_type;
                    payload.LevelNumber = metaData.level_number;
                    payload.LevelType = metaData.level_type;
                    
                    payload.AddressLine1 = metaData.address_line_1;
                    payload.AddressLine2 = metaData.address_line_2;
                    
                    
                    payload.Suburb = metaData.locality_name;
                    payload.State = metaData.state_territory;
                    payload.PostCode = metaData.postcode;
                    payload.SA2_Id = metaData.sa2_id;
                    payload.GNAF_Id = metaData.gnaf_id;
                    payload.Country = 'Australia';
                    payload.CountryCode = 'AU';
                    payload.Status = 'Address Check'; 
                    payload.Kiosk = kiosk;
                    payload.AgentCode = agentCode;
                    
                    // Correct way to dispatch a standard DOM event in Aura
                   
                    var trafficObj = { /* ... your extracted object ... */ };
                    
                    var getCookieEvent = new CustomEvent("getCookies", {
                        bubbles: true,
                        composed: true,
                        detail: { value: trafficObj }
                    });
                    
                    // Use window or a specific element to dispatch in Aura
                    window.dispatchEvent(getCookieEvent);
                    
                    
                    if(getCookieEvent != null){
                        const cookieString = decodeURIComponent(JSON.stringify(getCookieEvent));
                        console.log('Cookie String: ' + getCookieEvent);
                        const match = cookieString.match(/gc_gtm_utm_session_data=({.*?})(?:;|$)/);
                        
                        if (match && match[1]) {
                            // 2. Parse the captured JSON string into an object
                            const sessionData = JSON.parse(match[1]);
                            
                            // 3. Return only the gtm_marketing_traffic object
                            const gtmObj = sessionData.gtm_marketing_traffic;
                            payload.UTMSource = gtmObj.source;    
                            payload.UTMMedium = gtmObj.medium; 
                            payload.UTMCampaign = gtmObj.campaign; 
                            payload.UTMTerm = gtmObj.term; 
                            payload.UTMContent = gtmObj.content; 
                            
                            
                        }
                        
                    }
                    
                   
   
                    
                    let dml = '';
                    if(payload.Id != null){
                        dml = 'UPDATE';
                        payload.RefreshPlans = true;
                        
                    }else{
                        payload.Term = 'Monthly';
                        dml = 'INSERT';
                    }
                    //Assign payload to input field
                    //GigaCommOrderWizard is the Parent
                    cmpEvent.setParams({
                        "payload" : payload,
                        "dml" : dml,
                    	"addressCheck" : true
                    });
                    
                    cmpEvent.fire();
 					//console.log('Address Event');                    
                } else {
                    document.getElementById('suburb').value = metaData.locality_name;
                    document.getElementById('state').value = metaData.state_territory;
                    document.getElementById('postCode').value = metaData.postcode;
                }
                
                
            });
            
            
        };
        document.body.appendChild(script);
        
    },
    
    capitalizeFirstLetter: function(val) {
        return val.replace(/(^\w)|([-\s]\w)/g, match => match.toUpperCase());
    },
    
    navigateTo : function (component, event, res) {
        var urlEvent = $A.get("e.force:navigateToURL");
        var url = '/giga/s/our-plans?';
        var scrollTo = '';
        var device = $A.get("$Browser.formFactor");
        if (device == 'PHONE') {
            scrollTo = 'planSectionMobile';
        } else if (device == 'TABLET') {
            scrollTo = 'planSection';
        } else {
            // Code to execute if it's not a phone or tablet
            scrollTo = 'planSection';
        }
        
        
        if(res != null){
            url = url + 'enquiry=' + res.Id + '&#' + scrollTo;
        }
        
        urlEvent.setParams({
            "url": url
        });
        urlEvent.fire();
    },
    
    
    getStates: function(component, event) {
        let states = [{'label': 'Select state', 'value': ''},
                      {'label': 'New South Wales', 'value': 'New South Wales'},
                      {'label': 'Victoria', 'value': 'Victoria'},
                      {'label': 'Queensland', 'value': 'Queensland'},
                      {'label': 'South Australia', 'value': 'South Australia'},
                      {'label': 'Western Australia', 'value': 'Western Australia'},
                      {'label': 'Tasmania', 'value': 'Tasmania'},
                      {'label': 'Northern Territory', 'value': 'Northern Territory'},
                      {'label': 'Australian Capital Territory', 'value': 'Australian Capital Territory'},];
                      
                      component.set('v.stateOptions', states);
                      
                      },
                      
                      getStreetTypes: function(component, event) {
                      var action = component.get("c.getPicklistValues");
                      
                      
                      action.setParams({  
                      'objObject' : 'Lead',
                      'fld' : 'Street_Type_bric__c',
                      'selected_string' : ''
                      });    
                      
                      action.setCallback(this, function(response) {            
                      
                      var state = response.getState();   
                      if (state == "SUCCESS") {   
                      var res = response.getReturnValue();  
                      component.set('v.streetTypeOptions', res);
                      } else if (state == "INCOMPLETE") {
                      console.log("No response from server or client is offline.")
                      // Show offline error
                      }else if (state == "ERROR") {
                      console.log('ERROR');
                      console.log(response);
                      var errors = response.getError();  
                      console.log("Error: " + errors[0].message);
        // Show error message
    }        
});               

$A.enqueueAction(action);    
},
    
    
})