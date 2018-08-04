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
    
    var dataController: DataController!
    var mapPress = UILongPressGestureRecognizer()
    let fetch: NSFetchRequest<Pin> = Pin.fetchRequest()
    let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
    
    @IBOutlet weak var map: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapPress = UILongPressGestureRecognizer(target: self, action: #selector(setPinOnMap(sender:)))
        
        map.addGestureRecognizer(mapPress)
        
        loadPinsOnMap()
    }

    @objc func setPinOnMap(sender: UILongPressGestureRecognizer) {
        
        let touchPoint = sender.location(in: map)
        let touchCoordinate = map.convert(touchPoint, toCoordinateFrom: map)
        
        let pointAnnotation = MKPointAnnotation()
        pointAnnotation.coordinate = touchCoordinate
        map.addAnnotation(pointAnnotation)
        
        savePinData(annotation: pointAnnotation)
        
    }
    
    func savePinData(annotation: MKPointAnnotation) {
        
        let newPin = Pin(context: self.dataController.viewContext)
        newPin.latitude = annotation.coordinate.latitude as Double
        newPin.longitude = annotation.coordinate.longitude as Double
        
        try? self.dataController.viewContext.save()
        
    }
    
    func setPinOnMap(_ pin: Pin) {
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin.latitude), longitude: CLLocationDegrees(pin.longitude))
        
        map.addAnnotation(annotation)
        
    }
    
    func loadPinsOnMap() {
        if let pins = try? dataController.viewContext.fetch(fetch) {
            
            for pin in pins {
                setPinOnMap(pin)
            }
            
        }
    }
    
    
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        performSegue(withIdentifier: "Photos", sender: view.annotation!.coordinate)
        
        map.deselectAnnotation(view.annotation, animated: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Photos" {
            let destination = segue.destination as! PhotosViewController
            let coordinate = sender as! CLLocationCoordinate2D
            destination.location = coordinate
            
            let fetchedPins = try? dataController.viewContext.fetch(fetch)
            
            for pin in fetchedPins! {
                
                if pin.latitude == coordinate.latitude && pin.longitude == coordinate.longitude {
                    
                    destination.selectedPin = pin
                    destination.dataController = dataController
                    
                    
                    break
                }
            }
            
        }
    }

}

