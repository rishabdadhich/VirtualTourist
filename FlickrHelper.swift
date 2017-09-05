//
//  FlickrHelper.swift
//  VirtualTourist
//
//  Created by Rishabh on 12/06/1939 Saka.
//  Copyright © 1939 Saka rishi. All rights reserved.
//

import Foundation
import CoreData

extension FlickrParseClient {
    
    //Parse Image URLs from Flickr JSON Response Objects
    
    
    func parsePhotoURLFromFlickrJSON(pin selectedPin : Pin, managedcontext coreDataContext:NSManagedObjectContext ){
        
        
        // Parameters adding
        
        let flickrParameters : [String : String?] = [
            FlickrConstants.ParameterKeys.Method : FlickrConstants.ParameterValues.SearchMethod,
            FlickrConstants.ParameterKeys.APIKey : FlickrConstants.ParameterValues.APIKey,
            FlickrConstants.ParameterKeys.BBOX : FlickrParseClient.sharedInstance().bboxString(latitude: selectedPin.coordinate.latitude, longitude: selectedPin.coordinate.longitude),
            FlickrConstants.ParameterKeys.SearchType : FlickrConstants.ParameterValues.SafeSearch,
            FlickrConstants.ParameterKeys.Extras : FlickrConstants.ParameterValues.MediumURL,
            FlickrConstants.ParameterKeys.Format : FlickrConstants.ParameterValues.JSONFormat,
            FlickrConstants.ParameterKeys.JSONCallback : FlickrConstants.ParameterValues.NoJSONCallback,FlickrConstants.ParameterKeys.Page : FlickrConstants.ResponseKeys.Pages
            ]
        
        // Request Setup
        
        
        let getRequestSetup = FlickrParseClient.sharedInstance().getBuildURL(parameters: flickrParameters as [String : AnyObject])
        
        
        let task = URLSession.shared.dataTask(with: getRequestSetup) {
            data , response , error in
            
            // guard statements incoming
            
            guard let data = data else {
                print("Data not present,")
                //Debug print
                print("Error in InitTask Guard Statement")
                
                return
            }
            
            guard error == nil else {
                print("error present")
                //Debug print
                print("Error in InitTask Guard Statement")
                return
            }
            // Status code msgs
            guard let statusCodes = (response as? HTTPURLResponse)?.statusCode , statusCodes >= 200 && statusCodes <= 299 else {
                print("Wrong status codes returned")
                return
            }
            
            var parsedResult : [String:AnyObject]?
            
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:AnyObject]
                
                
                
            } catch {
                print(" Catched Error in JSON serialization Json Object creation")
                
            }
            
            
         
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult?[FlickrConstants.ResponseKeys.Photos] as? [String:AnyObject] else {
               print("Cannot find keys '\(FlickrConstants.ResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "pages" key in the photosDictionary? */
            guard let totalPages = photosDictionary[FlickrConstants.ResponseKeys.Pages] as? Int else {
               print("Cannot find key '\(FlickrConstants.ResponseKeys.Pages)' in \(photosDictionary)")
                return
            }
            
            // pick a random page!
            let pageLimit = min(totalPages, 40)
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
//            self.displayImageFromFlickrBySearch(flickrParameters as [String : AnyObject], withPageNumber: randomPage)
            self.displayImageFromFlickrBySearch(pin:selectedPin, flickrParameters as [String : AnyObject], withPageNumber: randomPage, managedcontext: coreDataContext)
        }
        
        
        // start the task!
        task.resume()
    }
    
    // FIX: For Swift 3, variable parameters are being depreciated. Instead, create a copy of the parameter inside the function.
    
    private func displayImageFromFlickrBySearch(pin selectedPin:Pin,_ methodParameters: [String: AnyObject], withPageNumber: Int,managedcontext coreDataContext:NSManagedObjectContext) {
        
        // add the page to the method's parameters
        var methodParametersWithPageNumber = methodParameters
        methodParametersWithPageNumber[FlickrConstants.ParameterKeys.Page] = withPageNumber as AnyObject?
        
        // Request Setup
        
        
        let getRequestSetup = FlickrParseClient.sharedInstance().getBuildURL(parameters: methodParameters as [String : AnyObject])
        
        // create network request
        let task = URLSession.shared.dataTask(with: getRequestSetup) { (data, response, error) in
            
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                print("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch {
                print("Could not parse the data as JSON: '\(data)'")
                return
            }

                        guard let photosDictionary = parsedResult?[FlickrConstants.ResponseKeys.Photos] as? [String:AnyObject],
                            let photosArray = photosDictionary[FlickrConstants.ResponseKeys.Photo] as? [[String:AnyObject]]
                            else {
                                print(" find \(FlickrConstants.ResponseKeys.Photos) and \(FlickrConstants.ResponseKeys.Photo) in \(parsedResult)")
                                return
                        }
            
                        guard photosArray.count > 0 else {
                            print("photosarray is empty.")
                            return
                        }
            
                        //Create the photoarraycount variable for easily traversing through the array index & print it.
                        let photosArrayCount = photosArray.count-1
                        print(photosArrayCount)
            
                        for photoindex in 0...photosArrayCount {
            
                            let photoDictionary = photosArray[photoindex] as [String:AnyObject]
            
                            guard let imageURLString = photoDictionary[FlickrConstants.ResponseKeys.MediumURL] as? String else {
                                print("Unable to locate image URL in photo dictionary")
                                return
                            }
            
                            // asynchronously run same thread
                            coreDataContext.perform {
            
                                // Create a photo object
                                let photo = Photo(context: coreDataContext)
            
                                //Debug Image URL Prints
                                print(imageURLString)
            
                                // Save the  url
                                photo.url = imageURLString
            
                                // Save the  photoindex
                                photo.index = photoindex + 1
            
                                // Make Bool isinAlbum = false
                                photo.isInAlbum = false
                                
                                // Save photo for selected pin
                                selectedPin.addToPhotos(photo)
                            }
                            
                        }
                        
            
                        // end of the photo passing loop creation
                        print("PhotoIndex Completed parsing through PhotoArraycount")
                        

            }
         // End of Task2
        
        
        
        task.resume()
        
        
    } // End of Function parsePhotoURLFromFlickrJSON
    
    func downloadImage( imagePath:String, completionHandler: @escaping (_ imageData: NSData?, _ errorString: String?) -> Void){
        let session = URLSession.shared
        let imgURL = NSURL(string: imagePath)
        let request: NSURLRequest = NSURLRequest(url: imgURL! as URL)
        
        let task = session.dataTask(with: request as URLRequest) {data, response, downloadError in
            
            if let _ = downloadError {
                completionHandler(nil, "Could not download image \(imagePath)")
            } else {
                
                completionHandler(data as NSData?, nil)
            }
        }
        
        task.resume()
    }
    
    
    
    //Convert Flickr URLs to  Image Data.
    func getImageDataFlickrURL (urlString : String) -> Data? {
        
        guard let url = URL(string: urlString),
            let imageData = try? Data(contentsOf: url) else {
                print("Error converting URL string to Image data")
                return nil
        }
        return imageData
    }
    




}

