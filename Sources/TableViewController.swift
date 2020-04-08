//
//  TableViewController.swift
//  Created by J.Rodden
//  Copyright © 2018 DD/MF & Associates. All rights reserved.
//

import UIKit

public extension UITableView
{
    struct Updater
    {
        let completion: (()->())?
        init(_ t: UITableView)
        {
            if t.superview == nil
            {
                completion = nil
            }
            else
            {
                t.beginUpdates()
                completion = { t.endUpdates() }
            }
        }
    }
    
    func register(item: TableItem)
    {
        item.cellType.register(forUseIn: self)
    }
    
    func register(items: [TableItem])
    {
        items.forEach { self.register(item: $0) }
    }
    
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
}

// MARK: -

open class TableViewController : UITableViewController
{
    public typealias Cell = TableItem.Cell
    public typealias Updater = UITableView.Updater
    
    public var tableData: TableData = StandardTableData()
    {
        didSet
        {
            registerEverything()
            if isViewLoaded { tableView.reloadData() }
        }
    }
    
    open func tableItem(at indexPath: IndexPath) -> TableItem?
    {
        return tableData.item(atIndexPath: indexPath)
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
        let update = Updater(tableView)
        defer { update.completion?() }
        
        var numberOfItemsAdded = 0
        var sectionsToAddToTable = IndexSet()
        
        // this makes no sense, but the tableView
        // barfs on the additions w/o this pre-check
        let _ = tableView.numberOfRows(inSection: 0)
        
        // make sure all cellTypes are registered
        items.forEach { $0.cellType.register(forUseIn: tableView) }
        
        indexPaths.forEach {
            
            if numberOfItemsAdded < items.count
            {
                numberOfItemsAdded += 1
                if $0.section >= tableView.numberOfSections
                {
                    sectionsToAddToTable.insert($0.section)
                }
                
                tableData.insert(items: [items[numberOfItemsAdded-1]], at: $0)
            }
        }
        
        var addedRows = indexPaths.dropLast(indexPaths.count - numberOfItemsAdded)
        
        if numberOfItemsAdded < items.count, numberOfItemsAdded <= indexPaths.count
        {
            let lastIndexPath = indexPaths[numberOfItemsAdded - 1]
            let addedIndexPath = IndexPath(row: // after lastIndexPath
                lastIndexPath.row + 1, section: lastIndexPath.section)
            let remainingItems = Array(items.suffix(from: numberOfItemsAdded))
            
            addedRows.append(
                contentsOf: (numberOfItemsAdded..<items.count)
                    .map { IndexPath(row: addedIndexPath.row + $0 - 1,
                                     section: addedIndexPath.section) })
            
            numberOfItemsAdded += remainingItems.count
            tableData.insert(items: remainingItems, at: addedIndexPath)

            if addedIndexPath.section >= tableView.numberOfSections
            {
                sectionsToAddToTable.insert(addedIndexPath.section)
            }
        }
        
        if tableView.superview != nil
        {
            tableView.insertRows(at: Array(addedRows), with: animation)
            tableView.insertSections(sectionsToAddToTable, with: animation)
        }
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
        let update = Updater(tableView)
        defer { update.completion?() }
        
        var numberOfSectionsAdded = 0
        var sectionsToAddToTable = indexSet

        // register headerFooterViews and cellTypes
        sections.forEach { $0.register(forUseIn: tableView) }
        
        indexSet.forEach {
            
            if numberOfSectionsAdded < sections.count
            {
                numberOfSectionsAdded += 1
                if $0 >= tableView.numberOfSections
                {
                    sectionsToAddToTable.insert($0)
                }
                
                tableData.insert(sections: [sections[numberOfSectionsAdded-1]], at: $0)
            }
        }
        
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
        
        if tableView.superview != nil
        {
            tableView.insertSections(sectionsToAddToTable, with: animation)
        }
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
        delete(itemsAt: [indexPath], withAnimation: animation)
    }
    
    public func delete(itemsAt indexPaths: [IndexPath],
                       withAnimation animation: UITableView.RowAnimation = .automatic)
    {
        indexPaths.forEach { tableData.delete(itemAt: $0) }
        
        if tableView.superview != nil
        {
            tableView.deleteRows(at: indexPaths, with: animation)
        }
    }
}

// MARK: - UITableViewDataSource

extension TableViewController
{
    override open func numberOfSections(in tableView: UITableView) -> Int
    {
        assert(tableView == self.tableView)
        return tableData.numberOfSections
    }

    override open func tableView(_ tableView: UITableView,
                                   cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        assert(tableView == self.tableView)
        guard let item = tableItem(at: indexPath)
            else { return DefaultTableViewCell() }
        
        return item.configuredCell(for: tableView, at: indexPath)
    }
    
    override open func tableView(_ tableView: UITableView,
                                 numberOfRowsInSection section: Int) -> Int
    {
        assert(tableView == self.tableView)
        return tableData.numberOfItems(inSection: section)
    }

    // MARK:
    // Editing
    
    override open func tableView(_ tableView: UITableView,
                                 canEditRowAt indexPath: IndexPath) -> Bool
    {
        assert(tableView == self.tableView)
        return tableItem(at: indexPath)?.canEdit ?? false
    }
    
    // Data manipulation - insert and delete support
    
    override open func tableView(_ tableView: UITableView, commit
        editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath)
    {
        assert(tableView == self.tableView)
        if editingStyle == .delete { delete(itemAt: indexPath) }
    }
    
    // MARK:
    // Row Reordering
    
    override open func tableView(_ tableView: UITableView,
                                 canMoveRowAt indexPath: IndexPath) -> Bool
    {
        assert(tableView == self.tableView)
        return true
    }
    
    // Data manipulation - reorder / moving support
   
    override open func tableView(_ tableView: UITableView, moveRowAt
        sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath)
    {
        assert(tableView == self.tableView)
        if let item = tableItem(at: sourceIndexPath)
        {
            tableData.delete(itemAt: sourceIndexPath)
            tableData.insert(item: item, at: destinationIndexPath)
        }
    }
    
    open func tableView(_ tableView: UITableView, moveRowAt
        sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath,
                                    withAnimation animation: UITableView.RowAnimation)
    {
        assert(tableView == self.tableView)
        if let item = tableItem(at: sourceIndexPath)
        {
            let update = Updater(tableView); defer { update.completion?() }
            tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath)
            self.tableView(tableView, moveRowAt: sourceIndexPath, to: destinationIndexPath)
        }
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
    
//    // Index
//
//    override open func sectionIndexTitles(for tableView: UITableView) -> [String]?
//    {
//        return nil
//    }
//
//    override open func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int
//    {
//    }
}

// MARK: - UITableViewDelegate

extension TableViewController
{
    override open func tableView(_ tableView: UITableView,
                                   didSelectRowAt indexPath: IndexPath)
    {
        assert(tableView == self.tableView)

        tableItem(at: indexPath)?
            .handleSelection(TableContext(indexPath, self))
    }
    
    override open func tableView(_ tableView: UITableView,
                                   heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        assert(tableView == self.tableView)
        return tableItem(at: indexPath)?.cellType.height ?? 0
    }
    
    override open func tableView(
        _ tableView: UITableView, editingStyleForRowAt
        indexPath: IndexPath) -> UITableViewCell.EditingStyle
    {
        assert(tableView == self.tableView)
        return tableItem(at: indexPath)?.editingStyle ?? .none
    }
    
    override open func tableView(_ tableView: UITableView,
                                   shouldHighlightRowAt indexPath: IndexPath) -> Bool
    {
        assert(tableView == self.tableView)
        return tableItem(at: indexPath)?.shouldHighlight ?? false
    }
    
    override open func tableView(_ tableView: UITableView,
                                   indentationLevelForRowAt indexPath: IndexPath) -> Int
    {
        assert(tableView == self.tableView)
        return tableItem(at: indexPath)?.indentationLevel ?? 0
    }
    
    // MARK:
    
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
    
    // MARK:
    // Copy/Paste.  All three methods must be implemented by the delegate.
    
    override open func tableView(_ tableView: UITableView,
                                 shouldShowMenuForRowAt indexPath: IndexPath) -> Bool
    {
        assert(tableView == self.tableView)
        return false
    }
    
    override open func tableView(_ tableView: UITableView, performAction action: Selector,
                                 forRowAt indexPath: IndexPath, withSender sender: Any?)
    {
        assert(tableView == self.tableView)
    }
    
    override open func tableView(_ tableView: UITableView, canPerformAction action: Selector,
                                 forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool
    {
        assert(tableView == self.tableView)
        return false
    }
}
