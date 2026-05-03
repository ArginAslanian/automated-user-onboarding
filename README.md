# 🚀 Serverless User Onboarding Pipeline

A zero-touch, cloud-native automation that provisions Entra ID accounts, assigns dynamic security groups and Microsoft 365 licenses, and securely emails a Temporary Access Pass (TAP) to the hiring manager triggered by a Microsoft Form submission.

## 🏗️ Architecture
**Microsoft Forms** (Intake) ➔ **Azure Logic Apps** (Orchestrator) ➔ **Azure Automation** (Engine) ➔ **Microsoft Graph API** (Execution)

## 🔥 Why This is a Game-Changer for IT!

Let's face it: manual onboarding is tedious, prone to human error, and eats up massive amounts of IT Help Desk time. This serverless architecture completely revolutionizes how we handle new hires! 

Here is why automating this pipeline is an absolute massive win for the team:

* **⚡ Zero-Touch Provisioning:** The moment HR hits "Submit" on their Microsoft Form, the cloud takes over. No more copy-pasting names into Active Directory, no more delayed IT tickets, and absolutely zero manual intervention required from our engineers! It happens in *seconds*, not hours.
* **🎯 Eradicate Human Error:** Forget about typos in email addresses, missing E3/E5 licenses, or accidentally dropping a user into the wrong department group. The dynamic mapping table ensures every single configuration is flawlessly applied 100% of the time.
* **🎉 Day-One Productivity Guaranteed:** We are completely eliminating the dreaded "My new hire can't log in" Monday morning crisis! Managers automatically receive a secure Temporary Access Pass (TAP) via email before the employee even steps foot in the building.
* **🛡️ Next-Gen Security (Zero Trust):** This isn't just fast; it is incredibly secure. We are leveraging **Passwordless Day-One** authentication—no initial passwords are ever created, shared over email, or written on sticky notes. Plus, the entire backend runs on a System-Assigned Managed Identity, meaning there are zero hardcoded admin credentials anywhere in our code!
* **⏳ Reclaim Your Time:** By automating the most repetitive task in IT, our Systems Administrators and Support Engineers get to focus their talent on high-value projects, infrastructure improvements, and actual engineering work instead of mundane ticket-bashing!

## 🛠️ Let's Build It (Quick Setup)

1.  **The Engine:** Spin up an Azure Automation Account with a System-Assigned Managed Identity. Import the Microsoft Graph API modules (v5.1).
2.  **The Keys:** Grant that Managed Identity the precise permissions it needs (`User.ReadWrite.All`, `GroupMember.ReadWrite.All`, `UserAuthenticationMethod.ReadWrite.All`, `Organization.Read.All`). 
3.  **The Brain:** Deploy the provided `user-onboarding.ps1` script as a PowerShell runbook. Update your `$Domain` and match your `$DepartmentGroupMap` to your actual Entra ID groups.
4.  **The Orchestrator:** Connect your Microsoft Form to a Consumption Logic App. Map the form answers directly into the Runbook, and set up the final step to securely email the generated TAP code straight to the hiring manager. *See screenshots for reference!*
5.  **Hit Go:** Submit a test form and watch the cloud do the heavy lifting! 🚀

<img width="1277" height="604" alt="Confirmation Email with TAP Code" src="https://github.com/user-attachments/assets/0f22959a-881a-4bb3-9d32-241c1a42a7eb" />
