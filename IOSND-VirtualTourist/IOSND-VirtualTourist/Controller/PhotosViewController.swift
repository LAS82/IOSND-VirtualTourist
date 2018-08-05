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
    
    //MARK: - Properties
    @IBOutlet weak var newImagesButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var location: CLLocationCoordinate2D!
    
    var selectedPin: Pin!
    
    let dispatchGroup = DispatchGroup()
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    var insertedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!
    var updatedIndexPaths: [IndexPath]!
    
    //MARK: - View Functions
    
    //Recovers saved images
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        getFetchedResults()
        enableNewImagesButton(true)
    }
    
    //Gets new images if there isn't any already image on the database
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        if let photos = fetchedResultsController.fetchedObjects {
            
            if photos.count == 0 {
                
                getPhotoURLs()
            }
        }
    }
    
    //Cleans the objects
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        fetchedResultsController = nil
        selectedPin = nil
    }
    
    
    //MARK: - Collection view methods
    
    //Gets the number of objects
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    //Configures the cell
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
        self.setCellConfigurations(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    //Removes the tapped photo
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let selectedCell = collectionView.cellForItem(at: indexPath) as! ImageCell
        let photo = fetchedResultsController.object(at: indexPath)
        
        dataController.viewContext.delete(photo)
        setCellConfigurations(selectedCell, atIndexPath: indexPath)
    }
    
    //MARK: - Fetched data functions
    
    //Cleans data
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        insertedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
    }
    
    //Controls the index paths
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
            break
        }
    }
    
    //Updates content
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
            
        }, completion: nil)
    }
    
    
    //MARK: - Event methods
    
    //Get new photos
    @IBAction func newImagesButtonClicked(_ sender: Any) {
        
        deleteAllPhotos()
        
        enableNewImagesButton(false)
        getPhotoURLs()
        enableNewImagesButton(true)
    }
    
    
    //MARK: - Other methods
    
    //Process the fetched results
    func getFetchedResults() {
        
        let fetchRequest: NSFetchRequest = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin = %@", selectedPin)
        
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        do {
            
            try fetchedResultsController.performFetch()
        } catch {
            
            showSimpleAlert(caption: "Photos", text: error.localizedDescription, okHandler: nil)
        }
    }
    
    //Process' loaded photos from Flickr
    func processLoadedPhotos() {
        if let _ = fetchedResultsController?.fetchedObjects {
            
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
    
    //Calls the Flickr API and get images
    func getPhotoURLs() {
        let complete: (String) -> Void = { errorMessage in
            if errorMessage == "" {
                
                DispatchQueue.main.async {
                    
                    self.processLoadedPhotos()
                }
            }
            else {
                
                self.showSimpleAlert(caption: "Photos", text: errorMessage, okHandler: nil)
            }
        }
        
        let flickr = Flickr()
        flickr.searchPhotosByRegion(location: location, completionHandler: complete)
    }
    
    //Configures a cell
    func setCellConfigurations(_ cell: ImageCell, atIndexPath indexPath: IndexPath) {
        
        let photo = self.fetchedResultsController.object(at: indexPath)
        let deadline = DispatchTime.now() + 0.1
        
        if photo.placeholder == true {
            
            setActivityIndicator(cell, true, imageData: nil)
            
            cell.imageView.image = UIImage(data: photo.imageData!)
            
            DispatchQueue.main.asyncAfter(deadline: deadline) {
                
                self.dispatchGroup.enter()
                
                DispatchQueue.global(qos: .background).async {
                    
                    let imageData = try? Data(contentsOf: URL(string: photo.imageURL!)!)
                    
                    photo.setValue(imageData, forKey: "imageData")
                    photo.setValue(false, forKey: "placeholder")
                    photo.setValue(Date(), forKey: "downloadDate")
                    
                    self.setData(onPhoto: photo, imageData: imageData!, indexPath: indexPath)
                    
                    DispatchQueue.main.async {
                        
                        self.setActivityIndicator(cell, false, imageData: photo.imageData)
                        self.dispatchGroup.leave()
                    }
                    
                    self.dispatchGroup.notify(queue: DispatchQueue.main) {
                        
                        self.enableNewImagesButton(true)
                        self.collectionView.reloadData()
                    }
                }
            }
            
        } else {
            
            setActivityIndicator(cell, false, imageData: photo.imageData)
        }
    }
    
    //Removes all photos from selected pin
    func deleteAllPhotos() {
        
        for photo in fetchedResultsController.fetchedObjects! {
            
            dataController.viewContext.delete(photo)
        }
    }
    
    //Enables or disables the new images button
    func enableNewImagesButton(_ enable: Bool) {
        
        newImagesButton.isEnabled = enable
    }
    
    //Starts or stops activity indicator for a cell
    func setActivityIndicator(_ forCell: ImageCell, _ activate: Bool, imageData: Data?) {
        
        if activate {
            
            forCell.activityIndicator.hidesWhenStopped = true
            forCell.activityIndicator.color = UIColor.black
            forCell.imageView.image = UIImage(named: "placeholder")
            
            forCell.activityIndicator.startAnimating()
        }
        else {
            
            forCell.imageView.image = UIImage(data: imageData!)
            forCell.activityIndicator.stopAnimating()
        }
    }
    
    //Sets data on Photo objects
    func setData(onPhoto: Photo, imageData: Data, indexPath: IndexPath) {
        
        onPhoto.setValue(imageData, forKey: "imageData")
        onPhoto.setValue(false, forKey: "placeholder")
        onPhoto.setValue(Date(), forKey: "downloadDate")
    }
    
}
