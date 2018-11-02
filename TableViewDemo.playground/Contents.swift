//: Demo some GenericTableView capabilities

import UIKit
import PlaygroundSupport

// ----------------------------------------------------

// create a plain style tableView
let tableVC = TableViewController(style: .grouped)
tableVC.tableView.hideTrailingSeparators = true

// place it into the playground simulator
PlaygroundPage.current.liveView = tableVC

// give a simple set of items to start with...
let rawData = [ ("One, Two", "Buckle my shoe"),
                ("Three, Four", "Shut the door"),
                ("Five, Six", "Pick up sticks") ]

// StandardTableItems can be created from a single string or a pair
tableVC.insert(items: rawData.map({ StandardTableItem($0.0, $0.1) }))

// now lets add some interactive items

// ----------------------------------------------------
// like one that toggles itself on/off...

let toggleCallback: StandardTableItem.SelectionCallback =
{
    (context) in
    
    context.deselectRow(animated: true)
    
    if let cell = context.tableCell as? DefaultTableViewCell,
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
tableVC.append(item: StandardTableItem([ .title : "this one toggles",
                                         .selectionCallback : toggleCallback ] ))

// ----------------------------------------------------
// and one that adds another simple item each time you tap it...

let iconImage = UIImage(named: "icon")
let addItemCallback: StandardTableItem.SelectionCallback =
{
    (context) in
    
    context.deselectRow(animated: true)
    
    if let tableVC = context.viewController as? TableViewController
    {
        let configureBlock: StandardTableItem.ConfigureBlock =
        {
            (cell, indexPath) in
            
            // dynamically set the title
            cell.textLabel?.text =
                "item \(indexPath.row + 1) " +
            "(in section \(indexPath.section + 1))"
            
            // alternate background color (w/in section)
            cell.backgroundColor =
                (indexPath.row % 2 == 0) ? .white :
                UIColor.lightGray.withAlphaComponent(0.25)
        }
        
        // statically provide the image and accessoryView
        let accessoryView = UIImageView(image: iconImage)
        accessoryView.bounds.size = CGSize(width: 32, height: 32)
        
        tableVC.append(item:
            StandardTableItem([ .image : iconImage as Any,
                                .accessoryView : accessoryView,
                                .configureBlock : configureBlock ]))
    }
}

tableVC.append(item: StandardTableItem([ .title : "add another item",
                                         .selectionCallback : addItemCallback ] ))

// ----------------------------------------------------
// and one that adds a new section to the table each time it's tapped

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
                headerOrFooterView.textLabel?.text = "Section \(section + 1)"
                
                if let detailTextLabel = headerOrFooterView.detailTextLabel
                {
                    detailTextLabel.text = "(only grouped style table sections show detail)"
                }
        }
        
        tableVC.append(section:
            StandardTableSection(named: "",
                                 headerFooterConfigureBlock: configureBlock))
    }
}

tableVC.append(item: StandardTableItem([ .title : "add another section",
                                         .selectionCallback : addSectionCallback ] ))

// ----------------------------------------------------
