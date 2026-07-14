import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getDynamicList from '@salesforce/apex/PortalDynamicListController.getDynamicList';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import REFRESH_CHANNEL from '@salesforce/messageChannel/RefreshChannel__c';

export default class PortalDynamicListView extends NavigationMixin(LightningElement) {
    @api objectApiName;
    @api listTitle = 'RECORDS';
    @api fieldApiNames = 'Name';
    @api filterClause;
    @api recordLimit;
    @api viewAllUrl;
    @api columnLimit;
    @api sortConfig;
    @api searchField;
    @api linkField;
    @api recordUrlPattern = '/s/detail/{recordId}';
    @api listPagePath;

    @track data = [];
    @track columns = [];
    @track error;

    allData = [];
    fieldLabels = {};

    @track sortedBy;
    @track sortedDirection;

    searchTerm = '';

    enableInfiniteLoading = false;
    isLoading = false;

    // 1. Subscription tracking property & Context wiring
    subscription = null;

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        if (!this.objectApiName) {
            this.error = { body: { message: 'Object API Name is required. Set it in Experience Builder.' } };
            return;
        }

        const isListPage = this.listPagePath
            ? window.location.pathname.endsWith(this.listPagePath)
            : false;

        if ((!this.recordLimit || this.recordLimit === 0) && isListPage) {
            this.enableInfiniteLoading = true;
        } else {
            this.enableInfiniteLoading = false;
        }

        this.loadData();
    }

    renderedCallback() {
        if (this.messageContext && !this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                REFRESH_CHANNEL,
                () => this.handleRefresh()
            );
        }
    }

    disconnectedCallback() {
        if (this.subscription) {
            unsubscribe(this.subscription);
            this.subscription = null;
        }
    }

    handleRefresh() {
        this.isLoading = false;
        this.allData = [];
        this.data = [];
        this.searchTerm = '';

        const isListPage = this.listPagePath
            ? window.location.pathname.endsWith(this.listPagePath)
            : false;
        this.enableInfiniteLoading = (!this.recordLimit || this.recordLimit === 0) && isListPage;

        this.loadData();
    }

    get computedFieldNames() {
        let fields = this.fieldApiNames;
        if (this.searchField) {
            const searchFields = this.searchField.split(',');
            searchFields.forEach(sField => {
                const cleanField = sField.trim();
                if (cleanField && !fields.includes(cleanField)) {
                    fields += ',' + cleanField;
                }
            });
        }
        return fields;
    }

    get computedLinkField() {
        if (this.linkField) {
            return this.linkField.trim();
        }
        const firstField = this.fieldApiNames.replace(/\s/g, '').split(',')[0];
        return firstField || 'Name';
    }

    get listContainerStyle() {
        return this.enableInfiniteLoading ? 'height: 400px;' : '';
    }

    loadData(event) {
        const currentOffset = this.allData.length;

        if (this.isLoading) {
            return;
        }
        this.isLoading = true;

        const offsetToSend = this.enableInfiniteLoading ? currentOffset : 0;
        const limitToSend = this.enableInfiniteLoading ? 0 : this.recordLimit;

        getDynamicList({
            objectApiName: this.objectApiName,
            fieldNames: this.computedFieldNames,
            filterClause: this.filterClause,
            sortExpression: this.sortConfig,
            limitSize: this.enableInfiniteLoading ? 0 : limitToSend,
            offset: offsetToSend
        })
            .then(result => {
                const newRecords = result.records.map(row => this.processRow(row));
                this.fieldLabels = result.labels;

                if (this.columns.length === 0) {
                    this.generateColumns();
                    this.setInitialSortState();
                }

                if (offsetToSend === 0) {
                    this.allData = newRecords;
                } else {
                    const existingIds = new Set(this.allData.map(row => row.Id));
                    const uniqueNewRecords = newRecords.filter(row => !existingIds.has(row.Id));
                    this.allData = [...this.allData, ...uniqueNewRecords];
                }

                const filteredData = this.searchTerm ? this.applySearchFilter(this.allData) : this.allData;
                this.data = this.updateRowNumbers(filteredData);

                if (event) {
                    event.target.isLoading = false;
                }

                if (this.enableInfiniteLoading && newRecords.length < 50) {
                    this.enableInfiniteLoading = false;
                }

                this.error = undefined;
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error loading data', error);
                this.error = error;
                this.isLoading = false;
            });
    }

    updateRowNumbers(dataToNumber) {
        return dataToNumber.map((row, index) => ({ ...row, rowNumber: index + 1 }));
    }

    handleLoadMore(event) {
        if (!this.enableInfiniteLoading) {
            return;
        }
        this.loadData(event);
    }

    get showComponent() {
        return true;
    }

    get errorMessage() {
        if (!this.error) {
            return null;
        }
        if (this.error.body?.message) {
            return this.error.body.message;
        }
        if (this.error.message) {
            return this.error.message;
        }
        return 'An error occurred while loading records.';
    }

    get hasVisibleRows() {
        return this.data && this.data.length > 0;
    }

    get isListPage() {
        return this.listPagePath
            ? window.location.pathname.endsWith(this.listPagePath)
            : false;
    }

    get showViewAll() {
        return !this.isListPage && this.allData.length > 0 && this.viewAllUrl;
    }

    get showSearchBar() {
        return this.isListPage && this.searchField;
    }

    handleSearch(event) {
        this.searchTerm = event.target.value ? event.target.value.toLowerCase().trim() : '';

        const resultData = !this.searchTerm
            ? this.allData
            : this.applySearchFilter(this.allData);

        this.data = this.updateRowNumbers(resultData);
    }

    applySearchFilter(sourceData) {
        if (!this.searchField) {
            return sourceData;
        }
        const searchFields = this.searchField.split(',').map(f => f.trim());

        return sourceData.filter(row =>
            searchFields.some(field => {
                const cellValue = this.getCellValue(row, field);
                if (cellValue !== null && cellValue !== undefined) {
                    return String(cellValue).toLowerCase().includes(this.searchTerm);
                }
                return false;
            })
        );
    }

    getCellValue(row, fieldName) {
        if (!row || !fieldName) {
            return null;
        }
        if (row[fieldName] !== undefined) {
            return row[fieldName];
        }

        const key = Object.keys(row).find(k => k.toLowerCase() === fieldName.toLowerCase());
        return key ? row[key] : null;
    }

    setInitialSortState() {
        if (!this.sortConfig) {
            return;
        }
        const parts = this.sortConfig.trim().split(/\s+/);
        const field = parts[0];
        const dir = parts.length > 1 ? parts[1].toLowerCase() : 'asc';
        this.sortedDirection = dir;
        this.sortedBy = field === this.computedLinkField ? 'recordLink' : field;
    }

    handleSort(event) {
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        const fieldToSort = this.sortedBy === 'recordLink' ? this.computedLinkField : this.sortedBy;
        this.sortData(fieldToSort, this.sortedDirection);
    }

    sortData(fieldname, direction) {
        const parseData = data => (data && typeof data === 'string' ? data.toLowerCase() : data);
        const isReverse = direction === 'asc' ? 1 : -1;

        const sortedData = [...this.data].sort((a, b) => {
            let aVal = parseData(a[fieldname]);
            let bVal = parseData(b[fieldname]);

            if (aVal === undefined) {
                aVal = parseData(this.getCellValue(a, fieldname));
            }
            if (bVal === undefined) {
                bVal = parseData(this.getCellValue(b, fieldname));
            }

            if (aVal === undefined || aVal === null) {
                return 1;
            }
            if (bVal === undefined || bVal === null) {
                return -1;
            }
            return isReverse * ((aVal > bVal) - (bVal > aVal));
        });

        this.data = this.updateRowNumbers(sortedData);
    }

    generateColumns() {
        if (!this.fieldApiNames) {
            return;
        }
        let fields = this.fieldApiNames.replace(/\s/g, '').split(',');

        if (this.columnLimit && this.columnLimit > 0) {
            fields = fields.slice(0, this.columnLimit);
        }

        const linkField = this.computedLinkField;

        const dynamicColumns = fields.map(field => {
            const columnLabel = this.fieldLabels[field] || this.formatLabel(field);
            if (field === linkField) {
                return {
                    label: columnLabel,
                    fieldName: 'recordLink',
                    type: 'url',
                    typeAttributes: { label: { fieldName: linkField }, target: '_self' },
                    sortable: true
                };
            }
            if (field.includes('Amount') || field.includes('Price')) {
                return {
                    label: columnLabel,
                    fieldName: field,
                    type: 'currency',
                    sortable: true,
                    cellAttributes: { alignment: 'left' }
                };
            }
            if (field.includes('Date')) {
                return { label: columnLabel, fieldName: field, type: 'date', sortable: true };
            }
            return { label: columnLabel, fieldName: field, type: 'text', sortable: true };
        });

        this.columns = [
            {
                label: '',
                fieldName: 'rowNumber',
                type: 'number',
                initialWidth: 50,
                cellAttributes: { alignment: 'center' },
                sortable: false
            },
            ...dynamicColumns
        ];
    }

    formatLabel(fieldApiName) {
        let label = fieldApiName.replace(/\./g, ' ');
        label = label.replace(/([A-Z])/g, ' $1').trim();
        return label;
    }

    processRow(row) {
        const newRow = this.flattenData(row);
        const pattern = this.recordUrlPattern || '/s/detail/{recordId}';
        newRow.recordLink = pattern.replace('{recordId}', row.Id);
        return newRow;
    }

    flattenData(row) {
        const newRow = {};
        const recurse = (currentRow, propName) => {
            for (const key in currentRow) {
                if (Object.prototype.hasOwnProperty.call(currentRow, key)) {
                    const newKey = propName ? `${propName}.${key}` : key;
                    if (typeof currentRow[key] === 'object' && currentRow[key] !== null) {
                        recurse(currentRow[key], newKey);
                    } else {
                        newRow[newKey] = currentRow[key];
                    }
                }
            }
        };
        recurse(row, '');
        return newRow;
    }

    navigateToViewAll() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url: this.viewAllUrl }
        });
    }
}