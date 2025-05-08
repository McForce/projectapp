import { createElement } from 'lwc/testUtils';
import ContractorChanges from 'c/contractorChanges';
import getContractorChanges from '@salesforce/apex/ContractorChangesController.getContractorChanges';

// Mocking the Apex method
jest.mock('@salesforce/apex/ContractorChangesController.getContractorChanges', () => {
    return {
        default: jest.fn()
    };
}, { virtual: true });

describe('c-contractor-changes', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('renders contractor changes data when @wire returns data', async () => {
        // Mock data for the Apex method
        const mockData = [
            {
                Id: '1',
                Name: 'John Doe',
                Cost__c: 500,
                Budget_Percentage__c: 20,
                Change_Type__c: 'Add'
            },
            {
                Id: '2',
                Name: 'Jane Smith',
                Cost__c: 300,
                Budget_Percentage__c: 15,
                Change_Type__c: 'Remove'
            }
        ];

        // Mock the Apex method to return the data
        getContractorChanges.mockResolvedValue(mockData);

        // Create the component
        const element = createElement('c-contractor-changes', {
            is: ContractorChanges
        });
        document.body.appendChild(element);

        // Wait for any asynchronous DOM updates
        await Promise.resolve();

        // Verify the table rows are rendered
        const rows = element.shadowRoot.querySelectorAll('tbody tr');
        expect(rows.length).toBe(mockData.length);

        // Verify the first row's data
        const firstRow = rows[0].children;
        expect(firstRow[0].textContent).toBe(mockData[0].Name);
        expect(firstRow[1].textContent).toBe(mockData[0].Cost__c.toString());
        expect(firstRow[2].textContent).toBe(mockData[0].Budget_Percentage__c.toString());
        expect(firstRow[3].textContent).toBe(mockData[0].Change_Type__c);
    });

    it('renders error when @wire returns an error', async () => {
        // Mock the Apex method to return an error
        getContractorChanges.mockRejectedValue(new Error('Sample error'));

        // Create the component
        const element = createElement('c-contractor-changes', {
            is: ContractorChanges
        });
        document.body.appendChild(element);

        // Wait for any asynchronous DOM updates
        await Promise.resolve();

        // Verify the error message is rendered
        const errorElement = element.shadowRoot.querySelector('.slds-text-color_error');
        expect(errorElement).not.toBeNull();
        expect(errorElement.textContent).toBe('Error: Sample error');
    });
});