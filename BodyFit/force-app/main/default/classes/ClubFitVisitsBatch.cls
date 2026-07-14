global class ClubFitVisitsBatch implements Database.Batchable<String>, Database.AllowsCallouts {

    // Map of club names to their API keys
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

    // This batch fetches visits from "yesterday".
    private DateTime fromDateTime;

    public ClubFitVisitsBatch() {
        // Set the starting point for the visits: yesterday's start of day.
        this.fromDateTime = DateTime.newInstance(Date.today().addDays(-1), Time.newInstance(0, 0, 0, 0));
    }

    global Iterable<String> start(Database.BatchableContext bc) {
        // A dummy iterable since the logic is implemented in execute.
        return new List<String>{ 'start' };
    }

    global void execute(Database.BatchableContext bc, List<String> scope) {
        // Collect all visits from all clubs and insert them in one DML operation.
        List<Visitation__c> allVisitsToInsert = new List<Visitation__c>();

        // Format the fromDateTime as required.
        String fromDateStr = fromDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss');

        // Loop through each club.
        for (String clubName : clubApiKeys.keySet()) {
            String apiKey = clubApiKeys.get(clubName);
            Integer offset = 0;
            Boolean keepGoing = true;

            while (keepGoing) {
                try {
                    // Make the callout to get visits JSON.
                    String jsonResponse = ClubFitService.getVisitsJSON(fromDateStr, apiKey, offset);
                    // Deserialize JSON response.
                    Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
                    List<Object> dataList = (List<Object>) jsonMap.get('data');

                    if (dataList == null || dataList.isEmpty()) {
                        // No more records for this club.
                        keepGoing = false;
                        break;
                    }

                    // Collect the MemberNumbers from the JSON.
                    Set<String> memberNumbers = new Set<String>();
                    for (Object rec : dataList) {
                        Map<String, Object> visitRec = (Map<String, Object>) rec;
                        String memNum = (String) visitRec.get('MemberNumber');
                        if (memNum != null) {
                            memberNumbers.add(memNum);
                        }
                    }

                    // Query matching Accounts by their Clubfit_Member_Id__c.
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

                    // Process each visit record.
                    for (Object rec : dataList) {
                        Map<String, Object> visitRec = (Map<String, Object>) rec;
                        Visitation__c v = new Visitation__c();

                        // Set the Member lookup if an Account was found.
                        String memNum = (String) visitRec.get('MemberNumber');
                        if (memberNumToAcctId.containsKey(memNum)) {
                            v.Member__c = memberNumToAcctId.get(memNum);
                        }
                        // Always store the raw member number.
                        v.Member_ID__c = memNum;
                        // Set Door and Scan Source.
                        v.Door__c = (String) visitRec.get('Door');
                        v.Scan_Source__c = (String) visitRec.get('ScanSource');

                        // Parse and set the Visit DateTime.
                        if (visitRec.containsKey('VisitDateTime')) {
                            String dtStr = (String) visitRec.get('VisitDateTime');
                            // Replace 'T' with space and remove trailing 'Z'
                            dtStr = dtStr.replace('T', ' ').replace('Z', '');
                            DateTime dtVisit = DateTime.valueOf(dtStr);
                            v.Date_Time__c = dtVisit;
                        }

                        allVisitsToInsert.add(v);
                    }

                    // Pagination: if fewer than 500 records returned, stop.
                    if (dataList.size() < 500) {
                        keepGoing = false;
                    } else {
                        offset += 500;
                    }
                } catch (Exception ex) {
                    System.debug('Error retrieving visits for club ' + clubName +
                        ' at offset ' + offset + ': ' + ex.getMessage());
                    keepGoing = false;
                }
            }
        }

        // Now that all callouts are complete, perform one bulk DML.
        if (!allVisitsToInsert.isEmpty()) {
            try {
                insert allVisitsToInsert;
            } catch (DmlException dme) {
                System.debug('Error inserting visit records: ' + dme.getMessage());
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Optionally perform post-processing or logging.
    }
}