@isTest
public class Invoke_EmailOrderConfirmationTest {

    @isTest
    static void testInvokeFlow_Success() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            CloseDate = Date.today(),
            StageName = 'Closed Won',
            AccountId = acc.Id
        );
        insert opp;

        Invoke_EmailOrderConfirmation.FlowInput input = new Invoke_EmailOrderConfirmation.FlowInput();
        input.oppId = opp.Id;
        input.oppStatus = 'Closed Won';

        List<Invoke_EmailOrderConfirmation.FlowInput> inputList = new List<Invoke_EmailOrderConfirmation.FlowInput>{input};

        Test.startTest();
        Invoke_EmailOrderConfirmation.invokeFlowAsync(inputList);
        Test.stopTest();
    }
}