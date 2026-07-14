
# **Gigacomm Retail Salesforce – GitHub Workflow Guide**


## **1. Branch Overview**

| **Branch Name** | **Purpose / Environment** | **URL**
|------------------|---------------------------|-------------------------------------------------|
| **Main** | Production branch – stable, approved code only | https://www.gigacomm.net.au/
| **gcdev** | Development integration branch | https://gigacommnet--gcdev.sandbox.my.site.com/
| **PreProduction** | Deployment before going to production. Can be used for UAT testing | https://gigacommnet--preprod.sandbox.my.site.com/

---

## **2. Salesforce Integration Setup**

### **Step 1: Install Salesforce CLI**
Ensure the Salesforce CLI (SF CLI) tool is installed.  
Refer to the [Salesforce CLI installation guide](https://developer.salesforce.com/tools/sfdxcli).

---

### **Step 2: Login to Salesforce Sandbox**
Use the following command to log in to the Salesforce Env sandbox:

```bash
sf org login web --alias Gigacommnet --instance-url https://gigacommnet--[env].sandbox.my.salesforce.com/
```

This will open a browser window for authentication.

---

### **Step 3: Retrieve Metadata / Files**
Once logged in, retrieve files from the Salesforce org using the command below:

```bash
sf project retrieve start -x manifest/package.xml -o Gigacommnet
```

This command pulls metadata specified in `manifest/package.xml` into your local GitHub workspace.

---

## **3. Development Workflow**

### **Step 1: Create a New Branch**
Start your work by branching off from the **Main** branch:

```bash
git checkout main
git pull origin main
git checkout -b feature/<feature-name>
```

---

### **Step 2: Make Changes**
You can:
- Make updates in your **local file system**, or  
- Modify components directly within the **gcdev Sandbox**, then sync those changes to your branch.

---

### **Step 3: Commit and Push Changes**

```bash
git add .
git commit -m "Description of changes"
git push origin feature/<feature-name>
```

---

### **Step 4: Create a Pull Request (PR)**
Submit a **Pull Request** (PR) to the **gcdev** branch for review.

- The PR should include details about the feature or fix.
- Wait for approval from reviewers or tech leads.

---

### **Step 5: Deploy and Test**
Once approved:
1. **Deploy** the changes to the **gcdev Sandbox**.
2. **Verify** that new features and changes function as expected.

---

### **Step 6: Pre Production Deployment**
After successful testing:
- Create a **PR from Enigma-Dev (or Feature/release branch)** → **PreProd** branch.
- On approval, merge and **deploy to PreProd**.

---

### **Step 7: Production Deployment**
After successful testing:
- Create a **PR from PreProd** → **Main** branch.
- On approval, merge and **deploy to Production**.

### **Step 8: Resync all branches with main**
After successful testing on production:
- Create a **PR from Main** → **PreProd** branch.
- Create a **PR from Main** → **gcdev** branch.

