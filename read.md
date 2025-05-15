-OpportunityContractorController


public with sharing class OpportunityContractorController {
    @AuraEnabled(cacheable=true)
    public static List<ContractorChangeWrapper> getContractorChanges(Id opportunityId) {
        List<ContractorChangeWrapper> wrappers = new List<ContractorChangeWrapper>();
        
        // Query Contractor Changes for the Opportunity
        List<Contractor_Changes__c> contractorChanges = [
            SELECT Id, Contractor__r.Name, Cost__c, Budget_Percentage__c, Change_Type__c
            FROM Contractor_Changes__c
            WHERE Opportunity__c = :opportunityId
            ORDER BY Contractor__r.Name
        ];
        
        // Create wrappers
        for (Contractor_Changes__c change : contractorChanges) {
            ContractorChangeWrapper wrapper = new ContractorChangeWrapper();
            wrapper.id = change.Id;
            wrapper.name = change.Contractor__r.Name;
            wrapper.cost = change.Cost__c;
            wrapper.budgetPercentage = change.Budget_Percentage__c;
            wrapper.changeType = change.Change_Type__c;
            wrappers.add(wrapper);
        }
        
        return wrappers;
    }

    @AuraEnabled(cacheable=true)
    public static Decimal getOpportunityAmount(Id opportunityId) {
        Opportunity opp = [
            SELECT Amount
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];
        return opp.Amount;
    }

    @AuraEnabled
    public static void updateMultipleContractorChanges(List<ContractorChangeWrapper> changes, Id opportunityId) {
        if (changes == null || changes.isEmpty()) {
            throw new AuraHandledException('No changes provided for update');
        }

        // Get opportunity amount for validation
        Decimal opportunityAmount = getOpportunityAmount(opportunityId);
        
        // Get all contractor changes for the opportunity
        List<Contractor_Changes__c> allCurrentChanges = [
            SELECT Id, Cost__c
            FROM Contractor_Changes__c
            WHERE Opportunity__c = :opportunityId
        ];
        
        // Create map of current changes
        Map<Id, Contractor_Changes__c> currentChangesMap = new Map<Id, Contractor_Changes__c>(allCurrentChanges);
        
        // Calculate total cost including all changes
        Decimal totalCost = 0;
        Map<Id, Contractor_Changes__c> updatesMap = new Map<Id, Contractor_Changes__c>();
        
        // First pass: prepare updates and calculate total
        for (ContractorChangeWrapper change : changes) {
            Contractor_Changes__c updateChange = new Contractor_Changes__c(
                Id = change.id,
                Cost__c = change.cost,
                Change_Type__c = 'Reallocation',
                Budget_Percentage__c = (change.cost / opportunityAmount) * 100
            );
            updatesMap.put(change.id, updateChange);
            totalCost += change.cost;
        }
        
        // Add costs from unchanged records
        for (Contractor_Changes__c current : allCurrentChanges) {
            if (!updatesMap.containsKey(current.Id)) {
                totalCost += current.Cost__c;
            }
        }
        
        // Validate total cost against opportunity amount
        if (Math.abs(totalCost - opportunityAmount) > 0.01) {
            throw new AuraHandledException('Total Contractor cost ($' + totalCost.setScale(2) + 
                ') must equal the Opportunity Amount ($' + opportunityAmount.setScale(2) + ')');
        }
        
        // Perform update
        if (!updatesMap.isEmpty()) {
            update updatesMap.values();
        }
    }

    // Keep the original single update method for backward compatibility
    @AuraEnabled
    public static void updateContractorChange(Id contractorChangeId, Decimal newCost, Decimal opportunityAmount) {
        List<ContractorChangeWrapper> changes = new List<ContractorChangeWrapper>();
        ContractorChangeWrapper wrapper = new ContractorChangeWrapper();
        wrapper.id = contractorChangeId;
        wrapper.cost = newCost;
        
        // Get the opportunity ID from the contractor change
        Contractor_Changes__c change = [SELECT Opportunity__c FROM Contractor_Changes__c WHERE Id = :contractorChangeId];
        updateMultipleContractorChanges(changes, change.Opportunity__c);
    }

    // Wrapper class for UI data
    public class ContractorChangeWrapper {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public Decimal cost { get; set; }
        @AuraEnabled public Decimal budgetPercentage { get; set; }
        @AuraEnabled public String changeType { get; set; }
    }
}






-ContractorChanges LWC

-HTML

<template>
    <lightning-card title="Contractor Changes" icon-name="standard:contract">
        <div class="slds-m-around_medium">
            <!-- Error Handling -->
            <template if:true={error}>
                <div class="slds-text-color_error">
                    An error occurred: {error.body.message}
                </div>
            </template>
 
 
            <!-- Contractor Changes Table -->
            <template if:true={hasContractorChanges}>
                <lightning-datatable
                    key-field="id"
                    data={contractorChanges}
                    columns={columns}
                    onsave={handleSave}
                    draft-values={draftValues}>
                </lightning-datatable>
            </template>
 
 
            <!-- No Records Found -->
            <template if:false={hasContractorChanges}>
                <div class="slds-text-align_center slds-m-around_medium">
                    No contractor changes found for this opportunity.
                </div>
            </template>
 
 
            <!-- Totals Section -->
            <div class="slds-m-top_medium slds-grid slds-grid_vertical-align-center slds-gutters">
                <div class="slds-col">
                    <strong>Opportunity Amount:</strong> {formattedOpportunityAmount}
                </div>
                <div class="slds-col">
                    <strong>Total Contractor Cost:</strong> {formattedTotalCost}
                </div>
            </div>
        </div>
    </lightning-card>
 </template>


-JS

// Imports
import { LightningElement, api, wire, track } from 'lwc';
import getContractorChanges from '@salesforce/apex/OpportunityContractorController.getContractorChanges';
import getOpportunityAmount from '@salesforce/apex/OpportunityContractorController.getOpportunityAmount';
import updateMultipleContractorChanges from '@salesforce/apex/OpportunityContractorController.updateMultipleContractorChanges';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';


// Main Class
export default class ContractorChanges extends LightningElement {
   @api recordId; // The Opportunity record ID
   @track draftValues = []; // Track draft values for inline editing
   contractorChanges; // Holds the list of Contractor Changes
   opportunityAmount; // Holds the Opportunity Amount
   error;
   wiredContractorChangesResult; // For refreshApex


   // Columns for the datatable
   columns = [
       { label: 'Name', fieldName: 'name', type: 'text' },
       {
           label: 'Cost',
           fieldName: 'cost',
           type: 'currency',
           editable: true,
           typeAttributes: {
               minimumFractionDigits: 2,
               maximumFractionDigits: 2
           }
       },
       {
           label: 'Budget Percentage',
           fieldName: 'budgetPercentage',
           type: 'percent',
           typeAttributes: {
               minimumFractionDigits: 2,
               maximumFractionDigits: 2
           }
       },
       { label: 'Change Type', fieldName: 'changeType', type: 'text' }
   ];


   // Fetch Contractor Changes
   @wire(getContractorChanges, { opportunityId: '$recordId' })
   wiredContractorChanges(result) {
       this.wiredContractorChangesResult = result;
       if (result.data) {
           this.contractorChanges = result.data;
           this.error = undefined;
       } else if (result.error) {
           this.error = result.error;
           this.contractorChanges = undefined;
       }
   }


   // Fetch Opportunity Amount
   @wire(getOpportunityAmount, { opportunityId: '$recordId' })
   wiredOpportunityAmount({ error, data }) {
       if (data) {
           this.opportunityAmount = data;
           this.error = undefined;
       } else if (error) {
           this.error = error;
           this.opportunityAmount = undefined;
       }
   }


   // Handle save event
   handleSave(event) {
       const draftValues = event.detail.draftValues;
      
       // Create updated records based on draft values
       const updatedChanges = draftValues.map(draft => {
           const original = this.contractorChanges.find(change => change.id === draft.id);
           return {
               id: draft.id,
               name: original.name,
               cost: parseFloat(draft.cost),
               changeType: 'Reallocation',
               budgetPercentage: (parseFloat(draft.cost) / this.opportunityAmount) * 100
           };
       });


       // Call apex method to update all changes at once
       updateMultipleContractorChanges({
           changes: updatedChanges,
           opportunityId: this.recordId
       })
       .then(() => {
           // Show success message
           this.dispatchEvent(
               new ShowToastEvent({
                   title: 'Success',
                   message: 'Changes saved successfully',
                   variant: 'success'
               })
           );
          
           this.draftValues = []; // Clear all draft values
           return refreshApex(this.wiredContractorChangesResult); // Refresh the data
       })
       .catch(error => {
           // Show error message
           this.dispatchEvent(
               new ShowToastEvent({
                   title: 'Error',
                   message: error.body.message,
                   variant: 'error'
               })
           );
       });
   }


   // Helper to calculate total cost
   get totalCost() {
       if (!this.contractorChanges) return 0;
       return this.contractorChanges.reduce((total, change) => total + (change.cost || 0), 0);
   }


   // Helper to check if there are Contractor Changes
   get hasContractorChanges() {
       return this.contractorChanges && this.contractorChanges.length > 0;
   }


   // Helper to format the Opportunity Amount
   get formattedOpportunityAmount() {
       return this.opportunityAmount ? `$${this.opportunityAmount.toFixed(2)}` : '';
   }


   // Helper to format the Total Cost
   get formattedTotalCost() {
       return `$${this.totalCost.toFixed(2)}`;
   }
}

-JS.XML

<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
   <apiVersion>57.0</apiVersion>
   <isExposed>true</isExposed>
   <targets>
       <target>lightning__RecordPage</target>
   </targets>
   <targetConfigs>
       <targetConfig targets="lightning__RecordPage">
           <objects>
               <object>Opportunity</object>
           </objects>
       </targetConfig>
   </targetConfigs>
</LightningComponentBundle>



