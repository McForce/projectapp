import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getContractorChanges from '@salesforce/apex/OpportunityContractorChangeController.getContractorChanges';
import updateContractorChanges from '@salesforce/apex/OpportunityContractorChangeController.updateContractorChanges';

const columns = [
    { 
        label: 'Contractor', 
        fieldName: 'contractorName', 
        type: 'text',
        sortable: true 
    },
    { 
        label: 'Cost', 
        fieldName: 'cost', 
        type: 'currency',
        typeAttributes: { currencyCode: 'USD' },
        editable: true,
        sortable: true 
    },
    { 
        label: 'Budget %', 
        fieldName: 'budgetPercentage', 
        type: 'percent',
        typeAttributes: { 
            minimumFractionDigits: 2,
            maximumFractionDigits: 2 
        },
        sortable: true 
    }
];

export default class OpportunityContractorChanges extends LightningElement {
    @api recordId;
    @track data;
    @track draftValues = [];
    @track totalCost = 0;
    @track opportunityAmount = 0;
    
    columns = columns;
    error;
    wiredResult;
    
    @wire(getContractorChanges, { opportunityId: '$recordId' })
    wiredContractorChanges(result) {
        this.wiredResult = result;
        if (result.data) {
            this.data = JSON.parse(JSON.stringify(result.data.changes));
            this.totalCost = result.data.totalCost;
            this.opportunityAmount = result.data.opportunityAmount;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.data = undefined;
            this.showToast('Error', result.error.message, 'error');
        }
    }
    
    handleSave(event) {
        const draftValues = event.detail.draftValues;
        console.log('Draft values received:', JSON.stringify(draftValues));
        
        // Update the data with draft values
        let updatedData = JSON.parse(JSON.stringify(this.data));
        let newTotalCost = 0;
        
        updatedData.forEach(record => {
            const draftValue = draftValues.find(draft => draft.recordId === record.recordId);
            if (draftValue && draftValue.cost !== undefined) {
                console.log('Updating record:', record.recordId, 'with cost:', draftValue.cost);
                record.cost = parseFloat(draftValue.cost);
                record.isDirty = true;
                record.budgetPercentage = (record.cost / this.opportunityAmount) * 100;
            }
            newTotalCost += record.cost;
        });
        
        console.log('Updated data:', JSON.stringify(updatedData));
        console.log('New total cost:', newTotalCost);
        console.log('Opportunity amount:', this.opportunityAmount);
        
        // Validate total cost
        if (Math.abs(newTotalCost - this.opportunityAmount) > 0.01) {
            const errorMsg = `Total cost (${newTotalCost.toFixed(2)}) must equal opportunity amount (${this.opportunityAmount.toFixed(2)})`;
            console.error(errorMsg);
            this.showToast('Error', errorMsg, 'error');
            return;
        }
        
        // Save changes
        updateContractorChanges({ 
            changes: updatedData, 
            opportunityId: this.recordId 
        })
        .then(() => {
            console.log('Save successful');
            this.showToast('Success', 'Changes saved successfully', 'success');
            this.draftValues = [];
            return refreshApex(this.wiredResult);
        })
        .catch(error => {
            console.error('Save error:', JSON.stringify(error));
            const errorMessage = error.body?.message || error.message || 'An error occurred while saving changes';
            console.error('Error message:', errorMessage);
            this.showToast('Error', errorMessage, 'error');
        });
    }
    
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
    
    get isBalanced() {
        return Math.abs(this.totalCost - this.opportunityAmount) < 0.01;
    }
    
    get footerData() {
        return {
            totalCost: this.totalCost,
            opportunityAmount: this.opportunityAmount,
            difference: this.opportunityAmount - this.totalCost
        };
    }
}