global class ClubFitPaymentHistoryBatch implements Database.Batchable<String>, Database.AllowsCallouts {

    // Map of club names to their API keys.
    private Map<String, String> clubApiKeys = new Map<String, String>{
        'Auburn'       => 'Bk9vJ7puaZ4jTnCssfWjE12CFvYeS7n34FPvy1du',
        'Blacktown'    => 'n9pa7h4HEz8YzulNtAxtC7a3aJhidLNA4Jz2HXXs',
        'Emerton'      => 'wlhgx4Jthlf7K9bB3aTMaxBzCEwewkFru1V302g0',
        'Glebe'        => 'Ss1Wwelozx3ZIPVanOyadanUJJFYcg7k1nwDyRwj',
        'Marrickville' => 'cGZdiAbjMV1As3MexfnK01znMaY10qeUac5Y6sxj',
        'Miranda'      => 'wsd99s1L3p5iC3zGXGchA3CcsDDiE11C4R9PxUS2',
        'Redfern'      => 'srjIyGXnq38p6a4ZPqqcdalJOUj6V7X314I46Q9e',
        'Shellharbour' => 'HzTVFrV2Rwaj2jOijfDLS7YYtbnqRMW26WH9B6q9'
    };

    // This batch fetches payment history from "yesterday" (start of day).
    private DateTime fromDateTime;

    public ClubFitPaymentHistoryBatch() {
        this.fromDateTime = DateTime.newInstance(Date.today().addDays(-1), Time.newInstance(0, 0, 0, 0));
    }

    global Iterable<String> start(Database.BatchableContext bc) {
        // Dummy iterable; our logic is inside execute.
        return new List<String>{ 'start' };
    }

    global void execute(Database.BatchableContext bc, List<String> scope) {
        List<Payment_History__c> allPaymentsToInsert = new List<Payment_History__c>();
        String fromDateStr = fromDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss');

        // Loop through each club.
        for (String clubName : clubApiKeys.keySet()) {
            String apiKey = clubApiKeys.get(clubName);
            Integer offset = 0;
            Boolean keepGoing = true;

            while (keepGoing) {
                try {
                    String jsonResponse = ClubFitService.getPaymentHistoryJSON(fromDateStr, apiKey, offset);
                    Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
                    List<Object> dataList = (List<Object>) jsonMap.get('data');

                    if (dataList == null || dataList.isEmpty()) {
                        keepGoing = false;
                        break;
                    }

                    // Collect the member numbers from the JSON ("Number" field).
                    Set<String> memberNumbers = new Set<String>();
                    for (Object rec : dataList) {
                        Map<String, Object> paymentRec = (Map<String, Object>) rec;
                        String memNum = (String) paymentRec.get('Number');
                        if (memNum != null) {
                            memberNumbers.add(memNum);
                        }
                    }

                    // Query matching Accounts by external id.
                    Map<String, Id> memberNumToAcctId = new Map<String, Id>();
                    if (!memberNumbers.isEmpty()) {
                        for (Account acc : [
                            SELECT Id, Clubfit_Member_Id__c
                            FROM Account
                            WHERE Clubfit_Member_Id__c IN :memberNumbers
                        ]) {
                            memberNumToAcctId.put(acc.Clubfit_Member_Id__c, acc.Id);
                        }
                    }

                    // Process each payment record.
                    for (Object rec : dataList) {
                        Map<String, Object> paymentRec = (Map<String, Object>) rec;
                        Payment_History__c ph = new Payment_History__c();

                        // Set Member lookup and external id.
                        String memNum = (String) paymentRec.get('Number');
                        ph.Member_Id__c = memNum;
                        if (memberNumToAcctId.containsKey(memNum)) {
                            ph.Member__c = memberNumToAcctId.get(memNum);
                        }

                        // Map basic fields.
                        if (paymentRec.containsKey('Amount')) {
                            ph.Amount__c = (Decimal) paymentRec.get('Amount');
                        }
                        if (paymentRec.containsKey('PaymentDate')) {
                            String dtStr = (String) paymentRec.get('PaymentDate');
                            dtStr = dtStr.replace('T', ' ').replace('Z', '');
                            ph.Payment_Date__c = DateTime.valueOf(dtStr);
                        }
                        if (paymentRec.containsKey('PaymentType')) {
                            ph.Payment_Type__c = (String) paymentRec.get('PaymentType');
                        }
                        if (paymentRec.containsKey('Response')) {
                            ph.Response__c = (String) paymentRec.get('Response');
                        }
                        if (paymentRec.containsKey('PaymentDescription')) {
                            ph.Payment_Description__c = (String) paymentRec.get('PaymentDescription');
                        }
                        
                        // Map PaymentForReference sub-object.
                        if (paymentRec.containsKey('PaymentForReference')) {
                            Map<String, Object> ref = (Map<String, Object>) paymentRec.get('PaymentForReference');
                            if (ref != null) {
                                ph.Payment_Reference_Id__c = String.valueOf(ref.get('Id'));
                                ph.Payment_Reference_Name__c = (String) ref.get('Name');
                            }
                        }
                        
                        // Map FeeBreakdown sub-object.
                        if (paymentRec.containsKey('FeeBreakdown')) {
                            Map<String, Object> fees = (Map<String, Object>) paymentRec.get('FeeBreakdown');
                            if (fees != null) {
                                if (fees.containsKey('AccessCardFee')) {
                                    ph.Access_Card_Fee__c = (Decimal) fees.get('AccessCardFee');
                                }
                                if (fees.containsKey('AddOnAmount')) {
                                    ph.Add_On_Amount__c = (Decimal) fees.get('AddOnAmount');
                                }
                                if (fees.containsKey('Adjustment')) {
                                    ph.Adjustment__c = (Decimal) fees.get('Adjustment');
                                }
                                if (fees.containsKey('ArrearsFee')) {
                                    ph.Arrears_Fee__c = (Decimal) fees.get('ArrearsFee');
                                }
                                if (fees.containsKey('CancellationLateFee')) {
                                    ph.Cancellation_Late_Fee__c = (Decimal) fees.get('CancellationLateFee');
                                }
                                if (fees.containsKey('CardSurchargeFee')) {
                                    ph.Card_Surcharge_Fee__c = (Decimal) fees.get('CardSurchargeFee');
                                }
                                if (fees.containsKey('ClassNoShowFee')) {
                                    ph.Class_No_Show_Fee__c = (Decimal) fees.get('ClassNoShowFee');
                                }
                                if (fees.containsKey('CrecheClassNoShowFee')) {
                                    ph.Creche_Class_No_Show_Fee__c = (Decimal) fees.get('CrecheClassNoShowFee');
                                }
                                if (fees.containsKey('DishonourFee')) {
                                    ph.Dishonour_Fee__c = (Decimal) fees.get('DishonourFee');
                                }
                                if (fees.containsKey('JoiningFee')) {
                                    ph.Joining_Fee__c = (Decimal) fees.get('JoiningFee');
                                }
                                if (fees.containsKey('MaintenanceFee')) {
                                    ph.Maintenance_Fee__c = (Decimal) fees.get('MaintenanceFee');
                                }
                                if (fees.containsKey('PosTransaction')) {
                                    ph.Pos_Transaction__c = (Decimal) fees.get('PosTransaction');
                                }
                                if (fees.containsKey('Prorata')) {
                                    ph.Prorata__c = (Decimal) fees.get('Prorata');
                                }
                                if (fees.containsKey('PtNoShowFee')) {
                                    ph.Pt_No_Show_Fee__c = (Decimal) fees.get('PtNoShowFee');
                                }
                                if (fees.containsKey('SetupFee')) {
                                    ph.Setup_Fee__c = (Decimal) fees.get('SetupFee');
                                }
                                if (fees.containsKey('SubscriptionFee')) {
                                    ph.Subscription_Fee__c = (Decimal) fees.get('SubscriptionFee');
                                }
                                if (fees.containsKey('SuspensionFee')) {
                                    ph.Suspension_Fee__c = (Decimal) fees.get('SuspensionFee');
                                }
                                if (fees.containsKey('TransactionFee')) {
                                    ph.Transaction_Fee__c = (Decimal) fees.get('TransactionFee');
                                }
                            }
                        }
                        
                        // Map Refund sub-object.
                        if (paymentRec.containsKey('Refund')) {
                            Map<String, Object> refund = (Map<String, Object>) paymentRec.get('Refund');
                            if (refund != null) {
                                if (refund.containsKey('IsRefund')) {
                                    ph.IsRefund__c = (Boolean) refund.get('IsRefund');
                                }
                                if (refund.containsKey('RefundedPaymentId')) {
                                    ph.Refunded_Payment_Id__c = (String) refund.get('RefundedPaymentId');
                                }
                            }
                        }
                        
                        // (Optional) Set additional fields such as Club__c if you can resolve a club record.
                        allPaymentsToInsert.add(ph);
                    }
                    
                    if (dataList.size() < 500) {
                        keepGoing = false;
                    } else {
                        offset += 500;
                    }
                } catch (Exception ex) {
                    System.debug('Error retrieving payment history for club ' + clubName +
                        ' at offset ' + offset + ': ' + ex.getMessage());
                    keepGoing = false;
                }
            }
        }
        
        if (!allPaymentsToInsert.isEmpty()) {
            try {
                insert allPaymentsToInsert;
            } catch (DmlException dme) {
                System.debug('Error inserting payment history records: ' + dme.getMessage());
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Optional: add logging or post-processing here.
    }
}