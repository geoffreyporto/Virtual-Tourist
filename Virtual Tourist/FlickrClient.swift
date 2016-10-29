//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Tobias Helmrich on 25.10.16.
//  Copyright © 2016 Tobias Helmrich. All rights reserved.
//

import Foundation

class FlickrClient {
    
    // MARK: - Properties
    
    // Create a singleton and make sure that the FlickrClient class can't be instantiated anywhere else
    // by setting its init to the fileprivate access level
    static let shared = FlickrClient()
    fileprivate init() {}
    
    
    // MARK: - Methods
    
    func getImageUrls(forLatitude latitude: Double, andLongitude longitude: Double, withRadius radius: Double, completionHandlerForImageUrls: @escaping (_ imageUrls: [URL]?, _ errorMessage: String?) -> Void) {
        
        // Set the parameters
        let parameters: [String:Any] = [
            FlickrConstant.ParameterKey.apiKey: FlickrConstant.ParameterValue.apiKey,
            FlickrConstant.ParameterKey.format: FlickrConstant.ParameterValue.jsonFormat,
            FlickrConstant.ParameterKey.noJSONCallback: 1,
            FlickrConstant.ParameterKey.method: FlickrConstant.Method.photosSearch,
            FlickrConstant.ParameterKey.extras: FlickrConstant.ParameterValue.imageMediumUrl,
            FlickrConstant.ParameterKey.photosPerPage: 21,
            FlickrConstant.ParameterKey.lat: latitude,
            FlickrConstant.ParameterKey.lon: longitude,
            FlickrConstant.ParameterKey.radius: radius
        ]
        
        // Get the Flickr URL
        guard let url = createFlickrUrl(fromParameters: parameters) else {
            completionHandlerForImageUrls(nil, "Couldn't create Flickr URL")
            return
        }
        
        // Create the request
        let request = URLRequest(url: url)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            // Check if there was an error
            guard error == nil else {
                completionHandlerForImageUrls(nil, "Error: \(error!.localizedDescription)")
                return
            }
            
            // Check if the status code implies a successful response
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode,
                statusCode >= 200 && statusCode <= 299 else {
                    completionHandlerForImageUrls(nil, "Received unsuccessful status code")
                    return
            }
            
            // Check if data was received
            guard let data = data else {
                completionHandlerForImageUrls(nil, "No data received")
                return
            }
            
            // Deserialize the received data into a usable JSON object
            let jsonData: [String:Any]
            do {
                jsonData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
            } catch {
                completionHandlerForImageUrls(nil, "JSON deserialization error: \(error.localizedDescription)")
                return
            }
            
            // Get the array of photo dictionaries by extracting them from the JSON object
            guard let photos = jsonData[FlickrConstant.JSONResponseKey.photos] as? [String:Any],
                let photoArray = photos[FlickrConstant.JSONResponseKey.photoArray] as? [[String:Any]] else {
                    completionHandlerForImageUrls(nil, "Error when parsing JSON")
                    return
            }
            
            // Create an empty array of NSData objects and fill it by iterating over all the received image dictionaries
            // and using the images' URL string to create NSData objects from URLs
            var imageUrls = [URL]()
            for photo in photoArray {
                guard let currentImageUrlString = photo[FlickrConstant.JSONResponseKey.imageMediumUrl] as? String,
                    let currentImageUrl = URL(string: currentImageUrlString) else {
                        completionHandlerForImageUrls(nil, "Couldn't create URLs")
                        return
                }
                
                imageUrls.append(currentImageUrl)
                
            }
            
            // Call the completion handler and pass it the image data
            completionHandlerForImageUrls(imageUrls, nil)
            
        }
        
        task.resume()
        
    }
    
    func downloadImageData(fromUrl url: URL, completionHandlerForImageData: @escaping (_ data: NSData?, _ errorMessage: String?) -> Void) {
        // Create the request
        let request = URLRequest(url: url)
        
        // Make the request
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                completionHandlerForImageData(nil, error!.localizedDescription)
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode,
                statusCode >= 200 && statusCode <= 299 else {
                    completionHandlerForImageData(nil, "Unsuccessful status code \((response as? HTTPURLResponse)?.statusCode)")
                    return
            }
            
            guard let data = data else {
                completionHandlerForImageData(nil, "Didn't receive data")
                return
            }
            
            completionHandlerForImageData(data as NSData, nil)
            
        }
        
        task.resume()
        
    }
    
}


// MARK: - Helper Methods

extension FlickrClient {
    // This function creates a Flickr URL by taking a dictionary of parameters
    fileprivate func createFlickrUrl(fromParameters parameters: [String:Any]) -> URL? {
        
        // Create a URLComponents object and set its properties
        var urlComponents = URLComponents()
        urlComponents.scheme = FlickrConstant.Url.scheme
        urlComponents.host = FlickrConstant.Url.host
        urlComponents.path = FlickrConstant.Url.restApiPath
        
        
        // Create an empty array of URL query items and fill it with all the given parameters
        var queryItems = [URLQueryItem]()
        
        for (parameterKey, parameterValue) in parameters {
            let queryItem = URLQueryItem(name: parameterKey, value: "\(parameterValue)")
            queryItems.append(queryItem)
        }

        urlComponents.queryItems = queryItems
        return urlComponents.url
        
    }
}