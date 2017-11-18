//  Marco Cabrera - CS 646 iOS Development
//  MainViewController.swift
//  Assignment 5
//  Copyright © 2015 Marco Cabrera. All rights reserved.

import UIKit

class MainViewController: UITableViewController, ImageDelegate {
	var user = User(name: "rew")
	
	override func viewDidLoad() {
		super.viewDidLoad()
		print(user.getID())
		self.refreshControl = UIRefreshControl()
		self.refreshControl!.addTarget(self, action: "reloadTableView", forControlEvents: .ValueChanged)
		self.refreshControl!.addTarget(self, action: "endRefreshing", forControlEvents: .TouchUpInside)
	}
	
	override func viewWillAppear(animated: Bool) {
		self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
		super.viewWillAppear(animated)
	}
	
	func addNewImage(image: Image?) {
		if let image = image {
			user.images.insert(image, atIndex: 0)
			user.sortImagesByDate()
			tableView.reloadData()
		}
	}
	
	func endRefreshing() {
		self.refreshControl!.endRefreshing()
	}
	
	func reloadTableView() {
		print("refresing")
		let imagesCopy = user.images
		user.images = []
		for image in imagesCopy where !image.isOnServer {
			user.images.append(image)
		}
		tableView.reloadData()
		let date1 = NSDate(timeIntervalSinceNow: 1 * -86400)
		let date2 = NSDate()
		user.updateImagesFromServer(date1: date1, date2: date2, imageUpdated: { _ in
			dispatch_async(dispatch_get_main_queue()){
				self.user.sortImagesByDate()
				self.tableView.reloadData()
			}
			print("Image has been updated")
			}) {
				dispatch_async(dispatch_get_main_queue()) {
					print("Finished refreshing")
					self.refreshControl!.endRefreshing()
					self.tableView.reloadData()
					print(self.user.images.count)
				}
        }
	}
	
	// Segues
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		endRefreshing()
		if let mapViewController = segue.destinationViewController as? MapViewController {
			mapViewController.user = user
			return
		}
		let destinationController = segue.destinationViewController as! ImageDataViewController
		destinationController.delegate = self
		
		if let indexPath = self.tableView.indexPathForSelectedRow {
			let pictureTaken = user.images[indexPath.row]
			destinationController.dataSource = pictureTaken
			
		}
		
	}
	
	// Table View
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return user.images.count
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
		cell.textLabel!.text = user.images[indexPath.row].description
		return cell
	}
	
	override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return true
	}
	
	override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
		if editingStyle == .Delete {
			user.images.removeAtIndex(indexPath.row)
			tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
		}
	}
	
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//    }
}

