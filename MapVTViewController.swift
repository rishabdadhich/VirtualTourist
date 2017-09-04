//
//  MapVTViewController.swift
//  VirtualTourist
//
//  Created by Rishabh on 13/06/1939 Saka.
//  Copyright © 1939 Saka rishi. All rights reserved.
//

import UIKit
import Foundation
import CoreData
import MapKit

class MapVTViewController: UIViewController,MKMapViewDelegate {
     //outlets
    @IBOutlet weak var deletionLabel: UILabel!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var MapVTMapView: MKMapView!
    
    // variable
    var userPins : [Pin] = []
    var userSelectedPin : Pin!
    var isEditingMode : Bool = false
    
    
    
    override func viewDidLoad() {
      
        super.viewDidLoad()

       
        //call to delegate self
        
        MapVTMapView.delegate = self
        
        // change text of deletion label
        deletionLabel.text = "Hold press to drop Pin or delete Existinng Pin"
        
        // get user core data stored pins
        getStoredPins()
        
        //display pins from stored pins
        MapVTMapView.addAnnotations(userPins)
        //add touch to create pin map annotation
        let holdPress:UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addUserPin))
        holdPress.minimumPressDuration = 1.2
        MapVTMapView.addGestureRecognizer(holdPress)
        
        
    }
    
    @IBAction func segmentMapAction(_ sender: UISegmentedControl) {
        
        switch (sender.selectedSegmentIndex) {
        case 0:
            MapVTMapView.mapType = .standard
        case 1:
            MapVTMapView.mapType = .satellite
        case 2:
            MapVTMapView.mapType = .hybrid
        default:
            MapVTMapView.mapType = .standard
        }
    }

    @IBAction func editButtonPressed(_ sender: Any) {
        // first execution will happen in else statement as isEditingMode default is set to False
        // after pressing done on edit button
        
        if isEditingMode{
            isEditingMode = false
            editButton.title = "Edit"
            
            // after deletion give info
            deletionLabel.text = "Create New Pin Or Select Pin For Photos"
            
            // save after user press done with pins
            CoreDataStack.sharedInstance().saveContext()
            print("user saved pin")
        }
            //default
            else{
                isEditingMode = true
            editButton.title = "Done"
            deletionLabel.text = "Touch Pins to Delete"
            }
        
    }

    // mapview
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        //deselect the pin because it can't b selected again if we come back after opening photo album
        mapView.deselectAnnotation(view.annotation, animated: true)
        
        let mapPinFetch:NSFetchRequest<Pin> = Pin.fetchRequest()
        
        //  Core Data Double stores too much high precision in .000000000000 Values. We can remove that much precision & only use till .00001
        let precision = 0.00001
        
        let lowerBLatitude  = (view.annotation?.coordinate.latitude)! - precision
        let lowerBLongitude = (view.annotation?.coordinate.longitude)! - precision
        let upperBLatitude  = (view.annotation?.coordinate.latitude)! + precision
        let upperBLongitude  = (view.annotation?.coordinate.longitude)! + precision
        
        //NS Predicate Syntax for getting the pins on Latitude & longitude respectively
        // Took help for NSPRedicate Syntax from http://nshipster.com/nspredicate/ , https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/Predicates/Articles/pSyntax.html
        mapPinFetch.predicate = NSPredicate(format: "(%K BETWEEN {\(lowerBLatitude) , \(upperBLatitude)}) AND (%K BETWEEN {\(lowerBLongitude), \(upperBLongitude) })", #keyPath(Pin.latitude) , #keyPath(Pin.longitude) )
        
        var resultsPin : [Pin] = []
        
        do {
          resultsPin = try CoreDataStack.sharedInstance().persistentContainer.viewContext.fetch(mapPinFetch)
            
        } catch  {
            print("couldn't get the results pin via NSPredicate ")
            
        }
        
        if isEditingMode{
            // run the resultsPin variable after fetching via NSPredicate
            
            // Edit button has pressed and IbAction set bool isEditingMode = true
            if resultsPin.count > 0{
                // remove map annotations of pin
                mapView.removeAnnotation(resultsPin.first!)
                print("pin removed from map view")
                
                // delete the core data
                CoreDataStack.sharedInstance().persistentContainer.viewContext.delete(resultsPin.first!)
                print("pin removed from core data")
                
                //save 
                CoreDataStack.sharedInstance().saveContext()
            }
            else{
                print("couldn't fetch pins to delete")
                
            }
        }
            // edit button is not pressed and IBAction set bool isEditingMode = false
            
            // default execution
            
        else{
            if resultsPin.count > 0{
                userSelectedPin = resultsPin.first
                
                //open the photo album on pin selection
                
                let detailController = self.storyboard!.instantiateViewController(withIdentifier: "PhotoVTViewController") as! PhotoVTViewController
                detailController.mapSegueSelectedPin = userSelectedPin
                
                // perform transition on mqin thread
                
                DispatchQueue.main.async {
                    self.navigationController!.pushViewController(detailController, animated: true)
                }
                }
            else{
                print("unable to find pins for core data")
            }
        }
    }
    // add pins when user holds the touch gesture for more than 1.2 secs
    func addUserPin(gesture:UIGestureRecognizer) {
        if gesture.state == UIGestureRecognizerState.began{
            print("input gesture recieved")
            
            let touch = gesture.location(in: MapVTMapView)
            let convertedCoordinates = MapVTMapView.convert(touch, toCoordinateFrom: MapVTMapView)
            
            // update view with pin
            // get pin context and update object
            let newPin = Pin(context: CoreDataStack.sharedInstance().persistentContainer.viewContext)
            newPin.latitude = convertedCoordinates.latitude
            newPin.longitude = convertedCoordinates.longitude
            
            MapVTMapView.addAnnotation(newPin)
            
            deletionLabel.text = "Select Pin For Photos"
            
            // get flickr photos from that pin
            FlickrParseClient.sharedInstance().parsePhotoURLFromFlickrJSON(pin: newPin, managedcontext: CoreDataStack.sharedInstance().persistentContainer.viewContext)
            
            // save pin to core data
            do {
                try CoreDataStack.sharedInstance().persistentContainer.viewContext.save()
            }
            catch{
                print("couldn't save pin to core data")
            }
        }
        }
    // retrieve core data pins stored from the user data
    func getStoredPins(){
        do {
          userPins = try CoreDataStack.sharedInstance().persistentContainer.viewContext.fetch(Pin.fetchRequest())
        } catch  {
            print("couldn't fetch user stored pins from core data stack")
        }
    }
    
    // segue 
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "seguePhotoViewController"{
            
            let controller = segue.destination as! PhotoVTViewController
            controller.mapSegueSelectedPin = userSelectedPin
    }
   
   }
}
