// Imports
import { LightningElement, api, wire, track } from 'lwc';
import getContractorChanges from '@salesforce/apex/OpportunityContractorController.getContractorChanges';
import getOpportunityAmount from '@salesforce/apex/OpportunityContractorController.getOpportunityAmount';
import updateContractorChange from '@salesforce/apex/OpportunityContractorController.updateContractorChange';
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
    async handleSave(event) {
        const draftValues = event.detail.draftValues;
        
        try {
            // Process each changed record sequentially to maintain consistency
            for (let draft of draftValues) {
                await updateContractorChange({ 
                    contractorChangeId: draft.id,
                    newCost: parseFloat(draft.cost),
                    opportunityAmount: this.opportunityAmount
                });
            }

            // Show success message
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Changes saved successfully',
                    variant: 'success'
                })
            );
            
            this.draftValues = []; // Clear all draft values
            await refreshApex(this.wiredContractorChangesResult); // Refresh the data
            
        } catch (error) {
            // Show error message
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        }
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