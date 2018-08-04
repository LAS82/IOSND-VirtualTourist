//
//  PhotosViewController.swift
//  IOSND-VirtualTourist
//
//  Created by Leandro Alves Santos on 28/07/18.
//  Copyright © 2018 Leandro Alves Santos. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotosViewController : UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate  {
    
    
    @IBOutlet weak var newImagesButton: UIButton!

    @IBOutlet weak var collectionView: UICollectionView!
    
    
    var location: CLLocationCoordinate2D!
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var selectedPin: Pin!
    var pinGeoLocation: String!
    var insertedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!
    var updatedIndexPaths: [IndexPath]!
    var moveIndexPaths: [IndexPath]!
    var moveIndexNewPaths: [IndexPath]!
    var selectedPaths = [IndexPath]()
    let group = DispatchGroup()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFetchedResultsController()
        self.title = pinGeoLocation
        //collectionView.allowsMultipleSelection = true
        enableNewImagesButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let photos = fetchedResultsController.fetchedObjects {
            if photos.count == 0 {
                getPhotoURLs()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultsController = nil
        selectedPin = nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let width = floor(self.collectionView.frame.size.width/3)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }
    
    func deleteSelectedPhotos() {
        var photosToDelete = [Photo]()
        for indexPath in selectedPaths {
            photosToDelete.append(fetchedResultsController.object(at: indexPath))
        }
        for photo in photosToDelete {
            dataController.viewContext.delete(photo)
        }
        selectedPaths = [IndexPath]()
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin = %@", selectedPin)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = []
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("The fetch for photos failed: \(error.localizedDescription)")
        }
    }
    
    func setPlaceholders() {
        if let photos = fetchedResultsController?.fetchedObjects {
            if photos.count == 0 {
                for photoURL in Flickr.photosData {
                    let photo = Photo(context: dataController.viewContext)
                    photo.pin = selectedPin
                    photo.imageURL = photoURL
                    photo.imageData = UIImageJPEGRepresentation(UIImage(named: "placeholder")!, 1)
                    photo.placeholder = true
                    try? dataController.viewContext.save()
                }
            }
        }
    }
    
    func getPhotoURLs() {
        let complete: (String) -> Void = { errorMessage in
            if errorMessage == "" {
                DispatchQueue.main.async {
                    self.setPlaceholders()
                }
            }
            else {
                self.showSimpleAlert(caption: "Photos", text: errorMessage, okHandler: nil)
            }
        }
        let flickr = Flickr()
        flickr.searchPhotosByRegion(location: location, completionHandler: complete)
    }
    
    
    
    
    
    func configureCell(_ cell: ImageCell, atIndexPath indexPath: IndexPath) {
        cell.activityIndicator.hidesWhenStopped = true
        cell.activityIndicator.color = UIColor.black
        cell.imageView.image = UIImage(named: "placeholder")
        let aPhoto = self.fetchedResultsController.object(at: indexPath)
        if aPhoto.placeholder == true {
            cell.imageView.image = UIImage(data: aPhoto.imageData!)
            cell.activityIndicator.startAnimating()
            let delay = DispatchTime.now() + 0.2
            DispatchQueue.main.asyncAfter(deadline: delay) {
                if let imageURL = URL(string: aPhoto.imageURL!) {
                    self.group.enter()
                    DispatchQueue.global(qos: .background).async {
                        if let imageData = try? Data(contentsOf: imageURL) {
                            aPhoto.setValue(imageData, forKey: "imageData")
                            aPhoto.setValue(false, forKey: "placeholder")
                            aPhoto.setValue(Date(), forKey: "downloadDate")
                            DispatchQueue.main.async {
                                cell.imageView.image = UIImage(data: aPhoto.imageData!)
                                cell.activityIndicator.stopAnimating()
                                self.group.leave()
                            }
                        }
                        self.group.notify(queue: DispatchQueue.main) {
                            self.newImagesButton.isEnabled = true
                            self.collectionView.reloadData()
                        }
                    }
                }
            }
            
        } else {
            cell.imageView.image = UIImage(data: aPhoto.imageData!)
            cell.activityIndicator.stopAnimating()
        }
        if let _ = selectedPaths.index(of: indexPath) {
            cell.contentView.alpha = 0.2
        } else {
            cell.contentView.alpha = 1.0
            cell.layer.borderColor = UIColor.white.cgColor
            cell.layer.borderWidth = 1.0
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedCell = collectionView.cellForItem(at: indexPath) as! ImageCell
        configureCell(selectedCell, atIndexPath: indexPath)
        
        let photo = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photo)
        
    }
    
    
    
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
        moveIndexPaths = [IndexPath]()
        moveIndexNewPaths = [IndexPath]()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .update:
            updatedIndexPaths.append(indexPath!)
            break
        case .delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .move:
            moveIndexPaths.append(indexPath!)
            moveIndexNewPaths.append(newIndexPath!)
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({() -> Void in
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItems(at: [indexPath])
            }
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItems(at: [indexPath])
            }
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItems(at: [indexPath])
            }
            for i in 0..<self.moveIndexNewPaths.count {
                self.collectionView.moveItem(at: self.moveIndexNewPaths[i], to: self.moveIndexNewPaths[i])
            }
        }, completion: nil)
    }
    
    
    
    
    
    @IBAction func newImagesButtonClicked(_ sender: Any) {
        if selectedPaths.isEmpty {
            deleteAllPhotos()
            self.newImagesButton.isEnabled = false
            getPhotoURLs()
        } else {
            deleteSelectedPhotos()
        }
        enableNewImagesButton()
    }
    
    func deleteAllPhotos() {
        for photo in fetchedResultsController.fetchedObjects! {
            dataController.viewContext.delete(photo)
        }
    }
    
    func enableNewImagesButton() {
        newImagesButton.isEnabled = true
        if selectedPaths.isEmpty {
            newImagesButton.setTitle("New Collection", for: UIControlState.normal)
        } else {
            newImagesButton.setTitle("Delete Selected Photos", for: UIControlState.normal)
        }
    }
    
}
