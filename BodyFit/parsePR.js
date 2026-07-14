const fs = require('fs');
const readline = require('readline');
const path = require('path');

async function extractTests() {
    // Paths for input and output
    const prBodyPath = path.join(__dirname, 'pr_body.txt');
    const testsFile = path.join(__dirname, 'testsToRun.txt');
    
    let foundTests = [];

    // 1. Check if the PR body file exists
    if (!fs.existsSync(prBodyPath)) {
        console.log('PR body file not found. Defaulting to "all".');
        await fs.promises.writeFile(testsFile, 'all');
        return;
    }

    // 2. Read the file line by line
    const fileStream = fs.createReadStream(prBodyPath);
    const rl = readline.createInterface({
        input: fileStream,
        crlfDelay: Infinity
    });

    for await (const line of rl) {
        // Look for the pattern: Apex::[TestClass1 TestClass2]::Apex
        if (line.includes('Apex::[') && line.includes(']::Apex')) {
            const startIndex = line.indexOf('Apex::[') + 7;
            const endIndex = line.lastIndexOf(']::Apex');
            const rawTests = line.substring(startIndex, endIndex);

            // Split by whitespace or commas
            const cleanedTests = rawTests
                .split(/[\s,]+/) 
                .map(t => t.trim())
                // Remove empty strings to prevent "--tests --tests" errors
                .filter(t => t.length > 0);

            foundTests.push(...cleanedTests);
        }
    }

    // 3. De-duplicate tests (just in case they are mentioned twice)
    const uniqueTests = [...new Set(foundTests)];

    // 4. Format for the CLI
    // Result: "--tests TestA --tests TestB"
    let finalOutput;
    if (uniqueTests.length > 0) {
        finalOutput = uniqueTests.map(test => `--tests ${test}`).join(' ');
    } else {
        finalOutput = 'all';
    }

    // 5. Save to file
    await fs.promises.writeFile(testsFile, finalOutput);
    
    console.log('--- Extraction Complete ---');
    console.log(`Tests found: ${uniqueTests.length}`);
    console.log(`Formatted output: ${finalOutput}`);
}

// Execute the function
extractTests().catch(err => {
    console.error('Error parsing tests:', err);
    process.exit(1);
});