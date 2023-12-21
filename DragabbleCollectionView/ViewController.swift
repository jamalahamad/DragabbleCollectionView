//
//  ViewController.swift
//  DragabbleCollectionView
//
//  Created by Jamal Ahamad on 13/05/20.
//  Copyright © 2020 Jamal Ahamad. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIGestureRecognizerDelegate {
    @IBOutlet weak var topCollectionView: UICollectionView!
    @IBOutlet weak var bottomCollectionView: UICollectionView!
    
    var vm = viewModel()
    var topArray: [String] = []
    var bottomArray: [String] = []
    var dragItemIndex: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        topArray = vm.topArray
        bottomArray = vm.bottomArray
        setupCollectionView()
    }
    
    func setupCollectionView() {
        self.topCollectionView.delegate = self
        self.topCollectionView.dataSource = self
        self.bottomCollectionView.delegate = self
        self.bottomCollectionView.dataSource = self
        self.topCollectionView.dragDelegate = self
        self.bottomCollectionView.dragDelegate = self
        self.topCollectionView.dropDelegate = self
        self.bottomCollectionView.dropDelegate = self
        self.topCollectionView.dragInteractionEnabled = true
        self.bottomCollectionView.dragInteractionEnabled = true
        
        self.topCollectionView.register(UINib(nibName: "\(topCollectionViewCell.self)", bundle: nil), forCellWithReuseIdentifier: "\(topCollectionViewCell.self)")
        self.bottomCollectionView.register(UINib(nibName: "\(bottomCollectionViewCell.self)", bundle: nil), forCellWithReuseIdentifier: "\(bottomCollectionViewCell.self)")
    }
    
    private func reorderItems(coordinator: UICollectionViewDropCoordinator, destinationIndexPath: IndexPath, collectionView: UICollectionView) {
        let items = coordinator.items
        if items.count == 1, let item = items.first, let sourceIndexPath = item.sourceIndexPath {
            var dIndexPath = destinationIndexPath
            if dIndexPath.row >= collectionView.numberOfItems(inSection: 0) {
                dIndexPath.row = collectionView.numberOfItems(inSection: 0) - 1
            }
            collectionView.performBatchUpdates({
                if collectionView === self.bottomCollectionView {
                    self.bottomArray.remove(at: sourceIndexPath.row)
                    self.bottomArray.insert(item.dragItem.localObject as! String, at: dIndexPath.row)
                } else {
                    self.topArray.remove(at: sourceIndexPath.row)
                    self.topArray.insert(item.dragItem.localObject as! String, at: dIndexPath.row)
                }
                collectionView.deleteItems(at: [sourceIndexPath])
                collectionView.insertItems(at: [dIndexPath])
            })
            coordinator.drop(items.first!.dragItem, toItemAt: dIndexPath)
        }
    }
    
    private func copyItems(coordinator: UICollectionViewDropCoordinator, destinationIndexPath: IndexPath, collectionView: UICollectionView) {
        collectionView.performBatchUpdates({
            var indexPaths = [IndexPath]()
            for (index, item) in coordinator.items.enumerated() {
                var indexPath = IndexPath(row: destinationIndexPath.row + index, section: destinationIndexPath.section)
                if let destIndex = self.dragItemIndex {
                    indexPath = destIndex
                }
                if collectionView === self.bottomCollectionView {
                     
                    self.bottomArray.insert(item.dragItem.localObject as! String, at: indexPath.row)
                } else {
                    self.topArray.insert(item.dragItem.localObject as! String, at: indexPath.row)
                }
                indexPaths.append(indexPath)
            }
            collectionView.insertItems(at: indexPaths)
        })
    }
}

// MARK:- collectionview data source and delegate

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == topCollectionView {
            return topArray.count
        } else if collectionView == bottomCollectionView {
            return bottomArray.count
        } else {
            return 0
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == topCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(topCollectionViewCell.self)", for: indexPath) as! topCollectionViewCell
            cell.lblTop.text = topArray[indexPath.row]
            return cell
        } else if collectionView == bottomCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(bottomCollectionViewCell.self)", for: indexPath) as! bottomCollectionViewCell
            cell.lblBottom.text = bottomArray[indexPath.row]
            return cell
        } else {
            return  UICollectionViewCell()
        }
    }
}

// MARK:- flowlayout delegate

extension ViewController: UICollectionViewDelegateFlowLayout  {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 125, height: 60)
    }
}

// MARK:- collectionview drag drop delegate

extension ViewController: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let item = collectionView == topCollectionView ? self.topArray[indexPath.row] : self.bottomArray[indexPath.row]
        let itemProvider = NSItemProvider(object: item as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = item
        self.dragItemIndex = indexPath
        return [dragItem]
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        let item = collectionView == topCollectionView ? self.topArray[indexPath.row] : self.bottomArray[indexPath.row]
        let itemProvider = NSItemProvider(object: item as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = item
        self.dragItemIndex = indexPath
        return [dragItem]
    }
    
    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let previewParameters = UIDragPreviewParameters()
                   previewParameters.visiblePath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 125, height: 60))
                   return previewParameters
    }
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSString.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if collectionView === self.topCollectionView {
            if collectionView.hasActiveDrag {
                return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
            } else {
                return UICollectionViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
            }
        } else if collectionView == self.bottomCollectionView {
            if collectionView.hasActiveDrag {
                return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
            } else {
                return UICollectionViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
            }
        } else {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            let section = collectionView.numberOfSections - 1
            let row = collectionView.numberOfItems(inSection: section)
            destinationIndexPath = IndexPath(row: row, section: section)
        }
        
        switch coordinator.proposal.operation {
        case .move:
            self.reorderItems(coordinator: coordinator, destinationIndexPath:destinationIndexPath, collectionView: collectionView)
            break
            
        case .copy:
            self.copyItems(coordinator: coordinator, destinationIndexPath: destinationIndexPath, collectionView: collectionView)
            
        default:
            return
        }
    }
}
