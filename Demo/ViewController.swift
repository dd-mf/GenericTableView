//
//  ViewController.swift
//  Demo
//
//  Created by me on 11/29/18.
//  Copyright © 2018 DD/MF & Associates. All rights reserved.
//

import UIKit
import GenericTableView

class ViewController: TableViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        addRawItems()
        addToggleItem()
        addSectionItem()
        
        tableView.hideTrailingSeparators = true
        navigationItem.title = "GenericTableView"
        
        navigationItem.leftBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .add)
            {
                [weak self] (_) in self?.addAnotherItem()
            }
        
        // add edit button that toggles tableView's isEditing
        // and replaces itself with done/edit button to match
        navigationItem.rightBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .edit)
            {
                [weak self] (button) in
                if let tableView = self?.tableView
                {
                    tableView.isEditing = !tableView.isEditing
                    
                    self?.navigationItem.rightBarButtonItem =
                        UIBarButtonItem(barButtonSystemItem:
                            tableView.isEditing ? .done : .edit,
                                        block: button.block!)
                }
        }
    }
    
    // ----------------------------------------------------
    
    func addRawItems()
    {
        // give a simple set of items to start with...
        let rawData = [ ("One, Two", "Buckle my shoe"),
                        ("Three, Four", "Shut the door"),
                        ("Five, Six", "Pick up sticks") ]
        
        // StandardTableItems can be created from a single string or a pair
        insert(items: rawData.map({ StandardTableItem($0.0, $0.1) }))
    }
    
    // ----------------------------------------------------
    // now lets add some interactive items

    func addToggleItem()
    {
        // like one that toggles itself on/off...
        
        let toggleCallback: StandardTableItem.SelectionCallback =
        {
            (context) in
            
            context.deselectRow(animated: true)
            
            if let cell = context.tableCell as? BaseTableViewCell,
                let tableItem = cell.tableItem as? StandardTableItem
            {
                let isChecked = tableItem.accessoryType == .checkmark
                
                // toggle checkmark on/off, change titleColor as well
                tableItem.accessoryType = isChecked ? .none : .checkmark
                tableItem.titleColor = isChecked ? UIColor.black : UIColor.blue
                
                // and alternately style/un-style the text as well
                if let text = tableItem.title ?? tableItem.attributedTitle?.string
                {
                    let fontSize = CGFloat(16)
                    tableItem.attributedTitle =
                        NSAttributedString(string: text, attributes:
                            [NSAttributedString.Key.font: isChecked ?
                                UIFont.systemFont(ofSize: fontSize) :
                                UIFont.italicSystemFont(ofSize: fontSize)])
                }
            }
        }
        
        // more sophisticated StandardTableItems (or a subclass) can be
        // declared using the basic properties assembled in an dictionary
        append(item: StandardTableItem([ .title : "this one toggles",
                                         .selectionCallback : toggleCallback ] ))
    }
    
    // ----------------------------------------------------
    // and one that adds another simple item each time you tap it...

    var sectionCount = [Int: Int]()
    func addAnotherItem()
    {
        // insert section 2 if not already present
        if tableData.numberOfSections == 1,
            let firstSection = tableData.section(atIndex: 0)
        {
            tableView(tableView, didSelectRowAt: IndexPath(
                row: firstSection.numberOfItems - 1, section: 0))
        }
        
        let section = tableData.numberOfSections
        let row = (sectionCount[section] ?? 0) + 1
        let title = "item \(row) (in section \(section))"
        
        sectionCount[section] = row // update section counter
        
        let configureBlock: StandardTableItem.ConfigureBlock =
        {
            (item, indexPath) in
            
            // alternate background color (w/in section)
            item.cell?.backgroundColor =
                (row % 2 == 0) ? .white :
                UIColor.lightGray.withAlphaComponent(0.25)
        }
        
        // statically provide the image and accessoryView
        let iconImage = UIImage(named: "icon")
        let accessoryView = UIImageView(image: iconImage)
        accessoryView.bounds.size = CGSize(width: 32, height: 32)
        
        append(item: StandardTableItem([ .title : title,
                                         .image : iconImage as Any,
                                         .accessoryView : accessoryView,
                                         .configureBlock : configureBlock,
                                         .editingStyle : TableItem.EditingStyle.delete ]))
    }
    
    // ----------------------------------------------------
    // and one that adds a new section to the table each time it's tapped
    
    func addSectionItem()
    {
        let addSectionCallback: StandardTableItem.SelectionCallback =
        {
            (context) in
            
            context.deselectRow(animated: true)
            
            if let tableVC = context.viewController as? TableViewController
            {
                let configureBlock:
                    StandardTableSection.HeaderFooterConfigureBlock =
                    {
                        (headerOrFooterView, section, type) in
                        headerOrFooterView.detailTextLabel?.text =
                        nil//"(only grouped style table sections show detail)"
                }
                
                tableVC.append(section:
                    StandardTableSection(named:
                        "Section \(tableVC.tableView.numberOfSections + 1)",
                                         headerFooterConfigureBlock: configureBlock))
            }
        }
        
        append(item: StandardTableItem([ .title : "add another section",
                                         .selectionCallback : addSectionCallback ] ))
    }
    
    // ----------------------------------------------------
}
