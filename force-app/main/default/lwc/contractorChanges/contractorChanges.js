import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getContractorChanges from '@salesforce/apex/OpportunityContractorController.getContractorChanges';
import updateContractorChanges from '@salesforce/apex/OpportunityContractorController.updateContractorChanges';

export default class ContractorChanges extends LightningElement {
    @api recordId; // Opportunity Id
    @track data = [];
    @track columns = [
        { label: 'Contractor', fieldName: 'contractorName', type: 'text', editable: false },
        { label: 'Cost', fieldName: 'cost', type: 'currency', editable: true },
        { label: 'Budget %', fieldName: 'budgetPercentage', type: 'percent-fixed', editable: false },
        { label: 'Change Type', fieldName: 'changeType', type: 'text', editable: false }
    ];
    
    @track opportunityAmount = 0;
    @track totalCost = 0;
    @track isLoading = false;
    @track draftValues = [];

    connectedCallback() {
        this.loadContractorChanges();
    }

    async loadContractorChanges() {
        this.isLoading = true;
        try {
            const result = await getContractorChanges({ opportunityId: this.recordId });
            this.data = result.contractorChanges;
            this.opportunityAmount = result.opportunity.Amount;
            this.calculateTotals();
        } catch (error) {
            this.showToast('Error', 'Error loading contractor changes', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleSave(event) {
        this.isLoading = true;
        const records = event.detail.draftValues.slice().map(draftValue => {
            const fields = Object.assign({}, draftValue);
            return { fields };
        });

        updateContractorChanges({ 
            opportunityId: this.recordId, 
            changes: records 
        })
            .then(() => {
                this.showToast('Success', 'Contractor changes updated', 'success');
                this.draftValues = [];
                return this.loadContractorChanges();
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    calculateTotals() {
        this.totalCost = this.data.reduce((total, item) => total + (item.cost || 0), 0);
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
}