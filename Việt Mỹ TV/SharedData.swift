//
//  SharedData.swift
//  Việt Mỹ
//
//  Created by EVO on 2/21/16.
//  Copyright © 2016 VAYA. All rights reserved.
//

import Foundation

class ShareData
{
    class var sharedInstance: ShareData
    {
        struct Static
        {
            static var instance: ShareData?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token)
        {
            Static.instance = ShareData()
        }
        
        return Static.instance!
    }
    
    // Device screen height sizes
    let iPhone4s_Height_Portrait = Float(480.0)
    let iPhone4s_Height_Landscape = Float(320.0)
    let iPhone55c5s_Height_Portrait = Float(568.0)
    let iPhone55c5s_Height_Landscape = Float(320.0)
    let iPhone66s_Height_Portrait = Float(667.0)
    let iPhone66s_Height_Landscape = Float(375.0)
    
    var isPlaylistUnavailable: Bool = false
}