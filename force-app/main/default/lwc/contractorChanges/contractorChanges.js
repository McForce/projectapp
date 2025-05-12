import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getContractorChanges from '@salesforce/apex/OpportunityContractorController.getContractorChanges';
import getOpportunityAmount from '@salesforce/apex/OpportunityContractorController.getOpportunityAmount';
import updateContractorChanges from '@salesforce/apex/OpportunityContractorController.updateContractorChanges';

const COLUMNS = [
    { label: 'Contractor', fieldName: 'contractorName', type: 'text', editable: false },
    { label: 'Cost', fieldName: 'cost', type: 'currency', editable: true },
    { label: 'Budget %', fieldName: 'budgetPercentage', type: 'percent-fixed', editable: false },
    { label: 'Change Type', fieldName: 'changeType', type: 'text', editable: false }
];

export default class ContractorChanges extends LightningElement {
    @api recordId; // Opportunity Id
    @track data = [];
    @track columns = COLUMNS;
    @track opportunityAmount;
    @track isLoading = true;
    @track draftValues = [];
    
    connectedCallback() {
        this.loadData();
    }
    
    async loadData() {
        try {
            this.isLoading = true;
            const [changes, amount] = await Promise.all([
                getContractorChanges({ opportunityId: this.recordId }),
                getOpportunityAmount({ opportunityId: this.recordId })
            ]);
            
            this.data = changes;
            this.opportunityAmount = amount;
        } catch (error) {
            this.showToast('Error', error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }
    
    get totalCost() {
        return this.data.reduce((sum, item) => sum + (item.cost || 0), 0);
    }
    
    get isSaveDisabled() {
        return this.totalCost !== this.opportunityAmount;
    }
    
    handleSave(event) {
        const draftValues = event.detail.draftValues;
        
        // Update the data with draft values
        const updatedData = this.data.map(item => {
            const draft = draftValues.find(d => d.id === item.recordId);
            return draft ? { ...item, ...draft } : item;
        });
        
        this.isLoading = true;
        
        updateContractorChanges({ 
            changes: updatedData,
            opportunityId: this.recordId
        })
            .then(() => {
                this.showToast('Success', 'Changes saved successfully', 'success');
                this.draftValues = [];
                return this.loadData();
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}