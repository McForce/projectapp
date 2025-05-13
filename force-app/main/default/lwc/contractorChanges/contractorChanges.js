import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getContractorChanges from '@salesforce/apex/OpportunityContractorController.getContractorChanges';
import updateContractorChanges from '@salesforce/apex/OpportunityContractorController.updateContractorChanges';

// Column definitions for the datatable
const COLUMNS = [
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
        editable: true,
        typeAttributes: { 
            currencyCode: 'USD',
            step: '0.01'
        },
        sortable: true,
        cellAttributes: { 
            alignment: 'left' 
        }
    },
    { 
        label: 'Budget %', 
        fieldName: 'budgetPercentage', 
        type: 'percent',
        typeAttributes: { 
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        },
        sortable: true,
        cellAttributes: { 
            alignment: 'left' 
        }
    },
    { 
        label: 'Change Type', 
        fieldName: 'changeType', 
        type: 'text',
        sortable: true
    }
];

export default class ContractorChanges extends LightningElement {
    // Public properties
    @api recordId; // Opportunity Id from record page

    // Private reactive properties
    @track data = [];
    @track columns = COLUMNS;
    @track draftValues = [];
    @track error;
    @track isLoading = false;
    @track sortBy;
    @track sortDirection;

    // Private non-reactive properties
    opportunityAmount = 0;
    totalCost = 0;
    wiredContractorResult;

    // Lifecycle hooks
    connectedCallback() {
        this.loadContractorChanges();
    }

    // Data loading methods
    async loadContractorChanges() {
        if (!this.recordId) return;

        this.isLoading = true;
        this.error = undefined;

        try {
            const result = await getContractorChanges({ 
                opportunityId: this.recordId 
            });
            
            this.processContractorData(result);
        } catch (error) {
            this.handleError(error);
        } finally {
            this.isLoading = false;
        }
    }

    processContractorData(result) {
        this.data = [...result.contractorChanges];
        this.opportunityAmount = result.opportunityAmount;
        this.totalCost = result.totalCost;
        
        if (this.sortBy && this.sortDirection) {
            this.sortData(this.sortBy, this.sortDirection);
        }
    }

    // Event handlers
    handleSave(event) {
        this.isLoading = true;
        const draftValues = event.detail.draftValues;

        // Prepare updated records
        const updatedRecords = this.prepareUpdatedRecords(draftValues);

        // Update records
        updateContractorChanges({ 
            changes: updatedRecords,
            opportunityId: this.recordId 
        })
            .then(() => {
                this.showToast('Success', 'Contractor changes updated successfully', 'success');
                this.draftValues = [];
                return this.loadContractorChanges();
            })
            .catch(error => this.handleError(error))
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleSort(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    handleRefresh() {
        this.loadContractorChanges();
    }

    // Utility methods
    prepareUpdatedRecords(draftValues) {
        return this.data.map(record => {
            const draft = draftValues.find(draft => draft.id === record.recordId);
            return {
                ...record,
                cost: draft ? parseFloat(draft.cost) : record.cost
            };
        });
    }

    sortData(fieldName, direction) {
        const parseData = JSON.parse(JSON.stringify(this.data));

        const reverse = direction === 'asc' ? 1 : -1;

        parseData.sort((a, b) => {
            let valueA = a[fieldName] || '';
            let valueB = b[fieldName] || '';

            // Handle number fields
            if (fieldName === 'cost' || fieldName === 'budgetPercentage') {
                valueA = parseFloat(valueA) || 0;
                valueB = parseFloat(valueB) || 0;
            } else {
                // Handle string fields
                valueA = valueA.toLowerCase();
                valueB = valueB.toLowerCase();
            }

            return valueA > valueB ? 1 * reverse : -1 * reverse;
        });

        this.data = parseData;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: 'dismissable'
            })
        );
    }

    handleError(error) {
        let errorMessage = 'Unknown error';
        
        if (typeof error === 'string') {
            errorMessage = error;
        } else if (error.body?.message) {
            errorMessage = error.body.message;
        } else if (error.message) {
            errorMessage = error.message;
        }

        this.error = errorMessage;
        this.showToast('Error', errorMessage, 'error');
    }

    // Getter methods for template
    get hasData() {
        return this.data && this.data.length > 0;
    }

    get formattedOpportunityAmount() {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD'
        }).format(this.opportunityAmount);
    }

    get formattedTotalCost() {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD'
        }).format(this.totalCost);
    }

    get isBalanced() {
        return Math.abs(this.totalCost - this.opportunityAmount) < 0.01;
    }

    get totalCostVariance() {
        return Math.abs(this.totalCost - this.opportunityAmount);
    }

    get statusVariant() {
        return this.isBalanced ? 'success' : 'warning';
    }

    get statusIcon() {
        return this.isBalanced ? 'utility:check' : 'utility:warning';
    }
}