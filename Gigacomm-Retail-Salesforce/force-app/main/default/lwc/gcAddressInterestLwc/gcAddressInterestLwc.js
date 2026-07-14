import { LightningElement, api, track } from 'lwc';
import createLead from '@salesforce/apex/GigaCommAddressInterestController.createLead';

export default class GigaCommAddressInterestLwc extends LightningElement {
    @api lead = {};
    @track showThankYou = false;
    @track error = '';

    connectedCallback() {
        // Initialize lead properties if not already set, to avoid issues with two-way binding
        this.lead = {
            FirstName: this.lead.FirstName || '',
            LastName: this.lead.LastName || '',
            Email: this.lead.Email || '',
            Address: this.lead.Address || '',
            ...this.lead // Preserve any other existing lead properties
        };
    }

    handleInputChange(event) {
        const { name, value } = event.target;
        this.lead = { ...this.lead, [name]: value };
    }

    async handleSignUp() {
        this.error = '';
        // Basic validation
        const allValid = [...this.template.querySelectorAll('lightning-input')].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

        if (allValid) {
            try {
                // Ensure the address from the main component is passed to the lead object
                const payload = { ...this.lead };
                // If lead.Address is empty, use the address from the parent component if available (assuming it's passed as a property)
                if (!payload.Address) {
                     // This part needs to be handled by the parent component passing the address down
                    // For now, we'll assume the address property is set directly on the lead object
                }
                
                const result = await createLead({ siteLead: JSON.stringify(payload) });
                if (result) {
                    this.pushToGTM(result);
                    this.closeModal(true); // Pass true to indicate successful signup
                } else {
                    this.error = 'Failed to create lead. Please try again.';
                }
            } catch (error) {
                this.error = error.body ? error.body.message : 'An unexpected error occurred.';
                // eslint-disable-next-line no-console
                console.error('Error signing up:', error);
            }
        }
    }

    closeModal(showThankYou = false) {
        console.log('gigaCommAddressInterestLwc: closeModal called with showThankYou:', showThankYou);
        this.dispatchEvent(new CustomEvent('closeinterestmodal', { detail: { showThankYou: showThankYou } }));
    }

    // New method to handle 'X' button click and ensure no args are passed to closeModal
    handleCloseButtonClick() {
        this.closeModal();
    }

    //Method for Google Tag Manager
    pushToGTM(response) {
        let serviceable = '';
   

        if(this.serviceable){
            serviceable = 'eligible';
        }else{
            serviceable = 'ineligible';
        }
            console.log('CONSOLE');
            console.log(response);
            document.dispatchEvent(new CustomEvent(
                'eventGTM', { 
                'detail' : {
                    'event': 'generate_lead',
                    'lead_id': response.Id,
                    'lead_source': 'form_unserviceable_area',   
                    'state': response.StateCode,
                    'postcode': response.PostalCode,
                    'coupon' : this.getCookie('voucher') != null ? this.getCookie('voucher') : '' 
                    } 
                }
                ));


        
    }

    getCookie(name) {
        const cookies = decodeURIComponent(document.cookie).split(';');
        for (let c of cookies) {
            c = c.trim();
            if (c.startsWith(name + '=')) return c.substring(name.length + 1);
        }
        return '';
    }
}