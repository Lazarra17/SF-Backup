public without sharing class MinimumCommitmentContractTermCtrl {
    
    public Id oppId { get; set; }

    public Decimal getMinPrice() {

        try {
            
            Set<Id> voucherIdSet = new Set<Id>();
            Set<Id> voucherProdIdSet = new Set<Id>();
            Set<Id> monthlyPlanSet = new Set<Id>();
            Map<Id, Decimal> monthlyAmtMap = new Map<Id, Decimal>();
            //Map<Id, String> testMap = new Map<Id, String>();

            Opportunity opp = [SELECT Id, Term_bric__c, Voucher_bric__c FROM Opportunity WHERE Id =: oppId];
            voucherIdSet.add(opp.Voucher_bric__c);

            for(OpportunityLineItem oli : [SELECT Id, Product2Id, TotalPrice, Product2.Name, Frequency_Bric__c FROM OpportunityLineItem WHERE OpportunityId =: oppId]) {
                monthlyAmtMap.put(oli.Product2Id, oli.TotalPrice);
                //testMap.put(oli.Product2Id, oli.Product2.Name);
                if(oli.Frequency_Bric__c == 'Monthly') {
                    monthlyPlanSet.add(oli.Product2Id);
                }
            }

            System.debug('monthlyAmtMap '+monthlyAmtMap);
            //System.debug('testMap '+testMap);

            Decimal minimumPrice = 0;

            for(Voucher_Product__c vp : [SELECT Id, Agreement_Length__c, Duration_months_bric__c, Product_to_Apply_bric__c, Apply_if_Product_Present_bric__c FROM Voucher_Product__c WHERE Voucher_bric__c IN: voucherIdSet]) {
                
                voucherProdIdSet.add(vp.Product_to_Apply_bric__c);
                voucherProdIdSet.add(vp.Apply_if_Product_Present_bric__c);

                if(monthlyAmtMap.containsKey(vp.Apply_if_Product_Present_bric__c) && monthlyAmtMap.containsKey(vp.Product_to_Apply_bric__c)) {
                    
                    if(monthlyPlanSet.contains(vp.Product_to_Apply_bric__c)) {

                        Integer aggLength = agreementLength(opp.Term_bric__c);
                        System.debug('aggLength 1 '+aggLength);
                        aggLength = Integer.valueOf(vp.Duration_months_bric__c) > aggLength ? Integer.valueOf(vp.Duration_months_bric__c) : aggLength;

                        Decimal selectedProdAmt = monthlyAmtMap.get(vp.Apply_if_Product_Present_bric__c);
                        Decimal voucherProdAmt = monthlyAmtMap.get(vp.Product_to_Apply_bric__c);
                        System.debug('aggLength 2 '+aggLength);
                        System.debug('selectedProdAmt '+selectedProdAmt);
                        System.debug('voucherProdAmt '+voucherProdAmt);
                        System.debug('vp.Duration_months_bric__c '+vp.Duration_months_bric__c);

                        System.debug('((' + selectedProdAmt + ' * ' + aggLength + ') + (' + voucherProdAmt + ' * ' + vp.Duration_months_bric__c + '))');
                        
                        Decimal subTotal = ((selectedProdAmt * aggLength) + (voucherProdAmt * vp.Duration_months_bric__c));
                        
                        if(minimumPrice == 0) {
                            minimumPrice = subTotal;
                            System.debug('1st minimumPrice '+minimumPrice);
                        }
                        else {
                            System.debug('2nd minimumPrice '+Math.abs(subTotal)+' + '+Math.abs(minimumPrice));
                            minimumPrice = Math.abs(subTotal) + Math.abs(minimumPrice);
                            System.debug('2nd minimumPrice '+minimumPrice);
                        }

                        //System.debug('testMap '+testMap.get(vp.Product_to_Apply_bric__c)+' == '+testMap.get(vp.Apply_if_Product_Present_bric__c) + ' ((' + selectedProdAmt + ' * ' + aggLength + ') + (' + voucherProdAmt + ' * ' + vp.Duration_months_bric__c + ')) == '+minimumPrice);
                    }
                }
            }

            System.debug('minimumPrice 1 '+minimumPrice);

            for(Id key : monthlyAmtMap.keySet()) {
                if(!voucherProdIdSet.contains(key)) {
                    System.debug('key '+key+' == '+monthlyAmtMap.get(key));
                    minimumPrice += monthlyAmtMap.get(key);
                    //System.debug('testMap one time '+testMap.get(key)+' == '+minimumPrice);

                    System.debug('minimumPrice 3 '+minimumPrice);
                }
            }
            
            return minimumPrice;
        }
        catch(Exception e) {
            return 0;
        }
    }

    public Integer agreementLength(String aggLength) {
        
        if(aggLength == 'Monthly') {
            return 1;
        }
        else if(aggLength == '12 Months') {
            return 12;
        }
        else if(aggLength == '24 Months') {
            return 24;
        }
        else if(aggLength == '36 Months') {
            return 36;
        }
        else if(aggLength == '48 Months') {
            return 48;
        }
        else if(aggLength == '60 Months') {
            return 60;
        }
        return 1;
    }

}