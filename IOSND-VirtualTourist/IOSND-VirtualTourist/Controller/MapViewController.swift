//
//  ViewController.swift
//  IOSND-VirtualTourist
//
//  Created by Leandro Alves Santos on 22/07/18.
//  Copyright © 2018 Leandro Alves Santos. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
    
    //MARK: - Properties
    var dataController: DataController!
    var mapPress = UILongPressGestureRecognizer()
    let fetch: NSFetchRequest<Pin> = Pin.fetchRequest()
    
    @IBOutlet weak var map: MKMapView!
    
    //MARK: - View Functions
    
    //Loads the map
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        mapPress = UILongPressGestureRecognizer(target: self, action: #selector(setPinOnMap(sender:)))
        
        map.addGestureRecognizer(mapPress)
        
        loadPinsOnMap()
    }
    
    //MARK: - MapView functions
    
    //Configures pin
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let identifier = "travelPin"
        var pin = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
        
        if pin == nil {
            
            pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            pin!.canShowCallout = false
        } else {
            
            pin!.annotation = annotation
        }
        
        return pin
        
    }
    
    //Navigates to PhotosViewController
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        performSegue(withIdentifier: "Photos", sender: view.annotation!.coordinate)
        map.deselectAnnotation(view.annotation, animated: false)
    }
    
    //MARK: - Segue functions
    
    //Prepares data before go to PhotosViewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "Photos" {
            
            let photosViewController = segue.destination as! PhotosViewController
            let location = sender as! CLLocationCoordinate2D
            
            photosViewController.location = location
            
            let pins = try? dataController.viewContext.fetch(fetch)
            
            for pin in pins! {
                
                if pin.latitude == location.latitude && pin.longitude == location.longitude {
                    
                    photosViewController.selectedPin = pin
                    photosViewController.dataController = dataController
                    
                    break
                }
            }
            
        }
    }
    
    //MARK: - Pin functions

    //Sets a new Pin on the map
    @objc func setPinOnMap(sender: UILongPressGestureRecognizer) {
        
        let touchPoint = sender.location(in: map)
        let touchCoordinate = map.convert(touchPoint, toCoordinateFrom: map)
        
        let pointAnnotation = MKPointAnnotation()
        pointAnnotation.coordinate = touchCoordinate
        map.addAnnotation(pointAnnotation)
        
        savePinData(annotation: pointAnnotation)
        
    }
    
    //Saves the pin data on database
    func savePinData(annotation: MKPointAnnotation) {
        
        let newPin = Pin(context: self.dataController.viewContext)
        newPin.latitude = annotation.coordinate.latitude as Double
        newPin.longitude = annotation.coordinate.longitude as Double
        
        try? self.dataController.viewContext.save()
        
    }
    
    //Sets the pins on the map
    func setPinOnMap(_ pin: Pin) {
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin.latitude), longitude: CLLocationDegrees(pin.longitude))
        
        map.addAnnotation(annotation)
        
    }
    
    //Sets the pins on the map
    func loadPinsOnMap() {
        if let pins = try? dataController.viewContext.fetch(fetch) {
            
            for pin in pins {
                
                setPinOnMap(pin)
            }
            
        }
    }
}

