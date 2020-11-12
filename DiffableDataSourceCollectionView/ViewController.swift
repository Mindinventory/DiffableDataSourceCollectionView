//
//  ViewController.swift
//  DiffableDataSourceCollectionView
//
//  Created by mac-00010 on 10/11/2020.
//

import UIKit

class ViewController: UIViewController {

    enum Section: Int, CaseIterable {
        case grid
        case list
        case outline
    }
    
    struct Item: Hashable {
        var title: String?
        var symbol: SymbolItem?
        var isChild: Bool
        
        init(title: String? = nil, symbol: SymbolItem? = nil, isChild: Bool = false) {
            self.title = title
            self.symbol = symbol
            self.isChild = isChild
        }
        
        private let identifier = UUID()
    }
    
    var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    
    var itemSection = ItemSection()
    
    @IBOutlet weak var collView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collView.collectionViewLayout = createLayout()
        configureDataSource()
        applySnapshot()
    }
}

extension ViewController {
    
    private func deleteItemOnSwipe(item: Item) -> UISwipeActionsConfiguration? {
        
        let actionHandler: UIContextualAction.Handler = { action, view, completion in
            
            completion(true)
            
            var snapShot = self.dataSource.snapshot()
            snapShot.deleteItems([item])
            self.dataSource.apply(snapShot)
        }
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete", handler: actionHandler)
        deleteAction.image = UIImage(systemName: "trash")
        deleteAction.backgroundColor = .red
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    private func createLayout() -> UICollectionViewLayout {
        
        let sectionProvider = {(sectionIndex: Int, layout: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            guard let sectionKind = Section(rawValue: sectionIndex) else { return nil }

            let section: NSCollectionLayoutSection
            
            switch sectionKind {
            
            //... create layout for grid section
            case .grid:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.18), heightDimension: .fractionalWidth(0.2))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 10
                section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)

            //... create layout for list section
            case .list:
                var configution = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
                
                configution.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in

                    guard let `self` = self else { return nil }
                    
                    let selectedItem = self.dataSource.itemIdentifier(for: indexPath)
                    return self.deleteItemOnSwipe(item: selectedItem!)
                }
                
                section = NSCollectionLayoutSection.list(using: configution, layoutEnvironment: layout)

            //... create layout for outline section
            case .outline:
                let configution = UICollectionLayoutListConfiguration(appearance: .plain)
                section = NSCollectionLayoutSection.list(using: configution, layoutEnvironment: layout)

            }

            return section
        }
        
        return UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
    }
    
    private func configureGridCell() -> UICollectionView.CellRegistration<UICollectionViewCell, Item> {
        
        return UICollectionView.CellRegistration<UICollectionViewCell, Item> { (cell, indexpath, item) in

            //...Default content configuration
            var content = UIListContentConfiguration.cell()
            content.image = UIImage(systemName: item.symbol?.title ?? "")
            cell.contentConfiguration = content
            
            //... Update background default selection color
            var bgConfig = UIBackgroundConfiguration.listPlainCell()
            bgConfig.backgroundColor = .white
            bgConfig.cornerRadius = 10
            bgConfig.strokeColor = .gray
            bgConfig.strokeWidth = 1
            cell.backgroundConfiguration = bgConfig
        }
    }
    
    private func configureListCell() -> UICollectionView.CellRegistration<UICollectionViewListCell, Item> {
        
        return UICollectionView.CellRegistration<UICollectionViewListCell, Item> { (cell, indexPath, item) in
         
            var content = cell.defaultContentConfiguration()
            content.text = item.symbol?.title
            content.image = UIImage(systemName: item.symbol?.title ?? "")
            cell.contentConfiguration = content
            
            //... Update background default selection color
            var bgConfig = UIBackgroundConfiguration.listPlainCell()
            bgConfig.backgroundColor = .white
            cell.backgroundConfiguration = bgConfig
        }
    }
    
    private func configureOutlineHeaderCell() -> UICollectionView.CellRegistration<UICollectionViewListCell, Item> {
        
        return UICollectionView.CellRegistration<UICollectionViewListCell, Item> { (cell, indexPath, item) in

            var content = cell.defaultContentConfiguration()
            content.text = item.title
            cell.contentConfiguration = content
            
            let headerDisclosureOption = UICellAccessory.OutlineDisclosureOptions(style: .header)
            cell.accessories = [.outlineDisclosure(options:headerDisclosureOption)]
        }
    }
    
    private func configureOutlineSubCell() -> UICollectionView.CellRegistration<UICollectionViewListCell, Item> {
        
        return UICollectionView.CellRegistration<UICollectionViewListCell, Item> { (cell, indexPath, item) in
         
            var content = cell.defaultContentConfiguration()
            content.secondaryText = item.symbol?.title
            content.image = UIImage(systemName: item.symbol?.title ?? "")
            cell.contentConfiguration = content
        }
    }
    
    private func configureDataSource() {
        
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collView, cellProvider: { [self](collectionView, indexPath, item) -> UICollectionViewCell? in
            
            if let section = Section(rawValue: indexPath.section) {
                
                switch section {
                case .grid:
                    return collectionView.dequeueConfiguredReusableCell(using: configureGridCell(), for: indexPath, item: item)
                    
                case .list:
                    return collectionView.dequeueConfiguredReusableCell(using: configureListCell(), for: indexPath, item: item)
                    
                case .outline:

                    if (item.isChild) {
                        return collectionView.dequeueConfiguredReusableCell(using: configureOutlineHeaderCell(), for: indexPath, item: item)
                    } else {
                        return collectionView.dequeueConfiguredReusableCell(using: configureOutlineSubCell(), for: indexPath, item: item)
                    }
                }
            }
            return UICollectionViewCell()
        })
    }
    
    private func applySnapshot() {
     
        //...Apply grid snapshot to data source
        var gridSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
        let gridItems = itemSection.gridItem.map { Item(symbol: $0) }
        gridSnapshot.append(gridItems)
        dataSource.apply(gridSnapshot, to: .grid, animatingDifferences: false)

        //...Apply list snapshot to data source
        var listSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
        let listItems = itemSection.gridItem.map { Item(symbol: $0) }
        listSnapshot.append(listItems)
        dataSource.apply(listSnapshot, to: .list, animatingDifferences: false)

        var outlineSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()

        for item in itemSection.outlineItem {
            
            //...Append header item to snapshot
            let outlineItem = Item(title: item.title, isChild: true)
            outlineSnapshot.append([outlineItem])
            
            //...Add sub item to headerItem and then add sub item to outline snapshot
            let subItem = item.symbol.map{ Item(symbol: $0)}
            outlineSnapshot.append(subItem, to: outlineItem)
        }
        
        //...Apply outline snapshot to data source
        dataSource.apply(outlineSnapshot, to: .outline, animatingDifferences: false)
    }
}
