//
//  AttributedPopUpButton.swift
//
//  Created by Vitalii Vashchenko on 09.12.2020.
//

import AppKit
import Combine

/// A control for selecting an item from a list of unique items.
///
/// An AttributedPopUpButton object uses an NSPopUpButtonCell object to implement its user interface.
///
/// An AttributedPopUpButton displays its list of items with NSAttributedString, allowing to diverse the displayable content.
///
/// For example, AttributedPopUpButton is a perfect choise to create a font picker with a list of available fonts.
/// You can display each font in a menu item with attributed title written with a corresponding font.
///
/// - Note: While a menu is tracking user input, programmatic changes to the menu,
/// such as adding, removing, or changing items on the menu, is not reflected.

final public class AttributedPopUpButton: NSPopUpButton {
	
	public typealias MenuUnit = (attributedTitle: NSAttributedString,
								 representedObject: Any?,
								 selector: Selector?,
								 target: AnyObject?,
								 tag: Int?)
	
	
	// MARK: - Added Properties
	
	/// The menu containing items with attributed titles associated with the pop-up button
	///
	/// Make sure you won't touch the original 'menu' property of the button. This will cause a faulty behaviour
	public var attributedMenu: NSMenu?
	private var subscriber: AnyCancellable?
	
	final public override func viewWillDraw() {
		super.viewWillDraw()
		
		if subscriber == nil {
			// update the menu with selected items as soon as possible
			subscriber = NotificationCenter.default.publisher(for: NSMenu.willSendActionNotification).sink(receiveValue: { notification in
				guard notification.object as? NSMenu == self.attributedMenu else { return }
				guard let selectedItem = notification.userInfo?["MenuItem"] as? NSMenuItem else { return }
				self.selectedItems = [selectedItem]
			})
		}
	}
	
	deinit {
		subscriber?.cancel()
	}
	
	
	// MARK: Items Selection
	
	/// Holds the selected items from the attributedMenu.
	/// It's an array, so the AttributedPopUpButton objects support multiple items selection
	public var selectedItems: [NSMenuItem] = [] {
		didSet {
			updateSelectedItems(oldValues: oldValue)
		}
	}

	public override var selectedItem: NSMenuItem? {
		selectedItems.first
	}
	
	final private func updateSelectedItems(oldValues: [NSMenuItem] = []) {
		isEnabled = true

		if selectedItems.count > 1 {
			let multiTile = NSLocalizedString("label.multipleValues", comment: "string describing 'multiple values' state")
			
			let menuItem: NSMenuItem
			if let multiItem = menu?.item(withTitle: multiTile) {
				menuItem = multiItem
			} else {
				menuItem = NSMenuItem(title: multiTile, action: nil, keyEquivalent: "")
				menu?.addItem(menuItem)
			}
			selectedItems.forEach{ $0.state = .mixed }
			super.select(menuItem)
		}
		else if let item = selectedItems.first {
			let menuItem: NSMenuItem
			if let selectionItem = menu?.item(withTitle: item.title) {
				menuItem = selectionItem
			} else {
				menuItem = NSMenuItem(title: item.title, action: nil, keyEquivalent: "")
				menu?.addItem(menuItem)
			}
			item.state = .on
			oldValues.forEach{ $0.state = .off }
			super.select(menuItem)
		} else {
			super.select(nil)
			oldValues.forEach{ $0.state = .off }
			menu?.removeAllItems()
			isEnabled = false
		}
	}
	
	/// Selects multiple specified menu items.
	/// - Parameter items: The menu items to select, or empty array if you want to deselect all menu items
	public final func select(_ items: [NSMenuItem]) {
		let existingItems = items.compactMap({ item in attributedMenu?.items.first(where: { item == $0 }) })
		selectedItems = existingItems
	}
	
	/// Selects multiple specified menu items.
	/// - Parameter items: The titles of items to select, or empty array if you want to deselect all menu items
	public final func selectItems(withTitles titles: [String]) {
		let existingItems = titles.compactMap({ title in attributedMenu?.items.first(where: { title == $0.title }) })
		selectedItems = existingItems
	}
	
	/// Selects multiple specified menu items.
	/// - Parameter items: The titles of items to select, or empty array if you want to deselect all menu items
	public final func selectItems(withRepresentedObjects objects: [Any]) {
		let existingItems = objects.compactMap({ self.item(withRepresentedObject: $0) })
		selectedItems = existingItems
	}
	
	public override func select(_ item: NSMenuItem?) {
		if let item = attributedMenu?.items.first(where: { $0 == item }) {
			selectedItems = [item]
			return
		}
		selectedItems.removeAll()
	}
	
	public override func selectItem(at index: Int) {
		if let menu = attributedMenu, index < menu.items.count {
			select(menu.items[index])
			return
		}
		selectedItems.removeAll()
	}
	
	public override func selectItem(withTag tag: Int) -> Bool {
		if let item = attributedMenu?.item(withTitle: title) {
			select(item)
			return true
		}
		selectedItems.removeAll()
		return false
	}
	
	public override func selectItem(withTitle title: String) {
		if let item = attributedMenu?.item(withTitle: title) {
			select(item)
			return
		}
		selectedItems.removeAll()
	}
	
	public override func synchronizeTitleAndSelectedItem() {
		if selectedItems.isEmpty {
			if let item = attributedMenu?.items.first {
				selectedItems = [item]
			}
		} else {
			for item in selectedItems {
				if menu?.item(withTitle: item.attributedTitle?.string ?? item.title) == nil {
					menu?.removeAllItems()
					updateSelectedItems()
				}
				if attributedMenu?.item(withTitle: item.attributedTitle?.string ?? item.title) == nil {
					if let item = attributedMenu?.items.first {
						selectedItems = [item]
					}
					break
				}
			}
		}
	}
	
	
	// MARK: - Item Searching
	
	public override var numberOfItems: Int {
		attributedMenu?.items.count ?? 0
	}
	
	public override var lastItem: NSMenuItem? {
		attributedMenu?.items.last
	}
	
	public override var indexOfSelectedItem: Int {
		if let item = selectedItems.first {
			return attributedMenu?.index(of: item) ?? -1
		}
		return -1
	}
	
	public override var titleOfSelectedItem: String? {
		if let item = selectedItems.first, let idx = attributedMenu?.index(of: item) {
			return attributedMenu?.items[idx].attributedTitle?.string ?? attributedMenu?.items[idx].title ?? nil
		}
		return nil
	}
	
	public override func indexOfItem(withTag tag: Int) -> Int {
		attributedMenu?.indexOfItem(withTag: tag) ?? -1
	}
	
	public override func indexOfItem(withTitle title: String) -> Int {
		attributedMenu?.indexOfItem(withTitle: title) ?? -1
	}
	
	public override func indexOfItem(withRepresentedObject obj: Any?) -> Int {
		attributedMenu?.indexOfItem(withRepresentedObject: obj) ?? -1
	}

	public override var itemTitles: [String] {
		attributedMenu?.items.compactMap{ $0.attributedTitle?.string } ?? attributedMenu?.items.map{ $0.title } ?? []
	}
	
	public override var itemArray: [NSMenuItem] {
		attributedMenu?.items ?? []
	}
	
	public override func itemTitle(at index: Int) -> String {
		item(at: index)?.attributedTitle?.string ?? item(at: index)?.title ?? ""
	}
	
	public override func item(at index: Int) -> NSMenuItem? {
		attributedMenu?.items[index]
	}
	
	public override func item(withTitle title: String) -> NSMenuItem? {
		attributedMenu?.items.first(where: { $0.attributedTitle?.string == title }) ?? attributedMenu?.items.first(where: { $0.title == title })
	}
	
	public override func index(of item: NSMenuItem) -> Int {
		attributedMenu?.index(of: item) ?? -1
	}
	
	public override func indexOfItem(withTarget target: Any?, andAction actionSelector: Selector?) -> Int {
		attributedMenu?.indexOfItem(withTarget: target, andAction: actionSelector) ?? -1
	}
	
	/// Returns the menu item that holds the specified represented object.
	/// - Parameter representedObject: the represented object of the menu item you looking for
	public final func item(withRepresentedObject representedObject: Any) -> NSMenuItem? {
		if let idx = attributedMenu?.indexOfItem(withRepresentedObject: representedObject) {
			return attributedMenu!.items[idx]
		}
		return nil
	}
	
	
	// MARK: - Inserting Items
	
	public override func addItem(withTitle title: String) {
		let item = NSMenuItem()
		item.title = title
		attributedMenu?.addItem(item)
	}
	
	public override func addItems(withTitles itemTitles: [String]) {
		itemTitles.forEach { addItem(withTitle: $0) }
	}
	
	public override func insertItem(withTitle title: String, at index: Int) {
		let item = NSMenuItem()
		item.title = title
		attributedMenu?.insertItem(item, at: index)
	}

	
	// MARK: - Removing Items
	
	/// Removes specified item from the menu.
	/// - Parameter item: an item to remove
	final public func removeItem(_ item: NSMenuItem) {
		guard let idx = attributedMenu?.items.firstIndex(of: item) else { return }
		removeItem(at: idx)
	}
	
	public override func removeAllItems() {
		attributedMenu?.removeAllItems()
		synchronizeTitleAndSelectedItem()
	}
	
	public override func removeItem(at index: Int) {
		guard let item = attributedMenu?.item(at: index) else { return }
		attributedMenu?.removeItem(item)
		synchronizeTitleAndSelectedItem()
	}
	
	public override func removeItem(withTitle title: String) {
		guard let index = attributedMenu?.indexOfItem(withTitle: title) else { return }
		removeItem(at: index)
	}
		
	
	// MARK: - Responding to User Actions
	
	public override func mouseDown(with event: NSEvent) {
		let location = convert(event.locationInWindow, from: nil)
		if	frame.contains(location) {
			attributedMenu?.minimumWidth = bounds.width
			attributedMenu?.popUp(positioning: selectedItem, at: .zero, in: self)
		}
	}
	
	
	// MARK: - Content Update
	
	/// Convinience method to fill the button's menu with a specified content.
	/// - Parameter content: array of content units to fill the menu with
	public final func updateMenu(with content: [MenuUnit]) {
		if content.isEmpty {
			removeAllItems()
			return
		}
		
		if attributedMenu == nil {
			attributedMenu = NSMenu()
		}
		if menu == nil {
			menu = NSMenu()
		}
		
		// remove selection, since new content might lead to a new selected items
		select(nil)
		
		// remove items that aren't in the content any more
		attributedMenu?.items.forEach{ item in
			if !content.contains(where: { $0.attributedTitle.string == item.attributedTitle?.string || $0.attributedTitle.string == item.title }) {
				removeItem(item)
			}
		}
		
		// update the menu with new content
		content.forEach { unit in
			if let item = item(withTitle: unit.attributedTitle.string) {
				item.action = unit.selector
				item.target = unit.target
				item.representedObject = unit.representedObject
				return
			}
			
			let item = NSMenuItem(title: unit.attributedTitle.string, action: nil, keyEquivalent: "")
			item.attributedTitle = unit.attributedTitle
			item.action = unit.selector
			item.target = unit.target
			item.representedObject = unit.representedObject
			attributedMenu?.addItem(item)
		}
	}
}

