import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import createLead from '@salesforce/apex/GigaCommOrderWizardController.createLead';

const ADDRESSFINDER_URL = 'https://api.addressfinder.io/assets/v3/widget.js';
const ADDRESSFINDER_KEY = 'AGQFDVJXY4LRB3ECPTH6';
const ADDRESSFINDER_COUNTRY = 'AU';

export default class GigaCommAddressFinder extends NavigationMixin(LightningElement) {
    @api hideCantFindAddress = false;
    @track address = '';
    @track loading = false;
    @track showManualAddress = true;
    @track addressSelected = false;
    @track serviceable = false;
    @track validationErrorMessage = '';
    @track showServiceabilityErrorMessage = false;
    @track buttonLabel = 'Check Availability';
    @track showManualAddressModal = false;
    @track showRegisterModal = false;
    @track showThankYouModal = false;
    @track selectedLeadData = {};
    @track leadID;
    addressFinderLoaded = false;
    widget = null;
    selectedMetaData = null;

    @track ipAddress = '';
    @track voucher = '';
    @track kiosk = '';
    @track agentCode = '';
    @track utm = {};

    renderedCallback() {
        if (this.addressFinderLoaded) return;
        this.addressFinderLoaded = true;

        if (!window.AddressFinder) {
            const script = document.createElement('script');
            script.src = ADDRESSFINDER_URL;
            script.async = true;
            script.onload = () => this.initAddressFinder();
            document.body.appendChild(script);
        } else {
            this.initAddressFinder();
        }

        this.showManualAddress = !this.hideCantFindAddress;
        this.getIpAddress();
        this.setCookiePromoCode();
        this.voucher = this.getCookie('voucher');

        const params = new URLSearchParams(window.location.search);
        this.kiosk = params.get('kiosk');
        this.agentCode = params.get('agentCode');
        this.utm.source = params.get('utm_source');
        this.utm.medium = params.get('utm_medium');
        this.utm.campaign = params.get('utm_campaign');
        this.utm.term = params.get('utm_term');
        this.utm.content = params.get('utm_content');
    }

    initAddressFinder() {
        const inputs = this.template.querySelectorAll('input[type="search"]');
        if (!window.AddressFinder || this.widget) return;

        inputs.forEach((input) => {
            const widget = new window.AddressFinder.Widget(
                input,
                ADDRESSFINDER_KEY,
                ADDRESSFINDER_COUNTRY,
                {
                    address_params: { au_gnaf: '1', post_box: '0' },
                    empty_content: 'No addresses were found…'
                }
            );

            widget.on('address:select', (_full, meta) => this.handleAddressSelected(_full, meta));
        });
    }

    handleAddressInput(event) {
        this.address = event.target.value;
        this.addressSelected = false;
        this.selectedMetaData = null;
        this.validationErrorMessage = '';
        this.showServiceabilityErrorMessage = false;
        this.serviceable = false;
        this.buttonLabel = 'Check Availability';
    }

    async checkAvailabilityAfterAddressSelect() {
        this.hasPerformedCheck = true;
        this.validationErrorMessage = '';
        this.showServiceabilityErrorMessage = false;

        if (!this.addressSelected) {
            this.validationErrorMessage = 'Please validate your address to continue.';
            return;
        }

        this.loading = true;
        try {
            const result = await createLead({ siteLead: JSON.stringify(this.selectedMetaData) });
            this.loading = false;

            this.serviceable = result.Serviceable === true;
            this.leadID = result.Id;
            this.pushToGTM(result);
            if (this.serviceable) {
                this.navigateToPlans();
            } else {
                this.showServiceabilityErrorMessage = true;
                this.buttonLabel = 'Check Availability';
            }
        } catch (error) {
            this.loading = false;
            this.validationErrorMessage = error.body?.message ||
                'An error occurred while checking serviceability.';
            console.error(error);
        }
    }

    handleAddressSelected(_full, meta) {
        this.address = `${meta.address_line_1}, ${meta.locality_name}, ` +
            `${meta.state_territory} ${meta.postcode}`;
        this.addressSelected = true;

        this.selectedMetaData = {
            Address: this.address,
            AddressFinderId: meta.id,
            Street: meta.address_line_1,
            StreetName: meta.street_name,
            StreetNr: meta.street_number_1,
            StreetNrSuffix: meta.street_number_2,
            StreetType: meta.street_type,
            UnitNumber: meta.unit_identifier,
            UnitType: meta.unit_type,
            LevelNumber: meta.level_number,
            LevelType: meta.level_type,
            AddressLine1: meta.address_line_1,
            AddressLine2: meta.address_line_2,
            Suburb: meta.locality_name,
            State: meta.state_territory,
            PostCode: meta.postcode,
            SA2_Id: meta.sa2_id,
            GNAF_Id: meta.gnaf_id,
            Country: 'Australia',
            CountryCode: 'AU',
            Status: 'Address Check',
            Term: 'Monthly',
            Kiosk: this.kiosk,
            AgentCode: this.agentCode,
            IPAddress: this.ipAddress,
            PromoCodeReferral: this.voucher,
            UTMSource: this.utm.source,
            UTMMedium: this.utm.medium,
            UTMCampaign: this.utm.campaign,
            UTMTerm: this.utm.term,
            UTMContent: this.utm.content
        };

        this.checkAvailabilityAfterAddressSelect();
    }

    async handleFindAddressManually() {
        this.hasPerformedCheck = true;
        this.validationErrorMessage = '';
        this.showServiceabilityErrorMessage = false;
        this.serviceable = false;

        const fields = ['unitNumber', 'streetNumber', 'streetName', 'streetType', 'townSuburb', 'state', 'postCode'];
        const vals = {};
        fields.forEach(id => vals[id] = this.template.querySelector(`[data-id="${id}"]`)?.value || '');

        if (!vals.streetName || !vals.streetType || !vals.townSuburb || !vals.state || !vals.postCode) {
            this.validationErrorMessage = 'Please fill in all required manual address fields.';
            return;
        }

        this.loading = true;
        const addressLine1 = `${vals.streetNumber} ${vals.streetName} ${vals.streetType}`.trim();
        const fullAddress = `${addressLine1}, ${vals.townSuburb} ${vals.state} ${vals.postCode}`.trim();

        const siteLead = {
            Address: fullAddress,
            AddressFinderId: null,
            Street: addressLine1,
            StreetName: vals.streetName,
            StreetNr: vals.streetNumber,
            StreetNrSuffix: null,
            StreetType: vals.streetType,
            UnitNumber: vals.unitNumber,
            UnitType: null,
            LevelNumber: null,
            LevelType: null,
            AddressLine1: addressLine1,
            AddressLine2: null,
            Suburb: vals.townSuburb,
            State: vals.state,
            PostCode: vals.postCode,
            SA2_Id: null,
            GNAF_Id: null,
            Country: 'Australia',
            CountryCode: 'AU',
            Status: 'Address Check',
            Kiosk: null,
            AgentCode: null
        };

        try {
            const result = await createLead({ siteLead: JSON.stringify(siteLead) });
            this.loading = false;

            this.serviceable = result.Serviceable === true;
            this.leadID = result.Id;
            console.log('GOOGLE TAG MANAGER');
            //Push to Google Tag Manager
            this.pushToGTM(result);
            
            if (this.serviceable) {
                
                this.navigateToPlans();
            } else {
                this.showServiceabilityErrorMessage = true;
                this.buttonLabel = 'Check Availability';
            }
            this.closeManualAddressModal();
        } catch (error) {
            this.loading = false;
            this.validationErrorMessage = error.body?.message ||
                'An error occurred while checking serviceability.';
            console.error(error);
        }
    }

    navigateToPlans() {

        let url = `/giga/s/our-plans?enquiry=${this.leadID}&c__status=success`;
        if(this.voucher != ''){
            url = url + '&voucher=' + this.voucher;
        }
      
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        });
       
       
    }

    openManualAddressModal() {
        this.showManualAddressModal = true;
    }
    closeManualAddressModal() {
        this.showManualAddressModal = false;
    }

    handleRegisterNowClick() {
        this.selectedLeadData = { ...this.selectedMetaData, Address: this.address };
        this.showRegisterModal = true;
    }

    handleCloseRegisterModal(event) {
        this.showRegisterModal = false;
        if (event.detail?.showThankYou) this.showThankYouModal = true;
    }

    handleCloseThankYouModal() {
        this.showThankYouModal = false;
        this.address = '';
        this.addressSelected = false;
        this.hasPerformedCheck = false;
    }

    get shouldShowErrorMessage() {
        return (!this.serviceable && this.hasPerformedCheck);
    }

    getIpAddress() {
        const xhr = new XMLHttpRequest();
        xhr.open('GET', 'https://api.ipify.org/');
        xhr.send();
        xhr.onreadystatechange = () => {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                this.ipAddress = xhr.responseText;
            }
        };
    }

    setCookiePromoCode() {
        const params = new URLSearchParams(window.location.search);
        const v = params.get('voucher');
        if (v){
            document.cookie = `voucher=${v}`;
        }else{
            document.cookie = 'voucher=;';
        }
    }

    getCookie(name) {
        const cookies = decodeURIComponent(document.cookie).split(';');
        for (let c of cookies) {
            c = c.trim();
            if (c.startsWith(name + '=')) return c.substring(name.length + 1);
        }
        return '';
    }


    //Method for Google Tag Manager
    pushToGTM(response) {
        let serviceable = '';
        if(this.serviceable){
            serviceable = 'eligible';
        }else{
            serviceable = 'ineligible';
        }
     

        document.dispatchEvent(new CustomEvent(
            'eventGTM', { 
            'detail' : {
                'event': 'address_check',
                'lead_id': response.Id,
                'serviceability': serviceable,   
                'state': response.State,
                'postcode': response.PostCode,
                'coupon' : this.voucher != null ? this.voucher : '' 
                } 
            }
        ));



        document.dispatchEvent(new CustomEvent(
        'eventGTM', { 
        'detail' : {
            'event': 'view_plans_eligible',
            'lead_id': response.Id,
            'state': response.State,
            'postcode': response.PostCode,
            'coupon' : this.voucher != null ? this.voucher : '' 
            } 
        }
        ));
        
    }
}