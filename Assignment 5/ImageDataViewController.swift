//  Marco Cabrera - CS 646 iOS Development
//  ImageDataViewController.swift
//  Assignment 5
//  Copyright © 2015 Marco Cabrera. All rights reserved.

import UIKit
import CoreLocation
import MobileCoreServices

protocol ImageDataSource {
	var uiImage: UIImage? { get set }
	var location: Location { get set }
	var description: String { get set }
	func upload()
}

protocol ImageDelegate {
	func addNewImage(image: Image?)
	var user: User { get }
}

class ImageDataViewController: UIViewController, CLLocationManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	let locationManager = CLLocationManager()
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var longitudeTextField: UITextField!
	@IBOutlet weak var latitudeTextField: UITextField!
	@IBOutlet weak var descriptionTextView: UITextView!
	var dataSource: ImageDataSource?
	var delegate: ImageDelegate!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		if let dataSource = dataSource {
			imageView.image = dataSource.uiImage
			descriptionTextView.text = dataSource.description
			longitudeTextField.text = String(dataSource.location.longitude)
			latitudeTextField.text = String(dataSource.location.latitude)
		}
		activityIndicator.hidden = true
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "saveData")
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow", name: UIKeyboardWillShowNotification, object: nil)
	}
	
	// This function shows the keyboar
	func keyboardWillShow() {
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "hideKeyboard")
	}
	
    // This function hides the keyboard
	func hideKeyboard() {
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "saveData")
		longitudeTextField.resignFirstResponder()
		latitudeTextField.resignFirstResponder()
		descriptionTextView.resignFirstResponder()
	}
	
	// Imagepicker
	@IBAction func imageFromDevice() {
		let alertMessage = UIAlertController(title: "Image Source", message: nil, preferredStyle: .ActionSheet)
		if UIImagePickerController.isSourceTypeAvailable(.Camera) {
			alertMessage.addAction(UIAlertAction(title: "Camera", style: .Default){ _ in
				self.showImagePicker(.Camera) })
		}
		alertMessage.addAction(UIAlertAction(title: "Image Library", style: .Default) { _ in
			self.showImagePicker(.PhotoLibrary) })
		alertMessage.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
		self.presentViewController(alertMessage, animated: true, completion: nil)
	}
	
	func showImagePicker(sourceType: UIImagePickerControllerSourceType) {
		let picker = UIImagePickerController()
		picker.delegate = self
		picker.mediaTypes = [kUTTypeImage as String]
		picker.sourceType = sourceType
		self.presentViewController(picker, animated: true, completion: nil)
	}
	
	func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
		self.imageView.image = image
		dismissViewControllerAnimated(true, completion: nil)
	}
	
	// CLLocation
	@IBAction func locate() {
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
		locationManager.requestWhenInUseAuthorization()
		locationManager.requestLocation()
		activityIndicator.hidden = false
		activityIndicator.startAnimating()
	}
	
	
	func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		activityIndicator.stopAnimating()
		activityIndicator.hidden = true
		guard let lastLocation = locations.last else {
			print("Location is nonexistent!")
			return }
		longitudeTextField.text = String(lastLocation.coordinate.longitude)
		latitudeTextField.text = String(lastLocation.coordinate.latitude)
		manager.stopUpdatingLocation()
	}
	
	func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
		activityIndicator.stopAnimating()
		activityIndicator.hidden = true
		let alertMessage = UIAlertController(title: "Problem finding location!", message: "Provide a location", preferredStyle: .Alert)
		alertMessage.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
		presentViewController(alertMessage, animated: true, completion: nil)
	}
	
	// This function updates the image and saves the data
	func saveData() {
		guard var dataSource = dataSource else {
			makeNewImageFromData()
			return
		}
		dataSource.location = (
			latitude: Double(latitudeTextField.text ?? "") ?? 0,
			longitude: Double(longitudeTextField.text ?? "") ?? 0)
		dataSource.uiImage = imageView.image
		dataSource.description = descriptionTextView.text
		dataSource.upload()
		popToMainViewController()
	}
	
	func makeNewImageFromData() {
		let image = Image(
			user: delegate.user,
			location: (
				latitude: Double(latitudeTextField.text ?? "") ?? 0,
				longitude: Double(longitudeTextField.text ?? "") ?? 0),
			description: descriptionTextView.text,
			date: NSDate(),
			image: imageView.image)
		image.upload()
		self.delegate.addNewImage(image)
		popToMainViewController()
	}
	
	func popToMainViewController() {
		self.navigationController!.popViewControllerAnimated(true)
	}
}

