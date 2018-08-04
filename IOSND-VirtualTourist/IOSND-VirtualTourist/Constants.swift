//
//  Constants.swift
//  IOSND-VirtualTourist
//
//  Created by Leandro Alves Santos on 28/07/18.
//  Copyright © 2018 Leandro Alves Santos. All rights reserved.
//

struct Constants {
    
    struct ParameterKeys {
        static let method = "method"
        static let apiKey = "api_key"
        static let extras = "extras"
        static let format = "format"
        static let page = "page"
        static let perPage = "per_page"
        static let noJSONCallback = "nojsoncallback"
        static let safeSearch = "safe_search"
        static let bBox = "bbox"
    }
    
    struct ParameterValues {
        static let method = "flickr.photos.search"
        static let apiKey = "a6b7978141e96caab2ce3fa48680ce7d"
        static let extras = "url_m"
        static let format = "json"
        static let perPage = "21"
        static let noJSONCallback = "1"
        static let safeSearch = "1"
    }
}
