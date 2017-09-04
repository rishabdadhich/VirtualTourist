//
//  FlickrParse.swift
//  VirtualTourist
//
//  Created by Rishabh on 12/06/1939 Saka.
//  Copyright © 1939 Saka rishi. All rights reserved.
//

import Foundation
class FlickrParseClient {
    
    // MARK: Shared Instance
    
    class func sharedInstance() -> FlickrParseClient {
        struct Singleton {
            static var sharedInstance = FlickrParseClient()
        }
        return Singleton.sharedInstance
    }
    
    
    
    // Reference : Used from "Flick Finder" Jarod Udacity, Created by Jarrod Parkes on 11/5/15.
    func bboxString( latitude : Double , longitude : Double ) -> String {
        
        // Checking Valid Map Coordinates
        if(latitude == 0.0 && longitude == 0.0) {
            return "0,0,0,0"
        }
        
        let minimumLon = max ( longitude - FlickrConstants.SearchBBoxHalfWidth , FlickrConstants.SearchLonRange.0)
        let minimumLat = max ( latitude - FlickrConstants.SearchBBoxHalfHeight , FlickrConstants.SearchLatRange.0)
        let maximumLon = max ( longitude - FlickrConstants.SearchBBoxHalfWidth , FlickrConstants.SearchLonRange.1)
        let maximumLat = max ( latitude - FlickrConstants.SearchBBoxHalfHeight , FlickrConstants.SearchLatRange.1)
        
        return "\(minimumLon) , \(minimumLat) , \(maximumLon) , \(maximumLat) "
        
    }
    
    
    // Build URL & return the request.
    
    func getBuildURL(parameters : [String:AnyObject]) -> URLRequest {
        
        // Building URL Components
        var components = URLComponents()
        components.scheme = FlickrConstants.APIScheme
        components.host   = FlickrConstants.APIHost
        components.path   = FlickrConstants.APIPath
        
        components.queryItems = [URLQueryItem]()
        
        for (keys , values) in parameters {
            let queryItem = URLQueryItem(name: keys, value: values as? String)
            components.queryItems?.append(queryItem)
        }
        
        if  components.url == nil
        {
            print("Error in URL Creation")
        }
        
        guard let urlrequested = components.url else {
            print("Error in URL Creation")
            let url2 = NSURL(string: "https://www.flickr.com/photos/flickr/30709520093/in/feed")
            let url = URLRequest.init(url: url2 as! URL)
            return url
        }
        
        
        let request = URLRequest(url: urlrequested)
        return request
        
        
}
}
