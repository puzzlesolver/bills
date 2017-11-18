//  Marco Cabrera - CS 646 iOS Development
//  DataClasses.swift
//  Assignment 5
//  Copyright © 2015 Marco Cabrera. All rights reserved.

import UIKit
import CoreLocation

let lastThreeDigitsRedID = "015"
let typeOfReport = "street"
typealias Location = (longitude: Double, latitude: Double)

class User {
	var name: String
	var images = [Image]()
	
	func getID() -> String {
		let firstPart = lastThreeDigitsRedID.substringFromIndex(lastThreeDigitsRedID.startIndex.advancedBy(lastThreeDigitsRedID.characters.count-3))
		let secondPart = name.substringToIndex(name.startIndex.advancedBy(12, limit: name.endIndex))
		return firstPart + secondPart
	}
	
	init(name: String) {
		self.name = name
	}
	
	func imagesInRange(loc1 loc1: Location, loc2: Location) -> [Image] {
		return images.filter{ $0.isInRange(loc1: loc1, loc2: loc2) }
	}
	
	func uploadImagesToServer() {
		for image in images{
			image.uploadIt()
		}
	}
	
	func sortImagesByDate() {
		self.images.sortInPlace{ image1, image2 in
			image1.date.compare(image2.date) == NSComparisonResult.OrderedDescending
		}
	}
	
	// This function loads the images between dates from server. It iterates trough all the dates
	func updateImagesFromServer(date1 date1: NSDate, date2: NSDate, imageUpdated: Image->(), completion: ()->()) {
		print("dates: ", date1, date2)
		var i = 0
		var countDates = 0
		let dateFormatter = NSDateFormatter()
		dateFormatter.dateFormat = "MM/dd/yy"
		let dateString = dateFormatter.stringFromDate(date2.dateByAddingTimeInterval(86400))
		for(var actualDate = date1; dateFormatter.stringFromDate(actualDate) != dateString; actualDate = actualDate.dateByAddingTimeInterval(24*60*60)) {
                updateImagesFromServer(actualDate, imageUpdated: imageUpdated) {
                    if ++i == countDates {
                        completion()
                    }
                }
			countDates++
			print("date counter", countDates)
		}
	}
	
	// This function loads images from server and returns all reports for given user, type and date.
	func updateImagesFromServer(date: NSDate, imageUpdated: Image->(), completion: ()->()) {
		let formatter = NSDateFormatter()
		formatter.dateFormat = "MM/dd/yy"
		let dateString = formatter.stringFromDate(date)
		print("dateString: ", dateString)
		if let url = NSURL(string: "http://bismarck.sdsu.edu/city/fromDate?type=\(typeOfReport)&date=\(dateString)&user=\(self.getID())") {
			let request = NSURLRequest(URL: url)
			NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: requestClosure(imageUpdated, completion: completion)).resume()
		}
    }
	
	// Function which checks for the keys in the dictionary and loads the image
	func requestClosure(imageUpdated: Image->(), completion: ()->())(data: NSData?, response: NSURLResponse?, error: NSError?) -> () {
		
		print("ref closure")
		if	let data = data,
			let anyJson = (try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)),
			let arrayOfObjects = anyJson as? [[String : AnyObject]] {
				
				print("inside")
				print(arrayOfObjects)
				var imageCounter = 0
				var totalImageCount = 0
				
				if arrayOfObjects.isEmpty {
					completion()
				}
				
				for keysDictionary in arrayOfObjects {
					print(keysDictionary)
					
					// check keysDictionary
					if
						let id = keysDictionary["id"] as? Int,
						let latitude = keysDictionary["latitude"] as? Double,
						let longitude = keysDictionary["longitude"] as? Double,
						let description = keysDictionary["description"] as? String,
						let taken = keysDictionary["taken"] as? String {
							print("dict checked")
							let location = (latitude: latitude, longitude: longitude)
							
							let formatter = NSDateFormatter()
							formatter.dateFormat = "mm/dd/yy, hh:mm a"
							formatter.locale = NSLocale(localeIdentifier: "en")
							let date = formatter.dateFromString(taken)!
							totalImageCount++
							let request = NSURLRequest(URL: NSURL(string: "http://bismarck.sdsu.edu/city/image?id=\(id)")!)
							NSURLSession.sharedSession().dataTaskWithRequest(request) { data, request, error in
								print("Image has been uploaded")
								let photoTaken = data.flatMap(UIImage.init)
								let image = Image(
									user: self,
									location: location,
									description: description,
									date: date,
									image: photoTaken)
								
								image.isOnServer = true
								self.images.append(image)
								imageUpdated(image)
								
								imageCounter++
								print("image count= \(totalImageCount), counter = \(imageCounter)")
								
                                    if totalImageCount == imageCounter {
                                        completion()
                                    }
                                }.resume()
                    }
                }
        }
    }
}


class Image: ImageDataSource {
	unowned var user: User
	var location: Location
	var description: String
	var date: NSDate
	var uiImage: UIImage?
	var isOnServer = false
	
	init(user: User, location: Location, description: String, date: NSDate, image: UIImage?) {
		self.location = location
		self.uiImage = image
		self.description = description
		self.user = user
		self.date = date
	}
	
	func isInRange(loc1 loc1: Location, loc2: Location) -> Bool {
		let minLat = min(loc1.latitude, loc2.latitude)
		let maxLat = max(loc1.latitude, loc2.latitude)
		let minLong = min(loc1.longitude, loc2.longitude)
		let maxLong = max(loc1.longitude, loc2.longitude)
		return minLat <= location.latitude && location.latitude <= maxLat && minLong <= location.latitude && location.latitude <= maxLong
	}
	
	func upload() {
		isOnServer = false
		uploadIt()
	}
	
	func uploadIt() {
		if !isOnServer {
			let imageDataString: String
			let imageTypeString: String
			if	let image = uiImage,
				let imageString = UIImagePNGRepresentation(image)?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0)) {
					imageDataString = imageString
					imageTypeString = "png"
			} else {
				imageDataString = ""
				imageTypeString = "none"
			}
			let keysDictionary: [String : AnyObject] = [
				"type": "street",
				"user": user.getID(),
				"latitude": location.latitude,
				"longitude": location.longitude,
				"imagetype": imageTypeString,
				"description": description,
				"image": imageDataString
			]
			if let json = try? NSJSONSerialization.dataWithJSONObject(keysDictionary, options: .PrettyPrinted) {
				if let url = NSURL(string: "http://bismarck.sdsu.edu/city/report") {
					let request = NSMutableURLRequest(URL: url)
					request.HTTPBody = json
					request.HTTPMethod = "POST"
					request.setValue("application/json", forHTTPHeaderField: "Content-Type")
					NSURLSession.sharedSession().dataTaskWithRequest(request) { _,_,_ in
						self.isOnServer = true
						}.resume()
				}
			}
		}
	}
	
}

