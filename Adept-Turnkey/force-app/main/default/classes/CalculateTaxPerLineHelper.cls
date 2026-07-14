/**
 * @description Calculates total taxes for Order, Opportunity and Quote
 * @author Bricoleur Technologies
 * @date Feb 12 2025
 */
public class CalculateTaxPerLineHelper {
    
    public static void calcOppTotalTax(Map<Id, OpportunityLineItem> newMap, Map<Id, OpportunityLineItem> oldMap, Boolean isDelete) {
        
        Set<Id> oppIdSet = new Set<Id>();
        List<OpportunityLineItem> oliList = !isDelete ? newMap.values() : oldMap.values();

        for(OpportunityLineItem oli : oliList) {
            if((!isDelete && oli.Tax__c != null && oli.Tax__c != oldMap?.get(oli.Id)?.Tax__c) || isDelete) {
                oppIdSet.add(oli.OpportunityId);
            }
        }

        if(oppIdSet != null) {

            Map<Id, Decimal> oppTotalTaxMap = new Map<Id, Decimal>();

            for(OpportunityLineItem oli : [SELECT Id, OpportunityId, Tax__c FROM OpportunityLineItem WHERE OpportunityId IN :  oppIdSet]) {
                
                Decimal tax = oli.Tax__c != null ? oli.Tax__c : 0;

                if(!oppTotalTaxMap.containsKey(oli.OpportunityId)) {
                    oppTotalTaxMap.put(oli.OpportunityId, tax);
                }
                else {
                    oppTotalTaxMap.put(oli.OpportunityId, tax + oppTotalTaxMap.get(oli.OpportunityId));
                }
            }

            if(oppTotalTaxMap != null) {
                
                List<Opportunity> oppsToUpdate = new List<Opportunity>();

                for(Id oppId : oppTotalTaxMap.keySet()) {
                    Opportunity opp = new Opportunity();
                    opp.Id = oppId;
                    opp.Tax__c = oppTotalTaxMap.get(oppId);
                    oppsToUpdate.add(opp);
                }

                if(oppsToUpdate != null) {
                    try {
                        update oppsToUpdate;
                    }
                    catch(Exception e) {
                        Utilities.CreateExceptionLog(e, 'CalculateTaxPerLineHelper: calcOppTotalTax');
                    }
                }
            }
        }
    }

    public static void calcQuoteTotalTax(Map<Id, QuoteLineItem> newMap, Map<Id, QuoteLineItem> oldMap, Boolean isDelete) {
        
        Set<Id> quoteIdSet = new Set<Id>();
        List<QuoteLineItem> qliList = !isDelete ? newMap.values() : oldMap.values();

        for(QuoteLineItem qli : qliList) {
            if((!isDelete && qli.Tax__c != null && qli.Tax__c != oldMap?.get(qli.Id)?.Tax__c) || isDelete) {
                quoteIdSet.add(qli.QuoteId);
            }
        }

        if(quoteIdSet != null) {

            Map<Id, Decimal> quoteTotalTaxMap = new Map<Id, Decimal>();

            for(QuoteLineItem qli : [SELECT Id, QuoteId, Tax__c FROM QuoteLineItem WHERE QuoteId IN :  quoteIdSet]) {
                
                Decimal tax = qli.Tax__c != null ? qli.Tax__c : 0;

                if(!quoteTotalTaxMap.containsKey(qli.QuoteId)) {
                    quoteTotalTaxMap.put(qli.QuoteId, tax);
                }
                else {
                    quoteTotalTaxMap.put(qli.QuoteId, tax + quoteTotalTaxMap.get(qli.QuoteId));
                }
            }

            if(quoteTotalTaxMap != null) {
                
                List<Quote> quotesToUpdate = new List<Quote>();

                for(Id quoteId : quoteTotalTaxMap.keySet()) {
                    Quote quote = new Quote();
                    quote.Id = quoteId;
                    quote.Tax = quoteTotalTaxMap.get(quoteId);
                    quotesToUpdate.add(quote);
                }

                if(quotesToUpdate != null) {
                    try {
                        update quotesToUpdate;
                    }
                    catch(Exception e) {
                        Utilities.CreateExceptionLog(e, 'CalculateTaxPerLineHelper: calcQuoteTotalTax');
                    }
                }
            }
        }
    }

    public static void calcOrderTotalTax(Map<Id, OrderItem> newMap, Map<Id, OrderItem> oldMap, Boolean isDelete) {
        
        Set<Id> orderIdSet = new Set<Id>();
        List<OrderItem> oiList = !isDelete ? newMap.values() : oldMap.values();

        for(OrderItem oi : oiList) {
            if((!isDelete && oi.Tax__c != null && oi.Tax__c != oldMap?.get(oi.Id)?.Tax__c) || isDelete) {
                orderIdSet.add(oi.OrderId);
            }
        }

        if(orderIdSet != null) {

            Map<Id, Decimal> orderTotalTaxMap = new Map<Id, Decimal>();

            for(OrderItem oi : [SELECT Id, Tax__c, OrderId FROM OrderItem WHERE OrderId IN :  OrderIdSet]) {
                
                Decimal tax = oi.Tax__c != null ? oi.Tax__c : 0;

                if(!orderTotalTaxMap.containsKey(oi.OrderId)) {
                    orderTotalTaxMap.put(oi.OrderId, tax);
                }
                else {
                    orderTotalTaxMap.put(oi.OrderId, tax + orderTotalTaxMap.get(oi.OrderId));
                }
            }

            if(orderTotalTaxMap != null) {
                
                List<Order> ordersToUpdate = new List<Order>();

                for(Id orderId : orderTotalTaxMap.keySet()) {
                    Order order = new Order();
                    order.Id = orderId;
                    order.Tax__c = orderTotalTaxMap.get(orderId);
                    ordersToUpdate.add(order);
                }

                if(ordersToUpdate != null) {
                    try {
                        update ordersToUpdate;
                    }
                    catch(Exception e) {
                        Utilities.CreateExceptionLog(e, 'CalculateTaxPerLineHelper: calcOrderTotalTax');
                    }
                }
            }
        }
    }
}