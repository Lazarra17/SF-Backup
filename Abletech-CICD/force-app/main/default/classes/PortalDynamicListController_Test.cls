@IsTest
public class PortalDynamicListController_Test {

    private static final Date NEWEST_DATE = Date.newInstance(2025, 11, 20);
    private static final Date MIDDLE_DATE = Date.newInstance(2025, 11, 15);
    private static final Date OLDEST_DATE = Date.newInstance(2025, 11, 10);

    private static List<Order> createTestOrders(Account accId) {
        Product2 testProduct = new Product2(Name = 'Test Product', isActive = true);
        insert testProduct;

        Id standardPBId = Test.getStandardPricebookId();

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPBId,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbe;

        List<Order> ordersToInsert = new List<Order>();
        ordersToInsert.add(new Order(
            AccountId = accId.Id,
            EffectiveDate = NEWEST_DATE,
            Status = 'Draft',
            Pricebook2Id = standardPBId
        ));
        ordersToInsert.add(new Order(
            AccountId = accId.Id,
            EffectiveDate = MIDDLE_DATE,
            Status = 'Draft',
            Pricebook2Id = standardPBId
        ));
        ordersToInsert.add(new Order(
            AccountId = accId.Id,
            EffectiveDate = OLDEST_DATE,
            Status = 'Draft',
            Pricebook2Id = standardPBId
        ));

        insert ordersToInsert;
        return ordersToInsert;
    }

    @IsTest
    static void testGetDynamicList_OrderScenarios() {
        Account testAccount = new Account(Name = 'Test Account for Order');
        insert testAccount;
        createTestOrders(testAccount);

        User standardUser = createStandardUser();

        System.runAs(standardUser) {
            Test.startTest();

            PortalDynamicListController.ListResult result1 = PortalDynamicListController.getDynamicList(
                'Order', 'OrderNumber, Status, Account.Name', '', null, null, null
            );
            System.assertEquals(3, result1.records.size(), 'Should return all 3 orders.');

            PortalDynamicListController.ListResult result2 = PortalDynamicListController.getDynamicList(
                'Order', 'OrderNumber, EffectiveDate', 'Status = \'Draft\'', 'EffectiveDate DESC', 1, null
            );
            System.assertEquals(1, result2.records.size(), 'Should return 1 record due to limit.');
            Order returnedOrder = (Order) result2.records[0];
            System.assertEquals(NEWEST_DATE, returnedOrder.EffectiveDate, 'Should return the newest draft order.');

            PortalDynamicListController.ListResult result3 = PortalDynamicListController.getDynamicList(
                'Order', 'Status', '', null, 0, 1
            );
            System.assertEquals(2, result3.records.size(), 'Should return 2 records with offset 1.');

            Test.stopTest();
        }
    }

    @IsTest
    static void testGetDynamicList_AccountScenario() {
        insert new Account(Name = 'Alpha Account');
        insert new Account(Name = 'Beta Account');

        User standardUser = createStandardUser();

        System.runAs(standardUser) {
            Test.startTest();

            PortalDynamicListController.ListResult result = PortalDynamicListController.getDynamicList(
                'Account', 'Name', 'Name LIKE \'Alpha%\'', 'Name ASC', null, null
            );

            System.assertEquals(1, result.records.size(), 'Should return one matching account.');
            System.assertEquals('Alpha Account', ((Account) result.records[0]).Name);

            Test.stopTest();
        }
    }

    @IsTest
    static void testGetDynamicList_ExceptionHandling() {
        User standardUser = createStandardUser();

        System.runAs(standardUser) {
            Test.startTest();

            Boolean caughtInvalidObject = false;
            try {
                PortalDynamicListController.getDynamicList('NotARealObject', 'Name', '', null, 1, null);
            } catch (AuraHandledException e) {
                caughtInvalidObject = true;
            }
            System.assert(caughtInvalidObject, 'Should catch an AuraHandledException for an invalid object.');

            Boolean caughtBadField = false;
            try {
                PortalDynamicListController.getDynamicList('Order', 'OrderNumber, NonExistentField', '', null, 1, null);
            } catch (AuraHandledException e) {
                caughtBadField = true;
            }
            System.assert(caughtBadField, 'Should catch an AuraHandledException for an invalid field.');

            Test.stopTest();
        }
    }

    private static User createStandardUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User u = new User(
            Alias = 'testus',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser@test.com' + System.currentTimeMillis()
        );
        insert u;
        return u;
    }
}