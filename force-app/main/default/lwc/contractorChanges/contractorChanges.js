import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getContractorChanges from '@salesforce/apex/OpportunityContractorController.getContractorChanges';
import updateContractorChanges from '@salesforce/apex/OpportunityContractorController.updateMultipleContractorChanges';
import getOpportunityAmount from '@salesforce/apex/OpportunityContractorController.getOpportunityAmount';

const COLUMNS = [
    { label: 'Contractor Name', fieldName: 'contractorName', type: 'text', editable: false },
    { label: 'Cost', fieldName: 'Cost__c', type: 'currency', editable: true },
    { label: 'Budget Percentage', fieldName: 'Budget_Percentage__c', type: 'percent', editable: false },
    { label: 'Change Type', fieldName: 'Change_Type__c', type: 'text', editable: false }
];

export default class ContractorChanges extends LightningElement {
    @api recordId; // Opportunity Id
    @track data = [];
    @track columns = COLUMNS;
    @track totalCost = 0;
    @track opportunityAmount = 0;
    @track isLoading = true;
    
    wiredContractorChangesResult;
    draftValues = [];

    @wire(getContractorChanges, { opportunityId: '$recordId' })
    wiredContractorChanges(result) {
        this.wiredContractorChangesResult = result;
        if (result.data) {
            this.data = result.data;
            this.calculateTotals();
            this.isLoading = false;
        } else if (result.error) {
            this.handleError(result.error);
        }
    }

    @wire(getOpportunityAmount, { opportunityId: '$recordId' })
    wiredOpportunityAmount({ error, data }) {
        if (data) {
            this.opportunityAmount = data;
        } else if (error) {
            this.handleError(error);
        }
    }

    handleSave(event) {
        this.isLoading = true;
        const records = event.detail.draftValues;

        updateContractorChanges({ contractorChanges: records })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Contractor Changes updated',
                        variant: 'success'
                    })
                );
                this.draftValues = [];
                return refreshApex(this.wiredContractorChangesResult);
            })
            .catch(error => {
                this.handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    calculateTotals() {
        this.totalCost = this.data.reduce((total, row) => total + (row.Cost__c || 0), 0);
    }

    handleError(error) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: error.body?.message || 'Unknown error occurred',
                variant: 'error'
            })
        );
        this.isLoading = false;
    }
}