//
//  TableViewController.swift
//  Created by J.Rodden
//

import UIKit

public extension UITableView
{
    #if swift(>=4.2)
    #else
    class var automaticDimension: CGFloat
    { return UITableViewAutomaticDimension }
    #endif
    
    var hideTrailingSeparators: Bool
    {
        get { return tableFooterView != nil }
        set
        {
            tableFooterView = newValue ?
                (tableFooterView ?? UIView()) : nil
        }
    }
    
    public func register(item: TableItem)
    {
        item.cellType.register(forUseIn: self)
    }
    
    public func register(items: [TableItem])
    {
        items.forEach({ self.register(item: $0) })
    }
}

// MARK: -

open class TableViewController : UITableViewController
{
    public typealias Cell = TableItem.Cell
    
    public var tableData: TableData = StandardTableData()
    {
        didSet
        {
            registerEverything()
            if isViewLoaded { tableView.reloadData() }
        }
    }
    
    override open func viewDidLoad()
    {
        super.viewDidLoad()
        registerEverything()
    }
    
    private func registerEverything()
    {
        tableData.forEach(section: { $0.register(forUseIn: tableView) })
    }
    
    // MARK: -
    
    public func insert(item: TableItem,
                       at indexPath: IndexPath = IndexPath(row: 0, section: 0),
                       withAnimation animation: UITableView.RowAnimation = .automatic)
    {
        insert(items: [item], at: [indexPath], withAnimation: animation)
    }
    
    public func insert(items: [TableItem],
                       at indexPaths: [IndexPath] = [IndexPath(row: 0, section: 0)],
                       withAnimation animation: UITableView.RowAnimation = .automatic)
    {
        tableView.beginUpdates()
        defer { tableView.endUpdates() }
        
        var numberOfItemsAdded = 0
        var sectionsToAddToTable = IndexSet()
        
        // this makes no sense, but the tableView
        // barfs on the additions w/o this pre-check
        let _ = tableView.numberOfRows(inSection: 0)
        
        // make sure all cellTypes are registered
        items.forEach({ $0.cellType.register(forUseIn: tableView) })
        
        indexPaths.forEach({
            
            if numberOfItemsAdded < items.count
            {
                numberOfItemsAdded += 1
                if $0.section >= tableView.numberOfSections
                {
                    sectionsToAddToTable.insert($0.section)
                }
                
                tableData.insert(items: [items[numberOfItemsAdded-1]], at: $0)
            }
        })
        
        var addedRows = indexPaths.dropLast(indexPaths.count - numberOfItemsAdded)
        
        if numberOfItemsAdded < items.count, numberOfItemsAdded <= indexPaths.count
        {
            let lastIndexPath = indexPaths[numberOfItemsAdded - 1]
            let addedIndexPath = IndexPath(row: // after lastIndexPath
                lastIndexPath.row + 1, section: lastIndexPath.section)
            let remainingItems = Array(items.suffix(from: numberOfItemsAdded))
            
            addedRows.append(
                contentsOf: (numberOfItemsAdded..<items.count)
                    .map({ IndexPath(row: addedIndexPath.row + $0 - 1,
                                     section: addedIndexPath.section) }))
            
            numberOfItemsAdded += remainingItems.count
            tableData.insert(items: remainingItems, at: addedIndexPath)

            if addedIndexPath.section >= tableView.numberOfSections
            {
                sectionsToAddToTable.insert(addedIndexPath.section)
            }
        }
        
        tableView.insertRows(at: Array(addedRows), with: animation)
        tableView.insertSections(sectionsToAddToTable, with: animation)
    }
    
    public func insert(section: TableSection, at index: Int = 0,
                       withAnimation animation: UITableView.RowAnimation = .automatic)
    {
        insert(sections: [section], at: IndexSet(integer: index), withAnimation: animation)
    }
    
    public func insert(sections: [TableSection],
                       at indexSet: IndexSet = IndexSet(integer: 0),
                       withAnimation animation: UITableView.RowAnimation = .automatic)
    {
        tableView.beginUpdates()
        defer { tableView.endUpdates() }
        
        var numberOfSectionsAdded = 0
        var sectionsToAddToTable = indexSet

        // register headerFooterViews and cellTypes
        sections.forEach({ $0.register(forUseIn: tableView) })
        
        indexSet.forEach({
            
            if numberOfSectionsAdded < sections.count
            {
                numberOfSectionsAdded += 1
                if $0 >= tableView.numberOfSections
                {
                    sectionsToAddToTable.insert($0)
                }
                
                tableData.insert(sections: [sections[numberOfSectionsAdded-1]], at: $0)
            }
        })
        
        var addedSections = IndexSet(indexSet
            .dropLast(indexSet.count - numberOfSectionsAdded))
        
        if numberOfSectionsAdded < sections.count, numberOfSectionsAdded <= indexSet.count
        {
            // subscript indexing into an IndexSet is wonky!!
            let indexToAdd = indexSet[indexSet.index(
                indexSet.startIndex, offsetBy:numberOfSectionsAdded - 1)]  + 1
            let remainingSections = Array(sections.suffix(from: numberOfSectionsAdded))
            
            numberOfSectionsAdded += remainingSections.count
            tableData.insert(sections: remainingSections, at: indexToAdd)
            addedSections.insert(integersIn: numberOfSectionsAdded..<remainingSections.count)
        }
        
        tableView.insertSections(sectionsToAddToTable, with: animation)
    }

    // MARK: -

    public func append(item: TableItem, to section: Int = Int.max,
                       withAnimation animation: UITableView.RowAnimation = .automatic)
    {
        append(items: [item], to: section, withAnimation: animation)
    }
    
    public func append(items: [TableItem], to section: Int = Int.max,
                       withAnimation animation: UITableView.RowAnimation = .automatic)
    {
        let numberOfSections = tableData.numberOfSections > 0 ? tableData.numberOfSections : 1
        let sectionIndex = section < numberOfSections ? section : numberOfSections - 1
        
        insert(items: items, at: [IndexPath(row: tableData.numberOfItems(inSection: sectionIndex),
                                            section: sectionIndex)], withAnimation: animation)
    }
    
    public func append(section: TableSection,
                       withAnimation animation: UITableView.RowAnimation = .automatic)
    {
        append(sections: [section], withAnimation: animation)
    }
    
    public func append(sections: [TableSection],
                       withAnimation animation: UITableView.RowAnimation = .automatic)
    {
        let position = IndexSet(integer: tableView.numberOfSections)
        insert(sections: sections, at: position, withAnimation: animation)
    }
    
    // MARK: -
    
    public func delete(itemAt indexPath: IndexPath,
                       withAnimation animation: UITableView.RowAnimation = .automatic)
    {
        delete(itemsAt: [indexPath], with: animation)
    }
    
    public func delete(itemsAt indexPaths: [IndexPath],
                       withAnimation animation: UITableView.RowAnimation = .automatic)
    {
        indexPaths.forEach { tableData.delete(itemAt: $0) }
        tableView.deleteRows(at: indexPaths, with: animation)
    }
    
    // MARK: - UITableViewDataSource
    
    override open func numberOfSections(in tableView: UITableView) -> Int
    {
        assert(tableView == self.tableView)
        return tableData.numberOfSections
    }

    override open func tableView(_ tableView: UITableView,
                                   cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        assert(tableView == self.tableView)

        return tableData.item(atIndexPath: indexPath)?
            .configuredCell(for: tableView, at: indexPath) ?? DefaultTableViewCell()
    }
    
    override open func tableView(_ tableView: UITableView,
                                   numberOfRowsInSection section: Int) -> Int
    {
        assert(tableView == self.tableView)
        return tableData.numberOfItems(inSection: section)
    }

    // MARK: - UITableViewDelegate
    
    // Editing
    
    override open func tableView(_ tableView: UITableView,
                                 canEditRowAt indexPath: IndexPath) -> Bool
    {
        assert(tableView == self.tableView)
        return false
    }
    
    // Moving/reordering
    
    override open func tableView(_ tableView: UITableView,
                                 canMoveRowAt indexPath: IndexPath) -> Bool
    {
        assert(tableView == self.tableView)
        return false
    }
    
    // Data manipulation - reorder / moving support
    
    override open func tableView(_ tableView: UITableView, moveRowAt
        sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath)
    {
        assert(tableView == self.tableView)
        if let item = tableData.item(atIndexPath: sourceIndexPath)
        {
            tableView.beginUpdates()
            defer { tableView.endUpdates() }
            
            delete(itemAt: sourceIndexPath)
            insert(item: item, at: destinationIndexPath)
        }
    }
    
    // Data manipulation - insert and delete support
    
    override open func tableView(_ tableView: UITableView, commit
        editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath)
    {
        assert(tableView == self.tableView)

        switch editingStyle
        {
        case .none:     return
        case .insert:   return
            
        case .delete:   delete(itemAt: indexPath)
        }
    }
    
    // MARK:
    
    override open func tableView(_ tableView: UITableView,
                                   didSelectRowAt indexPath: IndexPath)
    {
        assert(tableView == self.tableView)

        tableData.item(atIndexPath: indexPath)?
            .handleSelection(TableContext(indexPath, self))
    }
    
    override open func tableView(_ tableView: UITableView,
                                   heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        assert(tableView == self.tableView)
        return tableData.item(atIndexPath: indexPath)?.cellType.height ?? 0
    }
    
    override open func tableView(_ tableView: UITableView,
                                   shouldHighlightRowAt indexPath: IndexPath) -> Bool
    {
        assert(tableView == self.tableView)
        return tableData.item(atIndexPath: indexPath)?.shouldHighlight ?? false
    }
    
    // MARK:

    override open func tableView(_ tableView: UITableView,
                                   titleForHeaderInSection index: Int) -> String?
    {
        assert(tableView == self.tableView)
        return tableData.section(atIndex: index)?.titleForHeader
    }
    
    override open func tableView(_ tableView: UITableView,
                                   titleForFooterInSection index: Int) -> String?
    {
        assert(tableView == self.tableView)
        return tableData.section(atIndex: index)?.titleForFooter
    }
    
    override open func tableView(_ tableView: UITableView,
                                   viewForHeaderInSection index: Int) -> UIView?
    {
        assert(tableView == self.tableView)
        return tableData.section(atIndex: index)?.headerView(for: tableView, at: index)
    }
    
    override open func tableView(_ tableView: UITableView,
                                   viewForFooterInSection index: Int) -> UIView?
    {
        assert(tableView == self.tableView)
        return tableData.section(atIndex: index)?.footerView(for: tableView, at: index)
    }
    
    override open func tableView(_ tableView: UITableView,
                                   heightForHeaderInSection index: Int) -> CGFloat
    {
        assert(tableView == self.tableView)
        return tableData.section(atIndex: index)?.headerViewHeight ?? 0
    }
    
    override open func tableView(_ tableView: UITableView,
                                   heightForFooterInSection index: Int) -> CGFloat
    {
        assert(tableView == self.tableView)
        return tableData.section(atIndex: index)?.footerViewHeight ?? 0
    }
    
    // Index

//    override public func sectionIndexTitles(for tableView: UITableView) -> [String]?
//    {
//        return nil
//    }
//
//    override public func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int
//    {
//    }
}
