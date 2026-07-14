import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { loadScript } from 'lightning/platformResourceLoader';
import GigaCommAsset from '@salesforce/resourceUrl/GigacommAssetLWC';
import GigaCommCustomerCharter from '@salesforce/resourceUrl/GigacommCustomerCharter';
import GigaCommSFOA from '@salesforce/resourceUrl/GigaCommSFOA';
import GigaCommAcceptableFairUsePolicy from '@salesforce/resourceUrl/GigacommAcceptableFairUsePolicy';
import GigaCommPrivacyPolicy from '@salesforce/resourceUrl/GigacommPrivacyPolicy';
import GigaCommFinancialHardshipPolicy from '@salesforce/resourceUrl/GigacommFinancialHardshipPolicy';
import GigaCommSocialMediaModerationPolicy from '@salesforce/resourceUrl/GigacommSocialMediaModerationPolicy';
import AuthorisedRepresentativeForm from '@salesforce/resourceUrl/AuthorisedRepresentativeForm';

export default class GigaCommFooterLWC extends NavigationMixin(LightningElement) {
    // Resource URLs
    footerLogoUrl = GigaCommAsset + '/HomePageIcons/footerLogo.svg';
    facebookIconUrl = GigaCommAsset + '/HomePageIcons/facebook.svg';
    instagramIconUrl = GigaCommAsset + '/HomePageIcons/instagram.svg';
    linkedinIconUrl = GigaCommAsset + '/HomePageIcons/linkedin.svg';
    
    // Policy URLs
    customerCharterUrl = GigaCommCustomerCharter;
    customerTermsUrl = GigaCommSFOA;
    acceptableUsePolicyUrl = GigaCommAcceptableFairUsePolicy;
    privacyPolicyUrl = GigaCommPrivacyPolicy;
    financialHardshipPolicyUrl = GigaCommFinancialHardshipPolicy;
    socialMediaPolicyUrl = GigaCommSocialMediaModerationPolicy;
    representativeForm = AuthorisedRepresentativeForm;

    connectedCallback() {
        // Load Google Tag Manager script
        this.loadGoogleTagManager();
    }
    get isChristmasHours() {
        const now = new Date();
        const start = new Date(2025, 11, 24, 0, 0, 0);    
        const end   = new Date(2026, 0, 1, 23, 59, 59);   

        return now >= start && now <= end;
    }
    async loadGoogleTagManager() {
        try {
            // You'll need to create a custom label for the Google Tag Manager script
            // and load it here using loadScript
            // This is a placeholder for the actual implementation
        } catch (error) {
            console.error('Error loading Google Tag Manager:', error);
        }
    }

    navigateToHome() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Home'
            }
        });
    }

    handlePolicyLinkClick(event) {
        const url = event.currentTarget.dataset.url;
        if (url) {
            window.open(url, '_blank');
        }
    }
}
