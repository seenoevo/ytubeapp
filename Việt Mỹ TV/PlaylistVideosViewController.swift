//
//  PlaylistVideosViewController.swift
//  Việt Mỹ
//
//  Created by EVO on 2/20/16.
//  Copyright © 2016 VAYA. All rights reserved.
//

import UIKit

/*
 * Performs synchronous request
 * Must wait for this task to finish before starting another task.
 */
extension NSURLSession
{
    func sendSynchronousRequest(request: NSURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void)
    {
        let semaphore = dispatch_semaphore_create(0)
        
        let task = self.dataTaskWithRequest(request) { data, response, error in
            completionHandler(data, response, error)
            dispatch_semaphore_signal(semaphore)
        }
        
        task.resume()
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }
}

class PlaylistVideosViewController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    @IBOutlet var playlistVideosTableView: UITableView!
    @IBOutlet var progressView: UIView!
    
    
    let serialQueue = dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL)
    
    // Key to use YouTube API
    let apiKey = "AIzaSyB537VDENQPVMR5cYtozhLLEbEUI59Sx28"
    
    // Maximum results returned from YouTube search
    let maxResults: Int = 50
    
    // Channel to get data from
    let channelID = "UC5ltMmeC4YFaart1SSXdmAg"
    
    // AppSpy
    //let channelID = "UCJKOvdk-nVzDAFR_9MF64sw"
    
    var playlistID: String!
    
    // Storage of JSON data
    var results_DICT: Dictionary<NSObject, AnyObject> = Dictionary<NSObject, AnyObject>()
    var resultsVideoDurations_DICT: Dictionary<NSObject, AnyObject> = Dictionary<NSObject, AnyObject>()
    var videoDurations_DICT: Dictionary<String, AnyObject> = Dictionary<String, AnyObject>()
    
    // All the playlist videos
    var playlistVideos_ARRAY: [AnyObject] = []
    
    // All the video IDs
    var videoIDs_ARRAY: [String] = []
    
    // All the videos per playlist data
    var thumbnailOfVideo: [UIImage] = []
    var titleOfVideo_ARRAY: [String] = []
    var formattedDurationOfVideos_ARRAY: [String] = []
    
    var counterToReloadTable: Int = 0
    var startOfNextIndexForVideos: Int = 0
    var runGetAllVideoDurationsInGetAllVideosFromPlaylist: Bool = true

   /*
    * MARK: UIVIEWCONTROLLER FUNCTIONS
    *
    * This function is called when the view appears for the first time, and
    * called one time when the app starts up.
    */
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Removes extra separator lines for empty cells
        playlistVideosTableView.tableFooterView = UIView(frame: CGRectZero)
        
        // Allows the appropriates functions to be used in the Table View
        playlistVideosTableView.dataSource = self
        playlistVideosTableView.delegate = self
        
        // Retrieve the first batch of videos from the playlists
        getAllVideosFromPlaylist("https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&maxResults=\(maxResults)&playlistId=PLxnnlv22Xcq1--zBP7iDc2WIavgmRT11B&key=\(apiKey)")
    }

   /*
    * MARK: UITABLEVIEWDELEGATE
    *
    * This function sets the number of sections.
    */
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }

   /*
    * This function sets the number of rows per section.
    */
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return playlistVideos_ARRAY.count
    }
 
   /*
    * This function populates each cell with data
    */
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var cell: UITableViewCell!
        
        // Dequeue the cell to load data
        cell = tableView.dequeueReusableCellWithIdentifier("PlaylistVideos", forIndexPath: indexPath)
        
        // Reference the video and video title imageview via its tags
        let videoThumbnail = cell.viewWithTag(7) as! UIImageView
        let videoTitle = cell.viewWithTag(8) as! UILabel
        let videoDuration = cell.viewWithTag(9) as! UILabel
        
       /*
        * User scrolled to last element (i.e. 5th video), so load more results.
        * Check to ensure there is another token, i.e. another page of items
        */
        if indexPath.row == playlistVideos_ARRAY.count - 1
                    && self.results_DICT["nextPageToken"] != nil
        {
            // Retrieve the next token
            let nextPageToken = results_DICT["nextPageToken"] as! String
            
            self.progressView.hidden = false
            
            // Retrieve the first batch of videos from the playlists
            getAllVideosFromPlaylist("https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&pageToken=\(nextPageToken)&maxResults=\(maxResults)&playlistId=PLxnnlv22Xcq1--zBP7iDc2WIavgmRT11B&key=\(apiKey)")
        }
        
        // Load the relevant videos per playlist data
        videoTitle.text = titleOfVideo_ARRAY[indexPath.row]
        videoDuration.text = formattedDurationOfVideos_ARRAY[indexPath.row]
        videoThumbnail.image = thumbnailOfVideo[indexPath.row]
        
        // Return the cell with loaded data
        return cell
    }

   /*
    * This function sets the height of each cell.
    */
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 80.0
    }
    
   /*
    * MARK: UITABLEVIEWDATASOURCE
    *
    * This function monitors the selection of a row.
    */
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        // Deselects the row
        playlistVideosTableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func methodOne(urlString1: String)
    {
        let targetURL = NSURL(string: urlString1)
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(targetURL!) {(data, response, error) in
            
            // DO STUFF
            self.methodTwo("some url string")
            
        }
    
        task.resume()
    }
    
    func methodTwo(urlString2: String)
    {
        let targetURL = NSURL(string: urlString2)
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(targetURL!) {(data, response, error) in
            
            // DO STUFF
            
        }
        
        task.resume()
    }
    
   /*
    * This function will retrieve all the important information from each video's playlist to display in the table.
    */
    func getAllVideosFromPlaylist(urlString: String)
    {
        // URL of the JSON data
        let targetURL = NSURL(string: urlString)
        
       
        // Instantiate a data task object using the session instance, in which we provide the request as an argument
        let task = NSURLSession.sharedSession().dataTaskWithURL(targetURL!) {(data, response, error) in
            
            // Check for valid JSON data by checking for HTTP status code and the error object
            do
            {
                // Convert the JSON data to a dictionary
                self.results_DICT = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as! Dictionary<NSObject, AnyObject>
                
                print(self.results_DICT)
                // Get the first dictionary item from the returned items (usually there's just one item)
                let items = self.results_DICT["items"] as AnyObject!
                
                if items.count > 0
                {
                    // Loop through all items and add it to another dictionary
                    for i in 0...items.count - 1
                    {
                        // Add the item to an array for playlist data retrieval
                        self.playlistVideos_ARRAY.append( (items[i])! )
                        
                        let thumbnails: AnyObject? = ( (self.playlistVideos_ARRAY[self.startOfNextIndexForVideos] as! Dictionary<NSObject, AnyObject> )["snippet"] as! Dictionary<NSObject, AnyObject> )["thumbnails"]
                        
                        if thumbnails != nil
                        {
                            // Retrieve each video ID from the batch of 10 results and store it in an array
                            self.videoIDs_ARRAY.append( ( ( ( ( self.playlistVideos_ARRAY[self.startOfNextIndexForVideos] as! Dictionary<NSObject, AnyObject> )["snippet"] as! Dictionary<NSObject, AnyObject> )["resourceId"] as! Dictionary<NSObject, AnyObject> )["videoId"] as? String)! )
                            
                            // Retrieve each video title from the batch of 10 results and store it in an array
                            self.titleOfVideo_ARRAY.append( ( ( ( self.playlistVideos_ARRAY[self.startOfNextIndexForVideos] as! Dictionary<NSObject, AnyObject> )["snippet"] as! Dictionary<NSObject, AnyObject> )["title"] as? String)! )
                            
                            self.thumbnailOfVideo.append(UIImage(data: NSData(contentsOfURL: NSURL(string: ( ( ( (self.playlistVideos_ARRAY[self.startOfNextIndexForVideos] as! Dictionary<NSObject, AnyObject> )["snippet"] as! Dictionary<NSObject, AnyObject> )["thumbnails"] as! Dictionary<NSObject, AnyObject> )["high"] as! Dictionary<NSObject, AnyObject> )["url"] as! String )! )! )! )
                            
                            // Index of where to store the next video data information
                            self.startOfNextIndexForVideos += 1
                            
                            // Index of each video ID
                            var j = 0
                            
                            if self.runGetAllVideoDurationsInGetAllVideosFromPlaylist == true
                            {
                                // First GET request batch, therefore the video ID must be fetched at the beginning of the array, i.e. 1st index
                                self.runGetAllVideoDurationsInGetAllVideosFromPlaylist = false
                            }
                            else
                            {
                                // Set the index to start looking for the video ID at the next GET request batch, i.e. 10th index
                                j = self.formattedDurationOfVideos_ARRAY.count
                            }
                            
                            print("inside ASYNC")
                            print("self.videoIDs_ARRAY = \(self.videoIDs_ARRAY)")
                            
                            
                            //let group = dispatch_group_create()
                            // For each video ID, perform GET request to YouTube api to retrieve each video duration
                            for k in j...self.videoIDs_ARRAY.count - 1
                            {
//                                dispatch_group_enter(group)
//                                dispatch_async(self.serialQueue) {
                                
                                print("k = \(k)")
                                
                                print("calling SYNC")
                                
                                self.getAllVideoDurations("https://www.googleapis.com/youtube/v3/videos?part=snippet,contentDetails,statistics,status&id=\(self.videoIDs_ARRAY[k])&key=\(self.apiKey)") //{
//                                        dispatch_group_leave(group)
//                                    }
//                                }
                            }
//                            dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
              
                        }
                        else
                        {
                            print("thumbnail not available")
                            
                            ShareData.sharedInstance.isPlaylistUnavailable = true
                            
                            dispatch_async(dispatch_get_main_queue(), {
                                
                                self.navigationController?.popViewControllerAnimated(true)
                                
                            })
                        }
                    }
                }
                else
                {
                    print("zero videos")
                    
                    ShareData.sharedInstance.isPlaylistUnavailable = true
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        self.navigationController?.popViewControllerAnimated(true)
                        
                    })
                }
            }
            catch
            {
                print(error)
            }
            
        }
        
        task.resume()
    }
   
    /*
    * This function performs this task synchronously.
    * Other tasks must wait for this to finish before starting.
    */
    func getAllVideoDurations(urlString: String)
    {
        // URL of the JSON data
        let targetURL = NSURL(string: urlString)!
        
        // Instantiate a data task object using the session instance, in which we provide the request as an argument
        let task = NSURLSession.sharedSession().dataTaskWithURL(targetURL) {(data, response, error) in
            
            
            if let validData = data
            {
                do
                {
                    // Convert the JSON data to a dictionary
                    self.resultsVideoDurations_DICT = try NSJSONSerialization.JSONObjectWithData(validData, options: NSJSONReadingOptions()) as! Dictionary<NSObject, AnyObject>
                    
                    
                    // Get the first dictionary item from the returned items (usually there's just one item)
                    let item = self.resultsVideoDurations_DICT["items"] as! [AnyObject]!
                    
                    
                    // Video duration in unfamiliar format
                    let videoDuration = ( ( item[0] as! Dictionary<NSObject, AnyObject>)["contentDetails"] as! Dictionary<NSObject, AnyObject> )["duration"] as? String
                    
                    
                    self.formattedDurationOfVideos_ARRAY.append( self.formatDurations(videoDuration!) )
                    
                    print("inside SYNC")
                    print("formattedDurationOfVideos_ARRAY = \(self.formattedDurationOfVideos_ARRAY)")
                    
                    self.counterToReloadTable += 1
                    
                    if self.counterToReloadTable == self.videoIDs_ARRAY.count
                    {
                        dispatch_async(dispatch_get_main_queue()) {
                            
                            // Reload the tableview.
                            self.playlistVideosTableView.reloadData()
                            
                            // Hide the progress indicator
                            self.progressView.hidden = true
                        }
                    }
                }
                catch
                {
                    print(error)
                }
            }
            else
            {
                print(error)
            }

        }
        task.resume()
    }

   /*
    * This function will take YouTube's ISO 8601 format and convert it to a recognizable time format.
    */
    func formatDurations(sender : String) ->String
    {
        var timeDuration : NSString!
        
        let string: NSString = sender
        
        if string.rangeOfString("H").location == NSNotFound && string.rangeOfString("M").location == NSNotFound{
            
            if string.rangeOfString("S").location == NSNotFound
            {
                timeDuration = NSString(format: "00:00")
            }
            else
            {
                var secs: NSString = sender
                secs = secs.substringFromIndex(secs.rangeOfString("PT").location + "PT".characters.count)
                secs = secs.substringToIndex(secs.rangeOfString("S").location)
                
                timeDuration = NSString(format: "00:%02d", secs.integerValue)
            }
        }
        else if string.rangeOfString("H").location == NSNotFound
        {
            var mins: NSString = sender
            mins = mins.substringFromIndex(mins.rangeOfString("PT").location + "PT".characters.count)
            mins = mins.substringToIndex(mins.rangeOfString("M").location)
            
            if string.rangeOfString("S").location == NSNotFound
            {
                timeDuration = NSString(format: "%02d:00", mins.integerValue)
            }
            else
            {
                var secs: NSString = sender
                secs = secs.substringFromIndex(secs.rangeOfString("M").location + "M".characters.count)
                secs = secs.substringToIndex(secs.rangeOfString("S").location)
                
                timeDuration = NSString(format: "%02d:%02d", mins.integerValue, secs.integerValue)
            }
        }
        else
        {
            var hours: NSString = sender
            hours = hours.substringFromIndex(hours.rangeOfString("PT").location + "PT".characters.count)
            hours = hours.substringToIndex(hours.rangeOfString("H").location)
            
            if string.rangeOfString("M").location == NSNotFound && string.rangeOfString("S").location == NSNotFound
            {
                timeDuration = NSString(format: "%02d:00:00", hours.integerValue)
            }
            else if string.rangeOfString("M").location == NSNotFound
            {
                var secs: NSString = sender
                secs = secs.substringFromIndex(secs.rangeOfString("H").location + "H".characters.count)
                secs = secs.substringToIndex(secs.rangeOfString("S").location)
                
                timeDuration = NSString(format: "%02d:00:%02d", hours.integerValue, secs.integerValue)
            }
            else if string.rangeOfString("S").location == NSNotFound
            {
                var mins: NSString = sender
                mins = mins.substringFromIndex(mins.rangeOfString("H").location + "H".characters.count)
                mins = mins.substringToIndex(mins.rangeOfString("M").location)
                
                timeDuration = NSString(format: "%02d:%02d:00", hours.integerValue, mins.integerValue)
            }
            else
            {
                var secs: NSString = sender
                secs = secs.substringFromIndex(secs.rangeOfString("M").location + "M".characters.count)
                secs = secs.substringToIndex(secs.rangeOfString("S").location)
                var mins: NSString = sender
                mins = mins.substringFromIndex(mins.rangeOfString("H").location + "H".characters.count)
                mins = mins.substringToIndex(mins.rangeOfString("M").location)
                
                timeDuration = NSString(format: "%02d:%02d:%02d", hours.integerValue, mins.integerValue, secs.integerValue)
            }
        }
        
        return timeDuration as String
    }
}