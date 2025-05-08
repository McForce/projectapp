import { LightningElement, api, wire } from 'lwc';
import getContractorBillings from '@salesforce/apex/ProjectContractorBillingController.getContractorBillings';
import { refreshApex } from '@salesforce/apex';

export default class ContractorBillingList extends LightningElement {
    @api recordId; // Project Id from record page
    wiredBillingsResult;
    billings;
    error;
    
    columns = [
        { 
            label: 'Contractor Name', 
            fieldName: 'contractorName', 
            type: 'text',
            sortable: true 
        },
        { 
            label: 'Contact', 
            fieldName: 'contactName', 
            type: 'text',
            sortable: true 
        },
        { 
            label: 'Budget %', 
            fieldName: 'budgetPercentage', 
            type: 'percent', 
            sortable: true,
            cellAttributes: { 
                alignment: 'left' 
            }
        },
        { 
            label: 'Cost', 
            fieldName: 'cost', 
            type: 'currency',
            sortable: true,
            cellAttributes: { 
                alignment: 'left' 
            }
        },
        { 
            label: 'Last Billed Date', 
            fieldName: 'lastBilledDate', 
            type: 'date',
            typeAttributes: {
                year: 'numeric',
                month: 'long',
                day: 'numeric'
            },
            sortable: true 
        }
    ];

    @wire(getContractorBillings, { projectId: '$recordId' })
    wiredBillings(result) {
        this.wiredBillingsResult = result;
        if (result.data) {
            this.billings = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.billings = undefined;
            console.error('Error:', result.error);
        }
    }

    handleRefresh() {
        refreshApex(this.wiredBillingsResult);
    }
}