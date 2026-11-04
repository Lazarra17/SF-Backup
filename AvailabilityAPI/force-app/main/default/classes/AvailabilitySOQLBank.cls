/*
@Author: Chad Lazarra 
@Date: 3-Nov-2026
@Desc: SOQL Bank Class
@History: [1] Created - 3-Nov-2026
*/
public with sharing class AvailabilitySOQLBank {
    
    public static Account getByUPRN(String uprn) {
        
        List<Account> accounts = [SELECT Id, UPRN__c, Ready_For_Sale__c, Client_Journey__c, Available_For_Pre_Order__c FROM Account  WHERE UPRN__c = :uprn  LIMIT 1];
        
        return accounts.isEmpty() ? null : accounts[0];
    }
}