//
//  StandardTableSection.swift
//  Created by J.Rodden
//

import UIKit

public extension UILabel
{
    func setText(to text: String?,
                 or attributedText: NSAttributedString?)
    {
        if attributedText == nil { self.text = text }
        else { self.attributedText = attributedText }
    }
}

// MARK: -

/// The "viewModel" protocol for storing items in a section,
/// and configuring optional section header and optional
/// section footer (thereby providing that functionality
/// for the  UITableViewDelegate and UITableViewDataSource)
public protocol TableSection: class
{
    var headerTitle: String? { get }
    var footerTitle: String? { get }
    
    var headerType: View.Type { get }
    var footerType: View.Type { get }
    
    var titleForHeader: String? { get }
    var titleForFooter: String? { get }
    
    var numberOfItems: Int { get }
    
    var showHeaderView: Bool { get }
    var showFooterView: Bool { get }
    
    // MARK:
    
    func item(atIndex: Int) -> TableItem?
    
    func forEach(item perform: (TableItem) -> Void)
    
    func append(items: [TableItem])
    func insert(items: [TableItem], at index: Int)
    
    func delete(itemAtIndex: Int)

    // MARK:

    func register(forUseIn: UITableView)
    
    func configure(headerView: UITableViewHeaderFooterView, forSection: Int)
    func configure(footerView: UITableViewHeaderFooterView, forSection: Int)
}

// MARK: -

public extension TableSection
{
    typealias View = UITableViewHeaderFooterView

    var headerTitle: String? { return nil }
    var footerTitle: String? { return nil }
    
    var headerType: View.Type { return DefaultHeaderFooter.self }
    var footerType: View.Type { return DefaultHeaderFooter.self }

    var titleForHeader: String? { return showHeaderView ? headerTitle : nil }
    var titleForFooter: String? { return showFooterView ? footerTitle : nil }
    
    // by default, non-nil sectoinHeader/FooterTitle shows View
    var showHeaderView: Bool { return headerTitle != nil }
    var showFooterView: Bool { return footerTitle != nil }
    
    var headerViewHeight: CGFloat { return showHeaderView ? headerType.height : 0 }
    var footerViewHeight: CGFloat { return showFooterView ? footerType.height : 0 }
    
    // MARK:
    
    func item(withID ID: String) -> TableItem?
    {
        var item: TableItem?
        
        forEach()
        {
            guard let itemID = $0.ID, itemID == ID else { return }
            assert(item == nil, "Multiple items with ID `\(ID)`")
            
            item = $0
        }
        
        return item
    }
    
    func insert(items: [TableItem]) { insert(items: items, at: 0) }

    func delete(itemAtIndex: Int) { }

    func headerView(for tableView: UITableView, at index: Int) -> View?
    {
        guard showHeaderView else { return nil }
        
        let headerView = tableView
            .dequeueReusableHeaderFooterView(
                withIdentifier: headerType.identifier)
        
        configure(headerView: headerView!, forSection: index)
        
        return headerView
    }
    
    func footerView(for tableView: UITableView, at index: Int) -> View?
    {
        guard showFooterView else { return nil }
        
        let footerView = tableView
            .dequeueReusableHeaderFooterView(
                withIdentifier: footerType.identifier)
        
        configure(footerView: footerView!, forSection: index)
        
        return footerView
    }

    // MARK:
    
    func register(forUseIn tableView: UITableView)
    {
        headerType.register(forUseIn: tableView)
        footerType.register(forUseIn: tableView)
        forEach(item: { $0.cellType.register(forUseIn: tableView) })
    }

    func configure(headerView: UITableViewHeaderFooterView, forSection: Int)
    {
        headerView.textLabel?.text = headerTitle
    }
    
    func configure(footerView: UITableViewHeaderFooterView, forSection: Int) { }
}

// MARK: -

open class StandardTableSection : StandardTableItem, TableSection
{
    public init(withID ID: String? = nil,
                named name: String? = nil,
                footerTitle: String? = nil,
                _ items: [TableItem] = [TableItem](),
                headerFooterConfigureBlock: HeaderFooterConfigureBlock? = nil)
    {
        self.items = items; super.init()
        self.headerFooterConfigureBlock = headerFooterConfigureBlock
        self.ID = ID; self.title = name; self.footerTitle = footerTitle
    }
    
    // MARK:
    
    public var items: [TableItem]

    open var headerTitle: String?
    {
        set { title = newValue }
        get { return title ?? attributedTitle?.string }
    }
    
    open var headerDetail: String?
    {
        set { detail = newValue }
        get { return detail ?? attributedDetail?.string }
    }
    
    public var footerTitle: String?
    {
        set { set(.footerTitle, to: newValue) }
        get { return sectionData?[.footerTitle] as? String }
    }
    
    public var footerDetail: String?
    {
        set { set(.footerDetail, to: newValue) }
        get { return sectionData?[.footerDetail] as? String }
    }
    
    public var numberOfItems : Int { return items.count }
    
    // MARK:
    
    private enum Info : String
    {
        case footerTitle, footerDetail
    }
    
    private typealias SectionData = [Info:Any]

    private func set(_ info: Info, to newValue: Any?)
    {
        var sectionData = self.sectionData
        if (newValue != nil) || (sectionData != nil)
        {
            sectionData =
                sectionData ?? SectionData()
            
            sectionData?[info] = newValue
            super.data[.extraData] = sectionData
        }
    }
    
    private var sectionData: SectionData?
    {
        set { super.data[.extraData] = newValue }
        get { return (data[.extraData] as? SectionData) }
    }
    
    // MARK:
    
    public func item(atIndex index: Int) -> TableItem?
    {
        return index < numberOfItems ? items[index] : nil
    }
    
    public func forEach(item perform: (TableItem) -> Void) { items.forEach(perform) }

    public func append(items: [TableItem]) { self.items.append(contentsOf: items) }
    public func insert(items: [TableItem], at index: Int = 0) { self.items.insert(contentsOf: items, at: index) }
    public func delete(itemAtIndex index: Int) { self.items.remove(at: index) }

    // MARK:
    
    open var titleForHeader: String?
    {
        let block = headerFooterConfigureBlock
        guard block == nil else { return nil }
        return showHeaderView ? headerTitle : nil
    }
    
    open var titleForFooter: String?
    {
        let block = headerFooterConfigureBlock
        guard block == nil else { return nil }
        return showFooterView ? footerTitle : nil
    }
    
    public enum HeaderOrFooter { case header, footer }
    
    public typealias HeaderFooterConfigureBlock =
        (_: UITableViewHeaderFooterView, _: Int, _: HeaderOrFooter) -> Void
    
    open var headerFooterConfigureBlock: HeaderFooterConfigureBlock?
    {
        set { set(.configureBlock, to: newValue, redraw: false) }
        get { return data[.configureBlock] as? HeaderFooterConfigureBlock }
    }
    
    // MARK:
    
    open func configure(headerView: View, forSection section: Int)
    {
        headerView.textLabel?.setText(to: headerTitle,
                                      or: attributedTitle)
        headerView.detailTextLabel?.setText(to: headerDetail,
                                            or: attributedDetail)
        
        headerFooterConfigureBlock?(headerView, section, .header)
    }
    
    open func configure(footerView: View, forSection section: Int)
    {
        footerView.textLabel?.text = footerTitle
        footerView.detailTextLabel?.text = footerDetail
        
        headerFooterConfigureBlock?(footerView, section, .footer)
    }
}
