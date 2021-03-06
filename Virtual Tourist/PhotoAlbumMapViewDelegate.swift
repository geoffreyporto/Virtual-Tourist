//
//  PhotoAlbumMapViewDelegate.swift
//  Virtual Tourist
//
//  Created by Tobias Helmrich on 12.11.16.
//  Copyright © 2016 Tobias Helmrich. All rights reserved.
//

import UIKit
import MapKit

extension PhotoAlbumViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Create an annotation view with the specified annotation
        let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        
        // Get the custom pin image
        let pinImage = #imageLiteral(resourceName: "VTPin")
        
        // Set the annotation view's image property to the custom image and set
        // a center offset with a y-value of negative the half of the pin image's
        // height so that the bottom of the image points to the annotation view's
        // coordinate
        annotationView.image = pinImage
        annotationView.centerOffset = CGPoint(x: 0, y: -(pinImage.size.height / 2))
        return annotationView
    }
}
