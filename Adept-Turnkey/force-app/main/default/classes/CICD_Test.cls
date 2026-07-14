@isTest
public class CICD_Test {

    /**
     * LOGIC SECTION 
     * (Normally this would be in a separate class, but we've 
     * included it here for a standalone 100% coverage example).
     */
    public static String processString(String input) {
        if (String.isBlank(input)) {
            return 'EMPTY';
        }
        
        if (input.contains('ERROR')) {
            return 'CRITICAL';
        }
        
        return input.trim().toUpperCase();
    }

    /**
     * TEST SECTION
     */
    @isTest
    static void runFullCoverageTest() {
        Test.startTest();
        
        // 1. Cover the 'Blank' branch (Line coverage for the first 'if')
        String res1 = CICD_Test.processString(null);
        String res2 = CICD_Test.processString('  ');
        
        // 2. Cover the 'Error' branch (Line coverage for the second 'if')
        String res3 = CICD_Test.processString('SYSTEM_ERROR_LOG');
        
        // 3. Cover the standard return (Line coverage for the final return)
        String res4 = CICD_Test.processString('  hello world  ');
        
        Test.stopTest();

        // Assertions to ensure the code actually works as expected
        System.assertEquals('EMPTY', res1);
        System.assertEquals('EMPTY', res2);
        System.assertEquals('CRITICAL', res3);
        System.assertEquals('HELLO WORLD', res4);
    }
}