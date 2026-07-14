import { LightningElement, track } from 'lwc';
import { label } from 'c/gcLabelUtility';
import gcAsset from '@salesforce/resourceUrl/GigacommAssetLWC';

export default class GcFaqs extends LightningElement {

    @track label= label;
    iconPlus;
    iconMinus;
    icon;
    collapseFAQOne = true;
    collapseFAQTwo = true;
    collapseFAQThree = true;
    collapseFAQFour = true;
    collapseFAQFive = true;
    collapseFAQSix = true;
    collapseFAQEight = true;
    collapseFAQNine = true;
    collapseFAQTen = true;

    connectedCallback(){
    this.icon = gcAsset + '/HomePageIcons/show.svg';
    this.iconPlus = gcAsset + '/HomePageIcons/show.svg';
    this.iconMinus = gcAsset + '/HomePageIcons/hide.svg';
  
    }

 

    handleToggleCollapse(event){
        let targetId  = event.target.dataset.target;
        let target = this.template.querySelector(`[data-id="${targetId}"]`);
       
        
       if(targetId == 'collapseFAQOne' && this.collapseFAQOne == true){
            this.collapseFAQOne = false;

       }else{
            this.collapseFAQOne = true;

       }
        
        if (target.classList.contains('show')) {
            target.classList.remove('show');
            target.classList.add('collapse');
          
        } else if (target.classList.contains('collapse')) {
            target.classList.remove('collapse');
            target.classList.add('show');
          
        }


    }

    handleToggleCollapse2(event){
        let targetId  = event.target.dataset.target;
        let target = this.template.querySelector(`[data-id="${targetId}"]`);
       
        
       if(targetId == 'collapseFAQTwo' && this.collapseFAQTwo == true){
            this.collapseFAQTwo = false;

       }else{
            this.collapseFAQTwo = true;

       }
        
        if (target.classList.contains('show')) {
            target.classList.remove('show');
            target.classList.add('collapse');
          
        } else if (target.classList.contains('collapse')) {
            target.classList.remove('collapse');
            target.classList.add('show');
          
        }


    }

    handleToggleCollapse3(event){
        let targetId  = event.target.dataset.target;
        let target = this.template.querySelector(`[data-id="${targetId}"]`);
       
        
       if(targetId == 'collapseFAQThree' && this.collapseFAQThree == true){
            this.collapseFAQThree = false;

       }else{
            this.collapseFAQThree = true;

       }
        
        if (target.classList.contains('show')) {
            target.classList.remove('show');
            target.classList.add('collapse');
          
        } else if (target.classList.contains('collapse')) {
            target.classList.remove('collapse');
            target.classList.add('show');
          
        }


    }

    handleToggleCollapse4(event){
        let targetId  = event.target.dataset.target;
        let target = this.template.querySelector(`[data-id="${targetId}"]`);
       
        
       if(targetId == 'collapseFAQFour' && this.collapseFAQFour == true){
            this.collapseFAQFour = false;

       }else{
            this.collapseFAQFour = true;

       }
        
        if (target.classList.contains('show')) {
            target.classList.remove('show');
            target.classList.add('collapse');
          
        } else if (target.classList.contains('collapse')) {
            target.classList.remove('collapse');
            target.classList.add('show');
          
        }


    }

    handleToggleCollapse5(event){
        let targetId  = event.target.dataset.target;
        let target = this.template.querySelector(`[data-id="${targetId}"]`);
       
        
       if(targetId == 'collapseFAQFive' && this.collapseFAQFive == true){
            this.collapseFAQFive = false;

       }else{
            this.collapseFAQFive = true;

       }
        
        if (target.classList.contains('show')) {
            target.classList.remove('show');
            target.classList.add('collapse');
          
        } else if (target.classList.contains('collapse')) {
            target.classList.remove('collapse');
            target.classList.add('show');
          
        }


    }

    handleToggleCollapse6(event){
        let targetId  = event.target.dataset.target;
        let target = this.template.querySelector(`[data-id="${targetId}"]`);
       
        
       if(targetId == 'collapseFAQSix' && this.collapseFAQSix == true){
            this.collapseFAQSix = false;

       }else{
            this.collapseFAQSix = true;

       }
        
        if (target.classList.contains('show')) {
            target.classList.remove('show');
            target.classList.add('collapse');
          
        } else if (target.classList.contains('collapse')) {
            target.classList.remove('collapse');
            target.classList.add('show');
          
        }


    }

    handleToggleCollapse8(event){
        let targetId  = event.target.dataset.target;
        let target = this.template.querySelector(`[data-id="${targetId}"]`);
       
        
       if(targetId == 'collapseFAQEight' && this.collapseFAQEight == true){
            this.collapseFAQEight = false;

       }else{
            this.collapseFAQEight = true;

       }
        
        if (target.classList.contains('show')) {
            target.classList.remove('show');
            target.classList.add('collapse');
          
        } else if (target.classList.contains('collapse')) {
            target.classList.remove('collapse');
            target.classList.add('show');
          
        }


    }

    handleToggleCollapse9(event){
        let targetId  = event.target.dataset.target;
        let target = this.template.querySelector(`[data-id="${targetId}"]`);
       
        
       if(targetId == 'collapseFAQNine' && this.collapseFAQNine == true){
            this.collapseFAQNine = false;

       }else{
            this.collapseFAQNine = true;

       }
        
        if (target.classList.contains('show')) {
            target.classList.remove('show');
            target.classList.add('collapse');
          
        } else if (target.classList.contains('collapse')) {
            target.classList.remove('collapse');
            target.classList.add('show');
          
        }


    }


    handleToggleCollapse10(event){
        let targetId  = event.target.dataset.target;
        let target = this.template.querySelector(`[data-id="${targetId}"]`);
       
        
       if(targetId == 'collapseFAQTen' && this.collapseFAQTen == true){
            this.collapseFAQTen = false;

       }else{
            this.collapseFAQTen = true;

       }
        
        if (target.classList.contains('show')) {
            target.classList.remove('show');
            target.classList.add('collapse');
          
        } else if (target.classList.contains('collapse')) {
            target.classList.remove('collapse');
            target.classList.add('show');
          
        }


    }


}