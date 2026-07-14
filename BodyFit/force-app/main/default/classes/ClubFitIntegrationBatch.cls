global class ClubFitIntegrationBatch implements Database.Batchable<String>, Database.AllowsCallouts {
    private Map<String, String> clubApiKeys = new Map<String, String>{
        'Auburn'       => 'Bk9vJ7puaZ4jTnCssfWjE12CFvYeS7n34FPvy1du',
        'Blacktown'    => 'n9pa7h4HEz8YzulNtAxtC7a3aJhidLNA4Jz2HXXs',
        'Emerton'      => 'wlhgx4Jthlf7K9bB3aTMaxCzCEwewkFru1V302g0',
        'Glebe'        => 'Ss1Wwelozx3ZIPVanOyadanUJJFYcg7k1nwDyRwj',
        'Marrickville' => 'cGZdiAbjMV1As3MexfnK01znMaY10qeUac5Y6sxj',
        'Miranda'      => 'wsd99s1L3p5iC3zGXGchA3CcsDDiE11C4R9PxUS2',
        'Redfern'      => 'srjIyGXnq38p6a4ZPqqcdalJOUj6V7X314I46Q9e',
        'Shellharbour' => 'HzTVFrV2Rwaj2jOijfDLS7YYtbnqRMW26WH9B6q9'
    };

    private Map<String, Id> clubNameToId = new Map<String, Id>{
        'Auburn'       => 'a0RGC00001waDS62AM',
        'Blacktown'    => 'a0RGC00001waDSB2A2',
        'Emerton'      => 'a0RGC00001waDSG2A2',
        'Glebe'        => 'a0RGC00001waDSL2A2',
        'Marrickville' => 'a0RGC00001waDSC2A2',
        'Miranda'      => 'a0RGC00001waDSM2A2',
        'Redfern'      => 'a0RGC00001waDSN2A2',
        'Shellharbour' => 'a0RGC00001waDS72AM'
    };

    global Iterable<String> start(Database.BatchableContext bc) {
        return new List<String>{'start'};
    }

    global void execute(Database.BatchableContext bc, List<String> scope) {
        List<Account> accountsToUpsert = new List<Account>();

        RecordType personRT = [SELECT Id FROM RecordType 
                                WHERE SobjectType = 'Account' 
                                      AND IsPersonType = true 
                                LIMIT 1];

        // Calculate yesterday's date and format it.
        Date yesterday = Date.today().addDays(-1);
        DateTime dt = DateTime.newInstance(yesterday, Time.newInstance(0, 0, 0, 0));
        String formattedDate = dt.format('yyyy-MM-dd\'T\'HH:mm:ss');
        String fromDate = formattedDate;
        String updateDate = formattedDate;

        for (String clubName : clubApiKeys.keySet()) {
            String clubKey = clubApiKeys.get(clubName);
            try {
                // Removed the status filter from the URL so that all members are returned.
                String constructedUrl = 'https://api.clubfit.net.au/v1/members'
                    + '?fromdate=' + fromDate
                    + '&updatedate=' + updateDate
                    + '&apikey=' + clubKey
                    + '&limit=500&offset=0';
                System.debug('Request URL for ' + clubName + ': ' + constructedUrl);

                String jsonBody = ClubFitService.getMembersJSON(fromDate, updateDate, clubKey);
                System.debug('JSON response for ' + clubName + ': ' + jsonBody);

                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);
                List<Object> dataList = (List<Object>) jsonResponse.get('data');

                for (Object rec : dataList) {
                    Map<String, Object> member = (Map<String, Object>) rec;
                    Account acct = new Account();
                    acct.RecordTypeId = personRT.Id;

                    acct.put('Clubfit_Member_Id__c', (String) member.get('Number'));
                    acct.put('FirstName', member.get('FirstName'));
                    acct.put('LastName', member.get('LastName'));
                    acct.put('Gender__c', member.get('Gender'));
                    acct.put('Status__pc', member.get('Status'));
                    acct.put('Barcode__c', member.get('Barcode'));
                    acct.put('Fitness_Passport_Number__pc', member.get('FitnessPassportNumber'));

                    // Date of Birth.
                    if (member.get('DateOfBirth') != null) {
                        String dobStr = (String) member.get('DateOfBirth');
                        acct.put('PersonBirthdate', Date.valueOf(dobStr.substring(0,10)));
                    }

                    // Process nested Contact data and set address fields.
                    if (member.get('Contact') != null) {
                        Map<String, Object> contact = (Map<String, Object>) member.get('Contact');
                        acct.put('PersonEmail', contact.get('Email'));
                        acct.put('PersonMobilePhone', contact.get('Mobile'));
                        acct.put('PersonHasOptedOutOfEmail', contact.get('OptOutEmail'));
                        acct.put('et4ae5__HasOptedOutOfMobile__pc', contact.get('OptOutSms'));
                        // Instead of a single string, assign to individual address components.
                        if (contact.get('Address') != null) {
                            acct.BillingStreet = (String) contact.get('Address');
                        }
                        if (contact.get('Suburb') != null) {
                            acct.BillingCity = (String) contact.get('Suburb');
                        }
                        if (contact.get('State') != null) {
                            acct.BillingState = (String) contact.get('State');
                        }
                        if (contact.get('Postcode') != null) {
                            acct.BillingPostalCode = (String) contact.get('Postcode');
                        }
                    }

                    if (member.get('Membership') != null) {
                        Map<String, Object> membership = (Map<String, Object>) member.get('Membership');
                        if (membership.get('Id') != null) {
                            acct.put('Membership_ID__pc', String.valueOf(membership.get('Id')));
                        }
                        acct.put('Membership_Name__c', membership.get('Name'));
                        if (membership.get('StartDate') != null) {
                            String startStr = (String) membership.get('StartDate');
                            acct.put('Start_Date__pc', Date.valueOf(startStr.substring(0,10)));
                        }
                        if (membership.get('ExpiryDate') != null) {
                            String expiryStr = (String) membership.get('ExpiryDate');
                            acct.put('Expiry_Date__pc', Date.valueOf(expiryStr.substring(0,10)));
                        }
                        if (membership.get('SaleDate') != null) {
                            String saleStr = (String) membership.get('SaleDate');
                            acct.put('Sale_Date__c', Date.valueOf(saleStr.substring(0,10)));
                        }
                        // Map Membership Type.
                        if (membership.get('Type') != null) {
                            acct.put('Membership_Type__pc', membership.get('Type'));
                            acct.put('Membership_Type__c', membership.get('Type'));
                        }
                        // Process cancellation date, if present.
                        if (membership.get('CancellationDate') != null) {
                            String cancellationStr = (String) membership.get('CancellationDate');
                            acct.put('Cancellation_Date__c', Date.valueOf(cancellationStr.substring(0,10)));
                            // Override status to 'Archived' if a cancellation date is present.
                            acct.put('Status__pc', 'Archived');
                        }
                    }

                    // Set the AssociatedClub__c field using the map.
                    if (clubNameToId.containsKey(clubName)) {
                        acct.AssociatedClub__c = clubNameToId.get(clubName);
                    } else {
                        System.debug('No valid Id found for club: ' + clubName);
                    }

                    accountsToUpsert.add(acct);
                }
            } catch(Exception e) {
                System.debug('Error processing club ' + clubName + ': ' + e.getMessage());
            }
        }

        if (!accountsToUpsert.isEmpty()) {
            List<Database.UpsertResult> results = Database.upsert(accountsToUpsert, Account.Clubfit_Member_Id__c, false);
            for (Database.UpsertResult sr : results) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        if (err.getStatusCode() == StatusCode.DUPLICATES_DETECTED) {
                            System.debug('Duplicate record skipped: ' + err.getMessage());
                        } else {
                            System.debug('DML Error during upsert: ' + err.getMessage());
                        }
                    }
                }
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Optionally add finish logic here.
    }
}