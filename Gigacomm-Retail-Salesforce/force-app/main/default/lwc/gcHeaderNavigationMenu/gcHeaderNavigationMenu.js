import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { loadStyle, loadScript  } from 'lightning/platformResourceLoader';
import googleIcons from '@salesforce/resourceUrl/Google_Icons';
import fontAwesome from '@salesforce/resourceUrl/FontAwesome';
import bootstrap from '@salesforce/resourceUrl/BootstrapCss';
import bootstrapJs from '@salesforce/resourceUrl/BootstrapJS';
import gcAsset from '@salesforce/resourceUrl/GigacommAssetLWC';
import trustPilot from '@salesforce/resourceUrl/TrustPilotBootstrapJS';
import GigacommJsLibrary from '@salesforce/resourceUrl/GigacommJsLibrary';
import GigaCommLogo from '@salesforce/resourceUrl/GigaComm_Logo';
import HeaderPhoneIcon from '@salesforce/resourceUrl/Header_Phone_Icon';

import getNavigationMenuItems from '@salesforce/apex/GcHeaderNavigationMenuController.getNavigationMenuItems';

/**
 * This is a custom LWC navigation menu component.
 * Make sure the Guest user profile has access to the NavigationMenuItemsController apex class.
 */
export default class NavigationMenu extends LightningElement {

    renderedCallback() {
        Promise.all([
            loadStyle(this, googleIcons), loadStyle(this, fontAwesome + '/css/all.css'), loadScript(this, GigacommJsLibrary + '/TrustPilotBootstrapJS.js')
            
        ]).then().catch();
    }

    

    gcLogo = gcAsset + '/Icons/logo.png';
    HeaderGigaCommLogo = GigaCommLogo;
    HeaderButtonPhoneIcon = HeaderPhoneIcon;

    /**
     * the label or name of the nav menu linkset (NavigationMenuLinkSet.MasterLabel) exposed by the .js-meta.xml,
     * used to look up the NavigationMenuLinkSet.DeveloperName
     */
     @api linkSetMasterLabel;

     /**
      * include the Home menu item, if true
      */
     @api addHomeMenuItem = false;
 
     /**
      * include image URLs in the response, if true
      * useful for building a tile menu with images
      */
     @api includeImageUrls = false;

    /**
     * the menu items when fetched by the NavigationItemsController
     */
    @track menuItems = [];

    /**
     * if the items have been loaded
     */
    @track isLoaded = false;

    /**
     * the error if it occurs
     */
    @track error;

    /**
     * the published state of the site, used to determine from which schema to 
     * fetch the NavigationMenuItems
     */
    publishStatus;

    /**
     * Using a custom Apex controller, query for the NavigationMenuItems using the
     * menu name and published state.
     * 
     * The custom Apex controller is wired to provide reactive results. 
     */
    @wire(getNavigationMenuItems, {
        navigationLinkSetMasterLabel: '$linkSetMasterLabel',
        publishStatus: '$publishStatus',
        addHomeMenuItem: '$addHomeMenuItem',
        includeImageUrl: '$includeImageUrls'
    })
    wiredMenuItems({error, data}) {
        if (data && !this.isLoaded) {

            let menuNavs = [];
            
            //Remove the Home Navigation
            data.forEach(item => {
                    if(item.label != 'Home'){
                        menuNavs.push(item);
                    }
             
            });

            this.menuItems = menuNavs.map((item, index) => {
             
                return {
                            target: item.actionValue,
                            id: index,
                            label: item.label,
                            type: item.actionType,
                            subMenu: item.subMenu,
                            imageUrl: item.imageUrl,
                            windowName: item.target
                        }
            
              
            });
            this.error = undefined;
            this.isLoaded = true;
        } else if (error) {
            this.error = error;
            this.menuItems = [];
            this.isLoaded = true;
            console.error(`Navigation menu error: ${JSON.stringify(this.error)}`);
        }
    }

    /**
     * Using the CurrentPageReference, check if the app is 'commeditor'.
     * 
     * If the app is 'commeditor', then the page will use 'Draft' NavigationMenuItems. 
     * Otherwise, it will use the 'Live' schema.
    */
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        const app = currentPageReference && currentPageReference.state && currentPageReference.state.app;
        if (app === 'commeditor') {
            this.publishStatus = 'Draft';
        } else {
            this.publishStatus = 'Live';
        }
    }


    handleToggleCollapse(event){
        let targetId  = event.target.dataset.target;
        let target = this.template.querySelector(`[data-id="${targetId}"]`);
        
        
        
        if (target.classList.contains('show')) {
            target.classList.remove('show');
            target.classList.add('collapse');
      
        } else {
            target.classList.remove('collapse');
            target.classList.add('show');
        
        }

    }





}