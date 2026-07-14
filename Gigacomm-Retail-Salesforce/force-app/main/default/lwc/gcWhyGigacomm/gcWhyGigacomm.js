import { LightningElement, track } from 'lwc';
import gcAsset from '@salesforce/resourceUrl/GigacommAssetLWC'; 
import ArrowSymbol from '@salesforce/resourceUrl/ArrowSymbol';
import { NavigationMixin } from 'lightning/navigation';
export default class GcWhyGigacomm extends NavigationMixin(LightningElement) {


    iconRoundSpeed = gcAsset + '/HomePageIcons/ic_round-speed.svg';
    iconWifiSignal = gcAsset + '/HomePageIcons/wifiSignal.svg';
    iconValue = gcAsset + '/HomePageIcons/Value.svg';
    @track wgCarousel1 = 'carousel-item active';
    @track wgCarousel2 = 'carousel-item ';
    @track wgCarousel3 = 'carousel-item ';
    ArrowSymbolIcon = ArrowSymbol;
   
    /*
    get wgCarousel1(){
        return this.wgCarousel1;

    }

    get wgCarousel2(){
        return this.wgCarousel2;

    }

    get wgCarousel3(){
        return this.wgCarousel3;

    }
    */

    @track currentTarget = 'wgCarousel1';
    @track currentIndex = 1;


    

    handleToggleCollapse(event){

        let carouselTarget = this.template.querySelectorAll('[data-bs-target="#carouselExampleIndicators"]');
        // Remove 'active' class from all buttons
        carouselTarget.forEach(btn => btn.classList.remove('active'));

        let carouselBtn = event.target;
        carouselBtn.className = 'active';

        let targetId  = event.target.dataset.slideto;
        let target = this.template.querySelector(`[data-id="${targetId}"]`);
   
        let carousel1 = this.template.querySelector('[data-id="wgCarousel1"]');
        let carousel2 = this.template.querySelector('[data-id="wgCarousel2"]');
        let carousel3 = this.template.querySelector('[data-id="wgCarousel3"]');

        carousel1.className  = 'carousel-item';
        carousel2.className  = 'carousel-item ';
        carousel3.className  = 'carousel-item ';
    
        target.classList.add('active');

        
        if(targetId == 'wgCarousel1'){
            //this.currentTarget = 'wgCarousel1';
            this.currentIndex = 1;
        }else if(targetId == 'wgCarousel2'){
            //this.currentTarget = 'wgCarousel2';
            this.currentIndex = 2;
        }else if(targetId == 'wgCarousel3'){
            //this.currentTarget = 'wgCarousel3';
            this.currentIndex = 3;
        }

    }

    

    prev(event){

        this.currentIndex = this.currentIndex - 1;
            if(this.currentIndex < 1){
                this.currentIndex = 3;  
            }
            let carousel1 = this.template.querySelector('[data-id="wgCarousel1"]');
            let carousel2 = this.template.querySelector('[data-id="wgCarousel2"]');
            let carousel3 = this.template.querySelector('[data-id="wgCarousel3"]');

            carousel1.className  = 'carousel-item';
            carousel2.className  = 'carousel-item ';
            carousel3.className  = 'carousel-item ';

            let carouselBtn1 = this.template.querySelector('[data-slideto="wgCarousel1"]');
            let carouselBtn2 = this.template.querySelector('[data-slideto="wgCarousel2"]');
            let carouselBtn3 = this.template.querySelector('[data-slideto="wgCarousel3"]');

            carouselBtn1.className  = '';
            carouselBtn2.className  = '';
            carouselBtn3.className  = '';


            let target = this.template.querySelector(`[data-id="wgCarousel${this.currentIndex}"]`);
            console.log('target: ' + target);
            target.classList.add('active');


            let targetBtn = this.template.querySelector(`[data-slideto="wgCarousel${this.currentIndex}"]`);
            targetBtn.classList.add('active');


    
       
        
    }

    next(event){

            this.currentIndex = this.currentIndex + 1;
                if(this.currentIndex > 3){ 
                    this.currentIndex = 1;
                }

            let carousel1 = this.template.querySelector('[data-id="wgCarousel1"]');
            let carousel2 = this.template.querySelector('[data-id="wgCarousel2"]');
            let carousel3 = this.template.querySelector('[data-id="wgCarousel3"]');

            carousel1.className  = 'carousel-item';
            carousel2.className  = 'carousel-item ';
            carousel3.className  = 'carousel-item ';

            let carouselBtn1 = this.template.querySelector('[data-slideto="wgCarousel1"]');
            let carouselBtn2 = this.template.querySelector('[data-slideto="wgCarousel2"]');
            let carouselBtn3 = this.template.querySelector('[data-slideto="wgCarousel3"]');

            carouselBtn1.className  = '';
            carouselBtn2.className  = '';
            carouselBtn3.className  = '';

            let target = this.template.querySelector(`[data-id="wgCarousel${this.currentIndex}"]`);
            target.classList.add('active');


            let targetBtn = this.template.querySelector(`[data-slideto="wgCarousel${this.currentIndex}"]`);
            targetBtn.classList.add('active');


     
        
    }

    handleNavToOurPlanPage() {
     try {
            const pageref = {
                type: 'standard__webPage',
                attributes: {
                    url: '/giga/s/our-plans'
                }
            };

            this[NavigationMixin.Navigate](pageref);
        } catch (error) {
            console.error('Navigation error:', error);
            alert('An error occurred while navigating: ' + (error?.message || error));
        }

    }
}