import { LightningElement} from 'lwc';
import GigaCommFooterBanner from '@salesforce/resourceUrl/GigaCommFooterBanner';

export default class GigaCommAddressFinderFooterLWC extends LightningElement {
   
    get heroBackgroundStyle() {
        return `background-image: url('${GigaCommFooterBanner}')`;
    }
}