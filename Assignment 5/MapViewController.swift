//  Marco Cabrera - CS 646 iOS Development
//  MapViewController.swift
//  Assignment 5
//  Copyright © 2015 Marco Cabrera. All rights reserved.

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {

	@IBOutlet weak var map: MKMapView!
	var user: User!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.map.delegate = self
    }
    
	func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
		let annotationView = MKPinAnnotationView()
		annotationView.pinTintColor = MKPinAnnotationView.redPinColor()
		return annotationView
	}
	
	func mapView(mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
		let mapSpan = map.region.span
		let mapCenter = map.region.center
		let minimumLat = mapCenter.latitude - mapSpan.latitudeDelta / 2
		let minimumLong = mapCenter.longitude - mapSpan.longitudeDelta / 2
		let maximumLat = mapCenter.latitude + mapSpan.latitudeDelta / 2
		let maximumLong = mapCenter.longitude + mapSpan.longitudeDelta / 2
		let images = user.imagesInRange(loc1: (latitude: minimumLat, longitude: minimumLong), loc2: (latitude: maximumLat, longitude: maximumLong))
		
		images.forEach{ image in
			let pointAnnotation = MKPointAnnotation()
			pointAnnotation.coordinate = CLLocationCoordinate2D(latitude: image.location.latitude, longitude: image.location.longitude)
			map.addAnnotation(pointAnnotation)
		}
	}

}
