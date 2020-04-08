//
//  StandardTableData.swift
//  Created by J.Rodden
//  Copyright © 2018 DD/MF & Associates. All rights reserved.
//

import Foundation

public protocol TableData
{
    /// # of (stored) sections
    var sectionCount: Int { get }
    
    // MARK:
    
    func removeAll()
    func addSection()

    func delete(itemAt indexPath: IndexPath)
    func delete(section index: Int)

    func section(atIndex index: Int) -> TableSection?
    func insert(sections: [TableSection], at index: Int)
}

// MARK: -

public extension TableData
{
    var firstSection: TableSection? { return section(atIndex: 0) }
    var lastSection: TableSection? { return section(atIndex: sectionCount) }
    
    func item(withID ID: String) -> TableItem?
    {
        var item: TableItem?
        
        forEach()
        {
            (section: TableSection) in
            
            if let sectionItem = section as? TableItem, sectionItem.ID == ID
            {
                assert(item == nil, "Multiple items with ID `\(ID)`")
                item = sectionItem
            }
            
            if let foundItem = section.item(withID: ID)
            {
                assert(item == nil || foundItem === item,
                       "Multiple items with ID `\(ID)`")
                item = foundItem
            }
        }
        
        return item
    }
    
    func item(atIndexPath indexPath: IndexPath) -> TableItem?
    {
        return indexPath.section < sectionCount ?
            section(atIndex: indexPath.section)?.item(atIndex: indexPath.row) : nil
    }
    
    // MARK:
    
    func forEach(item performTask: (TableItem) -> Void)
    {
        forEach(section: { $0.forEach(item: performTask) } )
    }
    
    func forEach(section performTask: (TableSection) -> Void)
    {
        for index in 0..<sectionCount
        {
            if let section = section(atIndex: index)
            {
                performTask(section)
            }
        }
    }
    
    // MARK:
    
    func insert(item: TableItem, at indexPath:
        IndexPath = IndexPath(row: 0, section: 0))
    {
        insert(items: [item], at: indexPath)
    }
    
    func insert(items: [TableItem], at indexPath:
        IndexPath = IndexPath(row: 0, section: 0))
    {
        let index = normalize(sectionIndex: indexPath.section)
        self.section(atIndex: index)!.insert(items: items,
                                             at: indexPath.row)
    }
    
    func delete(itemAt indexPath: IndexPath)
    {
        section(atIndex: indexPath.section)?
            .delete(itemAtIndex: indexPath.row)
    }
    
    func append(item: TableItem, to section: Int = Int.max)
    {
        append(items: [item], to: section)
    }
    
    func append(items: [TableItem], to section: Int = Int.max)
    {
        let index = normalize(sectionIndex: section)
        self.section(atIndex: index)!.append(items: items)
    }

    func append(section: TableSection)
    {
        insert(sections: [section], at: sectionCount)
    }

    func append(sections: [TableSection])
    {
        insert(sections: sections, at: sectionCount)
    }
    
    // MARK:
    
    /// how many sections to report to UITableView (>= 1)
    var numberOfSections : Int { return max(sectionCount, 1) }

    internal func normalize(sectionIndex: Int) -> Int
    {
        if sectionIndex >= sectionCount { addSection() }
        return sectionIndex < sectionCount ? sectionIndex : sectionCount
    }
    
    func numberOfItems(inSection sectionIndex: Int) -> Int
    {
        return section(atIndex: sectionIndex)?.numberOfItems ?? 0
    }
}

// MARK: -

open class StandardTableData : StandardTableSection, TableData
{
    public init(_ sections:
        [TableSection] = [TableSection]())
    {
        super.init(sections as! [TableItem])
    }
    
    public var sections: [TableSection]
    {
        // if these casts fail, the model is broken
        get { return items as! [TableSection] }
        set { items = newValue as! [TableItem] }
    }
    
    public var sectionCount: Int { return sections.count }
    
    // MARK:
    
    public func removeAll()
    {
        sections.removeAll()
    }
    
    public func addSection()
    {
        sections.append(StandardTableSection())
    }
    
    public func delete(section index: Int)
    {
        sections.remove(at: index)
    }
    
    public func section(atIndex index: Int) -> TableSection?
    {
        return ((index >= 0) && (index < sections.count)) ? sections[index] : nil
    }
    
    public func insert(sections: [TableSection], at index: Int)
    {
        self.sections.insert(contentsOf: sections, at: index)
    }
}
