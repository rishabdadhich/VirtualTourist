//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Rishabh on 12/06/1939 Saka.
//  Copyright © 1939 Saka rishi. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var image: NSData?
    @NSManaged public var index: Int16
    @NSManaged public var isInAlbum: Bool
    @NSManaged public var url: String?
    @NSManaged public var pins: Pin?

}
