//
//  TravelLocationsMapViewController.swift
//  Virtual Tourist
//
//  Created by Tobias Helmrich on 23.10.16.
//  Copyright © 2016 Tobias Helmrich. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController {

    // MARK: - Properties
    
    // This property keeps track of whether the pins on the map should be
    // deleted when they're tapped or not
    var isInDeleteMode = false
    var annotation: MKPointAnnotation = MKPointAnnotation()
    
    
    // MARK: - Outlets and Actions
    
    @IBOutlet weak var travelLocationsMapView: MKMapView!
    @IBOutlet weak var deleteInformationLabel: UILabel!
    
    @IBAction func toggleDeleteMode() {
        // Reverse isInDeleteMode's value, set the visibility of the deleteInformationLabel and
        // the right bar button item depending on its value
        isInDeleteMode = !isInDeleteMode
        deleteInformationLabel.isHidden = !isInDeleteMode
        if isInDeleteMode {
            navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(toggleDeleteMode))
        } else {
            navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(toggleDeleteMode))
        }
    }
    
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add a long press gesture recognizer to the map view in order to place an annotation
        // on the map after the user taps the map view with a long tap
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(placeAnnotation))
        travelLocationsMapView.addGestureRecognizer(longPressGestureRecognizer)
        
        // Set the map's region
        setStartRegion()
        
        // Get all pins from the view context and place them on the travel locations map view
        let fetchRequest = NSFetchRequest<Pin>(entityName: "Pin")
        do {
            let pins = try CoreDataStack.shared.persistentContainer.viewContext.fetch(fetchRequest)
            for pin in pins {
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                travelLocationsMapView.addAnnotation(annotation)
            }
            print(travelLocationsMapView.annotations.count)
        } catch {
            self.presentAlertController(withMessage: "Error when trying to get pins: \(error.localizedDescription)")
        }
        
    }
    
    // MARK: - Functions

    func placeAnnotation(sender: UILongPressGestureRecognizer) {
        // It should only be possible to place a pin when the delete mode
        // is not active
        if !isInDeleteMode {
            switch sender.state {
            case .began:
                // Create a new instance of MKPointAnnotation and set its initial coordinate
                // to the point the user tapped
                annotation = MKPointAnnotation()
                setCoordinate(forPointAnnotation: annotation, fromLongPressGestureRecognizer: sender)
                
                // Add the annotation to the map view
                travelLocationsMapView.addAnnotation(annotation)
            case .changed:
                // Every time the position of the user's finger changes, set a new
                // coordinate for the point to the new position of the finger and add
                // it to the map view again at its coordinate
                setCoordinate(forPointAnnotation: annotation, fromLongPressGestureRecognizer: sender)
                travelLocationsMapView.addAnnotation(annotation)
            case .ended:
                // When the tap ends, create a Pin managed object with the annotation's
                // coordinate and save the context
                let _ = Pin(withLatitude: annotation.coordinate.latitude, andLongitude: annotation.coordinate.longitude, intoContext: CoreDataStack.shared.persistentContainer.viewContext)
                CoreDataStack.shared.save()
            default:
                break
            }
        }
    }
    
    // This function should be used to set the region of the travelLocationsMapView
    // after starting the application
    // Note: The region could look slightly different compared to how it looked when
    // the app was closed as the "zoom" snaps to the closest "zoom level"
    func setStartRegion() {
        // Get the values needed to create a coordinate and coordinate span from the user defaults
        let startCenterLatitude = UserDefaults.standard.double(forKey: UserDefaultKey.currentCenterLatitude.rawValue)
        let startCenterLongitude = UserDefaults.standard.double(forKey: UserDefaultKey.currentCenterLongitude.rawValue)
        let startSpanLatitudeDelta = UserDefaults.standard.double(forKey: UserDefaultKey.currentSpanLatitudeDelta.rawValue)
        let startSpanLongitudeDelta = UserDefaults.standard.double(forKey: UserDefaultKey.currentSpanLongitudeDelta.rawValue)

        // Create center coordinate and coordinate span
        let centerCoordinate = CLLocationCoordinate2D(latitude: startCenterLatitude, longitude: startCenterLongitude)
        let span = MKCoordinateSpan(latitudeDelta: startSpanLatitudeDelta, longitudeDelta: startSpanLongitudeDelta)
        
        // Create and set the region from the center coordinate and span
        let startRegion = MKCoordinateRegion(center: centerCoordinate, span: span)
        travelLocationsMapView.setRegion(startRegion, animated: false)
    }
    
    func setCoordinate(forPointAnnotation annotation: MKPointAnnotation, fromLongPressGestureRecognizer longPressGestureRecognizer: UILongPressGestureRecognizer) {
        // Get the point on the travelLocationsMapView that was tapped with a long press
        let touchPoint = longPressGestureRecognizer.location(in: travelLocationsMapView)
        
        // Convert the position of the long press to a coordinate on the travelLocationsMapView,
        // create a point annotation with this coordinate,
        let tappedCoordinate = travelLocationsMapView.convert(touchPoint, toCoordinateFrom: travelLocationsMapView)
        
        annotation.coordinate = tappedCoordinate
    }
    
}
