//
//  Flickr.swift
//  IOSND-VirtualTourist
//
//  Created by Leandro Alves Santos on 28/07/18.
//  Copyright © 2018 Leandro Alves Santos. All rights reserved.
//

import UIKit
import MapKit

class Flickr {
    
    //MARK: - Properties
    static var photosData: [String] = []
    
    //MARK: - Public methods
    
    //Search photos on Flickr using coordinates received as parameter
    public func searchPhotosByRegion(location: CLLocationCoordinate2D, completionHandler: @escaping (String) -> Void) {
        
        Flickr.photosData.removeAll()
        
        let parameters: [String:String] = getParameters(location)
        let request = URLRequest(url: buildURLWithParameters(parameters: parameters))
        let sessionConfiguration = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfiguration)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            
            let errorMessage = self.verifyAPIProcessing(data: data, response: response, error: error)
            if(errorMessage != "") {
                completionHandler(errorMessage)
                return
            }
            
            var parsedResult: [String:Any]? = nil
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String:Any]
            } catch {
                completionHandler(error.localizedDescription)
                return
            }
            
            guard let status = parsedResult!["stat"] as? String, status == "ok" else {
                
                completionHandler("Some error occurs while downloading images")
                return
            }
            
            guard let photosObject = parsedResult!["photos"] as? [String:AnyObject] else {
                
                completionHandler("Some error occurs while downloading images")
                return
            }
            
            guard let photos = photosObject["photo"] as? [[String:AnyObject]] else {
                
                completionHandler("Some error occurs while downloading images")
                return
            }
            
            let errorMessageSettingImages = self.setPhotosData(photos: photos)
            if errorMessageSettingImages != "" {
                
                completionHandler(errorMessageSettingImages)
                return
            }
            
            completionHandler("")
            
        }
        task.resume()
        
    }
    
    //MARK: - Private Methods
    
    //Returns the Bounding Box based on coordinates received as parameter
    private func getLocationBBox(_ location: CLLocationCoordinate2D) -> String {
        
        let bboxHalfWidth = 0.05
        let bboxHalfHeight = 0.05
        let bboxLatitudeRange = (-90.0, 90.0)
        let bboxLongitudeRange = (-180.0, 180.0)
        
        let minLat = max(location.latitude - bboxHalfHeight, bboxLatitudeRange.0)
        
        let maxLat = min(location.latitude + bboxHalfHeight, bboxLatitudeRange.1)
        
        let minLong = max(location.longitude - bboxHalfWidth, bboxLongitudeRange.0)
        
        let maxLong = min(location.longitude + bboxHalfWidth, bboxLongitudeRange.1)
        
        return ("\(minLong),\(minLat),\(maxLong),\(maxLat)")
    }
    
    //Builds the URL with the parameters received as parameter
    private func buildURLWithParameters(parameters: [String:String]) -> URL {
        var urlComponents = URLComponents()
        
        urlComponents.scheme = "https"
        urlComponents.host = "api.flickr.com"
        urlComponents.path = "/services/rest"
        
        urlComponents.queryItems = [URLQueryItem]()
        for (name, value) in parameters {
            let urlQueryItem = URLQueryItem(name: name, value: value)
            urlComponents.queryItems?.append(urlQueryItem)
            
        }
        
        return urlComponents.url!
    }
    
    //Verifies if the process was executed with success
    private func verifyAPIProcessing(data: Data!, response:URLResponse!, error:Error!) -> String {
        
        guard (error == nil) else {
            
            return (error?.localizedDescription)!
        }
        
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
            
            return "The request returned a status other than 2xx"
        }
        
        guard data != nil else {
            
            return "No images was returned"
        }
        
        return ""
    }
    
    //Returns parameters to build the url
    private func getParameters(_ location: CLLocationCoordinate2D) -> [String:String] {
        return [
            Constants.ParameterKeys.method:Constants.ParameterValues.method,
            Constants.ParameterKeys.apiKey:Constants.ParameterValues.apiKey,
            Constants.ParameterKeys.safeSearch:Constants.ParameterValues.safeSearch,
            Constants.ParameterKeys.extras:Constants.ParameterValues.extras,
            Constants.ParameterKeys.perPage:Constants.ParameterValues.perPage,
            Constants.ParameterKeys.format:Constants.ParameterValues.format,
            Constants.ParameterKeys.noJSONCallback:Constants.ParameterValues.noJSONCallback,
            
            Constants.ParameterKeys.bBox : getLocationBBox(location),
            Constants.ParameterKeys.page : String(Int(arc4random_uniform(10)) + 1)
        ]
    }
    
    //Populates the photosData with the returned URLs
    private func setPhotosData(photos: [[String:AnyObject]]) -> String {
        
        for photo in photos {
            
            guard let url = photo["url_m"] as? String else {
                
                return "Some error occurs processing the downloaded images"
            }
            
            Flickr.photosData.append(url)
        }
        
        return ""
        
    }
    
    
}
